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

/// CRUD is prepared, but calendar operations deliberately fail until the shared
/// TaskItem date/recurrence contract has been agreed. Never show all days as today.
class FirebaseTaskRepository implements TaskRepository {
  FirebaseTaskRepository(this.data);
  final FirebaseUserData data;
  static const schemaPending =
      AppException('Lịch đang chờ thống nhất dữ liệu ngày và lặp lại.');
  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) async => throw schemaPending;
  @override
  Future<void> save(TaskItem task) async => throw schemaPending;
  @override
  Future<void> setStatus(String taskId, TaskStatus status) async =>
      throw schemaPending;
  @override
  Future<void> delete(String taskId) =>
      data.run(() => data.collection('tasks').doc(taskId).delete());
}
