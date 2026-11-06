import 'task_repository.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_item.dart';
import '../utils/app_error.dart';
import 'caregiver_schedule_service.dart';
import 'firebase_repositories.dart';

class FirebaseCaregiverScheduleService implements CaregiverScheduleService {
  FirebaseCaregiverScheduleService(this.data);
  final FirebaseUserData data;
  CollectionReference<Map<String, dynamic>> _tasks(String momUid) {
    if (data.auth.currentUser == null) {
      throw const AppException('Cần đăng nhập trước khi xem lịch.');
    }
    return data.db.collection('users').doc(momUid).collection('tasks');
  }

  @override
  Future<List<TaskItem>> templates(String momUid) =>
      data.run(() async => (await _tasks(momUid).get())
          .docs
          .map((d) => TaskItem.fromMap(d.id, d.data()))
          .toList());
  @override
  Stream<List<ScheduleOccurrence>> watch(
          String momUid, DateTime from, DateTime through) =>
      Stream.multi((sink) {
        List<TaskItem>? tasks;
        Map<String, TaskStatus>? statuses;
        Map<String, TaskReschedule>? moved;
        void emit() {
          if (tasks == null || statuses == null || moved == null) return;
          final list = <ScheduleOccurrence>[];
          final templates = {for (final t in tasks!) t.id: t};
          for (var day = calendarDate(from);
              !day.isAfter(through);
              day = day.add(const Duration(days: 1))) {
            final dailyStatuses = {
              for (final e in statuses!.entries)
                if (e.key.endsWith('_${dateKey(day)}'))
                  e.key.substring(0, e.key.length - 11): e.value
            };
            for (final task in tasks!.where((t) =>
                t.occursOn(day) &&
                !moved!.containsKey('${t.id}_${dateKey(day)}'))) {
              list.add(ScheduleOccurrence(
                  task.copyWith(
                      status: resolveOccurrenceStatus(
                          task, templates, dailyStatuses),
                      occurrenceDate: dateKey(day)),
                  day));
            }
          }
          for (final change in moved!.values) {
            final day = parseDateKey(change.targetDate);
            final task = templates[change.taskId];
            if (day == null ||
                task == null ||
                day.isBefore(calendarDate(from)) ||
                day.isAfter(calendarDate(through))) {
              continue;
            }
            list.add(ScheduleOccurrence(
                task.copyWith(
                    hour: change.hour,
                    minute: change.minute,
                    status: statuses!['${task.id}_${change.targetDate}'] ??
                        TaskStatus.pending,
                    occurrenceDate: change.targetDate,
                    rescheduleSourceDate: change.sourceDate),
                day));
          }
          list.sort((a, b) {
            final d = a.date.compareTo(b.date);
            return d != 0
                ? d
                : (a.task.hour * 60 + a.task.minute)
                    .compareTo(b.task.hour * 60 + b.task.minute);
          });
          sink.add(list);
        }

        void error(Object e, StackTrace st) => sink.addError(
            AppException('Chưa tải được lịch. Kiểm tra mạng hoặc ghép nối lại.',
                cause: e),
            st);
        final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> a, b, c;
        try {
          a = _tasks(momUid).snapshots().listen((s) {
            tasks =
                s.docs.map((d) => TaskItem.fromMap(d.id, d.data())).toList();
            emit();
          }, onError: error);
          b = data.db
              .collection('users')
              .doc(momUid)
              .collection('completions')
              .where('date', isGreaterThanOrEqualTo: dateKey(from))
              .where('date', isLessThanOrEqualTo: dateKey(through))
              .snapshots()
              .listen((s) {
            statuses = {
              for (final d in s.docs)
                d.id: TaskStatus.values.asNameMap()[d.data()['status']] ??
                    TaskStatus.pending
            };
            emit();
          }, onError: error);
          c = data.db
              .collection('users')
              .doc(momUid)
              .collection('taskReschedules')
              .snapshots()
              .listen((snapshot) {
            moved = {
              for (final doc in snapshot.docs)
                doc.id: TaskReschedule.fromMap(doc.data())
            };
            emit();
          }, onError: error);
          sink.onCancel = () async {
            await a.cancel();
            await b.cancel();
            await c.cancel();
          };
        } catch (e, st) {
          error(e, st);
          sink.close();
        }
      });
  @override
  Future<void> create(String momUid, TaskItem task) => data.run(() async {
        task.validate();
        final doc = _tasks(momUid).doc(task.id);
        await data.db.runTransaction((tx) async {
          final exists = await tx.get(doc);
          if (exists.exists) return;
          tx.set(doc, task.toMap());
        });
      });
  @override
  Future<ScheduleUndo> change(String momUid, TaskItem original, DateTime day,
          TaskItem? replacement, ChangeScope scope) =>
      data.run(() async {
        replacement?.validate();
        final tasks = _tasks(momUid);
        final newId = tasks.doc().id;
        return data.db.runTransaction((tx) async {
          final snapshot = await tx.get(tasks.doc(original.id));
          if (!snapshot.exists) {
            throw const AppException('Việc này không còn trong lịch.');
          }
          final current = TaskItem.fromMap(snapshot.id, snapshot.data()!);
          if (current.revision != original.revision) {
            throw const AppException(
                'Lịch đã được sửa trên máy khác. Tải lại rồi thử lại.');
          }
          final plan =
              planScheduleChange(current, day, replacement, scope, newId);
          for (final e in plan.after.entries) {
            tx.set(tasks.doc(e.key), e.value!.toMap());
          }
          return ScheduleUndo(momUid, plan.before, plan.after);
        });
      });
  @override
  Future<void> undo(ScheduleUndo change) => data.run(() async {
        if (change.used) {
          throw const AppException('Thay đổi này đã được hoàn tác.');
        }
        final tasks = _tasks(change.momUid);
        await data.db.runTransaction((tx) async {
          final snapshots = <String, TaskItem>{};
          for (final e in change.after.entries) {
            final doc = await tx.get(tasks.doc(e.key));
            if (!doc.exists) {
              throw const AppException('Lịch đã thay đổi. Không thể hoàn tác.');
            }
            final current = TaskItem.fromMap(doc.id, doc.data()!);
            if (current.revision != e.value!.revision) {
              throw const AppException(
                  'Lịch đã được sửa tiếp. Không thể hoàn tác.');
            }
            snapshots[e.key] = current;
          }
          for (final e in change.before.entries) {
            if (e.value == null) {
              tx.delete(tasks.doc(e.key));
            } else {
              tx.set(
                  tasks.doc(e.key),
                  e.value!
                      .copyWith(revision: snapshots[e.key]!.revision + 1)
                      .toMap());
            }
          }
        });
        change.used = true;
      });
}
