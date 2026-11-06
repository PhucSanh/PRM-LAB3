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
import 'schedule_limits.dart';

class FirebaseUserData {
  FirebaseUserData(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  CollectionReference<Map<String, dynamic>> collection(String name) {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
    return db.collection('users').doc(uid).collection(name);
  }

  Future<void Function()> checkSchedule(
      String uid, Map<String, TaskItem?> changes,
      {List<TaskReschedule> replaceMoves = const [],
      Set<String> removeMoves = const {},
      DateTime? from,
      Transaction? transaction}) async {
    final root = db.collection('users').doc(uid);
    final lock = root.collection('scheduleState').doc('current');
    final previousLock =
        transaction == null ? null : await transaction.get(lock);
    final snapshots = await Future.wait([
      root.collection('tasks').get(const GetOptions(source: Source.server)),
      root
          .collection('taskReschedules')
          .get(const GetOptions(source: Source.server))
    ]);
    final tasks = {
      for (final d in snapshots[0].docs) d.id: TaskItem.fromMap(d.id, d.data())
    };
    for (final e in changes.entries) {
      if (e.value == null) {
        tasks.remove(e.key);
      } else {
        tasks[e.key] = e.value!;
      }
    }
    final moves = {
      for (final d in snapshots[1].docs) d.id: TaskReschedule.fromMap(d.data())
    };
    for (final key in removeMoves) {
      moves.remove(key);
    }
    for (final move in replaceMoves) {
      moves[move.key] = move;
    }
    await validateScheduleLimitsAsync(
        tasks.values.toList(),
        moves.values.toList(),
        changes.keys.toSet(),
        from ?? DateTime.now().toUtc().add(const Duration(hours: 7)));
    return () {
      transaction?.set(lock,
          {'revision': (previousLock?.data()?['revision'] as int? ?? -1) + 1});
    };
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

class FirebaseFamilyRepository
    implements FamilyRepository, FavoriteFamilyRepository {
  @override
  Future<void> setFavorite(String id, bool value) => data
      .run(() => data.collection('family').doc(id).update({'favorite': value}));
  FirebaseFamilyRepository(this.data);
  final FirebaseUserData data;
  Relative _map(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Relative(
        id: doc.id,
        name: m['name'] as String,
        relation: m['relation'] as String,
        phone: m['phone'] as String,
        favorite: m['favorite'] as bool? ?? false);
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
            'favorite': relative.favorite,
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
class FirebaseTaskRepository
    implements TaskRepository, ScopedTaskRepository, RecentActivityRepository {
  @override
  Future<List<TaskItem>> recentActivities(DateTime day) => data.run(() async {
        final snapshot = await data.collection('tasks').get();
        return selectRecentActivities(
            snapshot.docs.map((d) => TaskItem.fromMap(d.id, d.data())).toList(),
            day);
      });
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
              isRescheduled: true,
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
          final commit = await data.checkSchedule(
              data.auth.currentUser!.uid, {normalized.id: normalized},
              transaction: tx);
          commit();
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
        final taskRef = data.collection('tasks').doc(task.id);
        return data.db.runTransaction((tx) async {
          final templateSnapshot = await tx.get(taskRef);
          if (!templateSnapshot.exists) {
            throw const AppException('Việc này không còn trong lịch.');
          }
          final template = TaskItem.fromMap(task.id, templateSnapshot.data()!);
          final snapshot = await tx.get(doc);
          // All writers below also update template.revision. Its transaction read
          // serializes concurrent moves; a retry re-reads this query as well.
          final all = await data
              .collection('taskReschedules')
              .where('taskId', isEqualTo: task.id)
              .get();
          final moves =
              all.docs.map((d) => TaskReschedule.fromMap(d.data())).toList();
          validateRescheduleTarget(template, sourceDate, targetDay, moves);
          final before =
              snapshot.exists ? TaskReschedule.fromMap(snapshot.data()!) : null;
          final next = TaskReschedule(
              taskId: task.id,
              sourceDate: sourceDate,
              targetDate: dateKey(targetDay),
              hour: hour,
              minute: minute,
              history: [
                ...?before?.history,
                {
                  'fromDate': before?.targetDate ?? sourceDate,
                  'fromHour': before?.hour ?? task.hour,
                  'fromMinute': before?.minute ?? task.minute
                },
              ]);
          final commit = await data.checkSchedule(
              data.auth.currentUser!.uid, {template.id: template},
              replaceMoves: [next], from: targetDay, transaction: tx);
          commit();
          tx.set(doc,
              {...next.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
          tx.update(taskRef, {'revision': template.revision + 1});
          return TaskRescheduleChange(key: key, before: before, after: next);
        });
      });

  @override
  Future<void> restoreReschedule(TaskRescheduleChange change) =>
      data.run(() async {
        final doc = data.collection('taskReschedules').doc(change.key);
        final taskId = change.after?.taskId ??
            change.before?.taskId ??
            change.key.substring(0, change.key.length - 11);
        final taskRef = data.collection('tasks').doc(taskId);
        await data.db.runTransaction((tx) async {
          final templateSnapshot = await tx.get(taskRef);
          final currentSnapshot = await tx.get(doc);
          if (!templateSnapshot.exists) {
            throw const AppException('Việc này không còn trong lịch.');
          }
          final current = currentSnapshot.exists
              ? TaskReschedule.fromMap(currentSnapshot.data()!)
              : null;
          if (change.after != null && !sameReschedule(current, change.after)) {
            throw const AppException(
                'Lần việc đã được dời tiếp. Bác tải lại lịch nhé.');
          }
          final template = TaskItem.fromMap(taskId, templateSnapshot.data()!);
          if (current != null) {
            if (!template.occursOn(DateTime.parse(current.sourceDate))) {
              throw const AppException(
                  'Lần việc đã được sửa. Không thể hoàn tác lần dời cũ.');
            }
            final all = await data
                .collection('taskReschedules')
                .where('taskId', isEqualTo: taskId)
                .get();
            validateRescheduleTarget(
                template,
                current.sourceDate,
                DateTime.parse(change.before?.targetDate ?? current.sourceDate),
                all.docs.map((d) => TaskReschedule.fromMap(d.data())));
          }
          final commit = await data.checkSchedule(
              data.auth.currentUser!.uid, {template.id: template},
              removeMoves: {change.key},
              replaceMoves: [if (change.before != null) change.before!],
              transaction: tx);
          commit();
          if (change.before == null) {
            tx.delete(doc);
          } else {
            tx.set(doc, {
              ...change.before!.toMap(),
              'updatedAt': FieldValue.serverTimestamp()
            });
          }
          tx.update(taskRef, {'revision': template.revision + 1});
        });
      });
}
