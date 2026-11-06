import 'caregiver_schedule_service.dart' as schedule;
import 'firebase_caregiver_schedule_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/habit.dart';
import '../models/relative.dart';
import '../models/task_item.dart';
import '../utils/app_error.dart';
import 'family_repository.dart';
import 'habit_repository.dart';
import 'task_repository.dart';

class FirebaseUserData {
  FirebaseUserData(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  CollectionReference<Map<String, dynamic>> collection(String name) {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
    return db.collection('users').doc(uid).collection(name);
  }

  Future<T> run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw AppException.network;
      }
      throw AppException('Chưa thể truy cập dữ liệu. Bác thử lại nhé.',
          cause: e);
    }
  }
}

class FirebaseFamilyRepository implements FamilyRepository {
  FirebaseFamilyRepository(this.data);
  final FirebaseUserData data;
  Relative _map(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Relative(
        id: doc.id,
        name: m['name'] as String,
        relation: m['relation'] as String,
        phone: m['phone'] as String);
  }

  @override
  Future<List<Relative>> all() => data.run(() async =>
      (await data.collection('family').get()).docs.map(_map).toList());
  Stream<List<Relative>> watchAll() => data
      .collection('family')
      .snapshots()
      .map((s) => s.docs.map(_map).toList());
  @override
  Future<void> save(Relative relative) =>
      data.run(() => data.collection('family').doc(relative.id).set({
            'name': relative.name,
            'relation': relative.relation,
            'phone': relative.phone,
          }));
  @override
  Future<void> delete(String id) =>
      data.run(() => data.collection('family').doc(id).delete());
}

class FirebaseHabitRepository implements HabitRepository {
  FirebaseHabitRepository(this.data);
  final FirebaseUserData data;
  @override
  Future<List<Habit>> all() =>
      data.run(() async => (await data.db.collection('habits').get())
          .docs
          .map((d) => Habit.fromMap(d.id, d.data()))
          .toList());
  @override
  Future<Habit?> byKey(String key) => data.run(() async {
        final doc = await data.db.collection('habits').doc(key).get();
        return doc.exists ? Habit.fromMap(doc.id, doc.data()!) : null;
      });
}

