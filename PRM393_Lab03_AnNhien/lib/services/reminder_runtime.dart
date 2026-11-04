import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_item.dart';
import 'caregiver_schedule_service.dart';
import 'crash_service.dart';
import 'local_reminder_service.dart';

/// Refresh native pending reminders at app start and each realtime task/status
/// change. New tasks from the child's device therefore also schedule on mom's.
class ReminderRuntime with WidgetsBindingObserver {
  ReminderRuntime(this.auth, this.schedules, this.reminders, this.crash);
  final FirebaseAuth auth;
  final CaregiverScheduleService schedules;
  final LocalReminderService reminders;
  final CrashService crash;
  StreamSubscription<User?>? _auth;
  StreamSubscription<List<ScheduleOccurrence>>? _tasks;
  int _generation = 0;
  String? _boundUid;
  bool _hasBound = false;
  List<ScheduleOccurrence> _last = const [];
  Future<void> init() async {
    await reminders.init();
    WidgetsBinding.instance.addObserver(this);
    reminders.onPermissionGranted = () => reminders.sync(_last);
    _auth = auth.authStateChanges().listen((user) {
      _bind(user).catchError((Object e, StackTrace st) => _report(e, st));
    });
  }

  Future<void> _bind(User? user) async {
    final generation = ++_generation;
    _last = const [];
    await _tasks?.cancel();
    if (generation != _generation) return;
    if (!_hasBound || _boundUid != user?.uid) {
      await reminders.clearAll(preservePending: !_hasBound && user != null);
      _boundUid = user?.uid;
      _hasBound = true;
    }
    if (user == null || generation != _generation) return;
    final today =
        calendarDate(DateTime.now().toUtc().add(const Duration(hours: 7)));
    _tasks = schedules
        .watch(user.uid, today, today.add(const Duration(days: 30)))
        .listen((items) {
      if (generation == _generation) {
        _last = items;
        reminders
            .sync(items)
            .catchError((Object e, StackTrace st) => _report(e, st));
      }
    }, onError: (Object e, StackTrace st) => _report(e, st));
  }

  Future<void> _report(Object e, StackTrace st) async {
    try {
      await crash.recordError(e, st, reason: 'sync_local_reminders');
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bind(auth.currentUser)
          .catchError((Object e, StackTrace st) => _report(e, st));
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    reminders.onPermissionGranted = null;
    ++_generation;
    await _auth?.cancel();
    await _tasks?.cancel();
  }
}