/// Giữ contract F3/F4; trạng thái hiện tại luôn thuộc ngày UTC+7 hôm nay.
class FirebaseTaskRepository implements TaskRepository, ScopedTaskRepository {
  FirebaseTaskRepository(this.data);
  final FirebaseUserData data;
  DateTime get today => DateTime.now().toUtc().add(const Duration(hours: 7));
  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) => data.run(() async {
        final tasks = await data.collection('tasks').get();
        final rescheduleDocs = await data.collection('taskReschedules').get();
        final statuses = await data
            .collection('completions')
            .where('date', isEqualTo: dateKey(day))
            .get();
        final byTask = {
          for (final d in statuses.docs)
            d.data()['taskId'] as String:
                TaskStatus.values.asNameMap()[d.data()['status']] ??
                    TaskStatus.pending
        };
        final templates = {
          for (final d in tasks.docs) d.id: TaskItem.fromMap(d.id, d.data())
        };
        final dayKey = dateKey(day);
        final reschedules = {
          for (final d in rescheduleDocs.docs)
            d.id: TaskReschedule.fromMap(d.data())
        };
        final scheduled = tasks.docs
            .map((d) => TaskItem.fromMap(d.id, d.data()))
            .where((t) =>
                t.occursOn(day) && !reschedules.containsKey('${t.id}_$dayKey'))
            .map((t) => t.copyWith(
                status: resolveOccurrenceStatus(t, templates, byTask),
                occurrenceDate: dayKey,
                rescheduleSourceDate: dayKey))
            .toList();
        for (final reschedule
            in reschedules.values.where((r) => r.targetDate == dayKey)) {
          final task = templates[reschedule.taskId];
          if (task != null) {
            scheduled.add(task.copyWith(
              hour: reschedule.hour,
              minute: reschedule.minute,
              status: byTask[task.id] ?? TaskStatus.pending,
              occurrenceDate: dayKey,
              rescheduleSourceDate: reschedule.sourceDate,
            ));
          }
        }
        scheduled.sort((a, b) =>
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        return scheduled;
      });
  @override
  Future<schedule.ScheduleUndo> changeOccurrence(TaskItem original,
          DateTime day, TaskItem? replacement, schedule.ChangeScope scope) =>
      FirebaseCaregiverScheduleService(data).change(
          data.auth.currentUser!.uid, original, day, replacement, scope);
  @override
  Future<void> undoOccurrence(schedule.ScheduleUndo change) async {
    if (data.auth.currentUser?.uid != change.momUid) {
      throw const AppException('Tài khoản đã thay đổi. Bác mở lại lịch nhé.');
    }
    await FirebaseCaregiverScheduleService(data).undo(change);
  }

  @override
  Future<void> save(TaskItem task) => data.run(() async {
        final normalized =
            task.copyWith(startDate: task.startDate ?? dateKey(today));
        normalized.validate();
        final doc = data.collection('tasks').doc(task.id);
        await data.db.runTransaction((tx) async {
          final existing = await tx.get(doc);
          final revision = existing.exists
              ? (existing.data()?['revision'] as int? ?? 0) + 1
              : 0;
          tx.set(doc, normalized.copyWith(revision: revision).toMap());
        });
      });
  @override
  Future<void> setStatus(String taskId, TaskStatus status) =>
      data.run(() async {
        final key = dateKey(today);
        final task = await data.collection('tasks').doc(taskId).get();
        if (!task.exists) {
          throw const AppException('Việc này không nằm trong lịch hôm nay.');
        }
        if (!TaskItem.fromMap(taskId, task.data()!).occursOn(today)) {
          final moved = await data
              .collection('taskReschedules')
              .where('taskId', isEqualTo: taskId)
              .get();
          if (!moved.docs.any((d) => d.data()['targetDate'] == key)) {
            throw const AppException('Việc này không nằm trong lịch hôm nay.');
          }
        }
        await data.collection('completions').doc('${taskId}_$key').set({
          'taskId': taskId,
          'date': key,
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
  @override
  Future<void> delete(String taskId) =>
      data.run(() => data.collection('tasks').doc(taskId).delete());

  @override
  Future<TaskRescheduleChange> reschedule(TaskItem task,
          {required DateTime targetDay,
          required int hour,
          required int minute}) =>
      data.run(() async {
        final sourceDate =
            task.rescheduleSourceDate ?? task.occurrenceDate ?? dateKey(today);
        final key = '${task.id}_$sourceDate';
        final doc = data.collection('taskReschedules').doc(key);
        final snapshot = await doc.get();
        final before =
            snapshot.exists ? TaskReschedule.fromMap(snapshot.data()!) : null;
        final history = [
          ...?before?.history,
          <String, Object?>{
            'fromDate': before?.targetDate ?? sourceDate,
            'fromHour': before?.hour ?? task.hour,
            'fromMinute': before?.minute ?? task.minute,
          },
        ];
        final next = TaskReschedule(
          taskId: task.id,
          sourceDate: sourceDate,
          targetDate: dateKey(targetDay),
          hour: hour,
          minute: minute,
          history: history,
        );
        await doc
            .set({...next.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
        return TaskRescheduleChange(key: key, before: before);
      });

  @override
  Future<void> restoreReschedule(TaskRescheduleChange change) =>
      data.run(() async {
        final doc = data.collection('taskReschedules').doc(change.key);
        if (change.before == null) {
          await doc.delete();
        } else {
          await doc.set({
            ...change.before!.toMap(),
            'updatedAt': FieldValue.serverTimestamp()
          });
        }
      });
}
