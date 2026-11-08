import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_notification.dart';
import '../models/notification_target.dart';
import '../models/task_item.dart';
import '../models/voice_task_draft.dart' show durationText;
import '../utils/app_error.dart';
import 'caregiver_schedule_service.dart';
import 'reminder_service.dart';

class PlannedReminder {
  const PlannedReminder(this.id, this.taskId, this.time,
      {this.title = reminderFallbackTitle, this.body = reminderFallbackBody});
  final int id;
  final String taskId;
  final DateTime time;

  /// Chữ trên thông báo: tên việc, giờ và thời lượng để Bác biết ngay việc gì.
  final String title, body;
}

const reminderFallbackTitle = 'An Nhiên nhắc Bác';
const reminderFallbackBody = 'Đến giờ xem việc trong lịch của Bác.';

/// "Đến giờ: Tưới cây" / "08:00 · làm trong 15 phút. Chạm để xem cách làm."
(String, String) reminderText(TaskItem task) {
  String two(int n) => n.toString().padLeft(2, '0');
  final name = task.title.trim().isEmpty ? 'việc của Bác' : task.title.trim();
  return (
    'Đến giờ: $name',
    '${two(task.hour)}:${two(task.minute)} · làm trong '
        '${durationText(task.durationMinutes)}. Chạm để xem cách làm.'
  );
}

/// Pure planner: next 30 days, <=128 pending notifications, stable IDs per UID.
List<PlannedReminder> planReminders(
    String uid, List<ScheduleOccurrence> occurrences, DateTime now) {
  final end = now.toUtc().add(const Duration(days: 30));
  final sorted = [...occurrences]..sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0
          ? d
          : (a.task.hour * 60 + a.task.minute)
              .compareTo(b.task.hour * 60 + b.task.minute);
    });
  final result = <PlannedReminder>[];
  final ids = <int>{};
  final keys = <String>{};
  for (final o in sorted) {
    final t = o.task;
    if (!t.remind ||
        [TaskStatus.done, TaskStatus.skipped].contains(t.status) ||
        (!t.occursOn(o.date) &&
            !(t.occurrenceDate == dateKey(o.date) &&
                t.rescheduleSourceDate != null))) {
      continue;
    }
    final time = DateTime.utc(
        o.date.year, o.date.month, o.date.day, t.hour - 7, t.minute);
    if (!time.isAfter(now.toUtc()) || time.isAfter(end)) continue;
    final key = '$uid|${t.id}|${dateKey(o.date)}';
    if (!keys.add(key)) continue;
    var hash = 2166136261;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0x3fffffff;
    }
    while (!ids.add(hash)) {
      hash = (hash + 1) & 0x3fffffff;
    }
    final (title, body) = reminderText(t);
    result.add(PlannedReminder(hash, t.id, time, title: title, body: body));
    if (result.length == 128) break;
  }
  return result;
}

/// Android channels are immutable once created: use one stable channel per
/// vibration choice so changing preference affects new/rescheduled reminders.
NotificationDetails reminderNotificationDetails(bool vibrate,
        {String? bigText}) =>
    NotificationDetails(
        android: AndroidNotificationDetails(
            vibrate ? 'an_nhien_reminders' : 'an_nhien_reminders_no_vibration',
            vibrate ? 'Nhắc việc An Nhiên' : 'Nhắc việc không rung',
            channelDescription: 'Lời nhắc sinh hoạt và lời nhắc thử',
            enableVibration: vibrate,
            importance: Importance.high,
            priority: Priority.high,
            // Hiện đủ chữ (tên việc dài) thay vì cắt bằng "…".
            styleInformation:
                bigText == null ? null : BigTextStyleInformation(bigText),
            icon: 'ic_notification'));

/// Android native notification service. Báo đúng phút bằng báo thức chính xác
/// (`USE_EXACT_ALARM` cho app lịch/nhắc việc, Android 13+ cấp sẵn khi cài;
/// Android 12 dùng `SCHEDULE_EXACT_ALARM`). Máy không cho phép thì quay về
/// báo thức không chính xác (có thể trễ vài phút) thay vì lỗi.
class LocalReminderService implements ReminderService {
  LocalReminderService(this.currentUid,
      {FlutterLocalNotificationsPlugin? plugin})
      : sdk = plugin ?? FlutterLocalNotificationsPlugin();
  final String? Function() currentUid;
  final FlutterLocalNotificationsPlugin sdk;
  final _opened = StreamController<AppNotification>.broadcast();
  AppNotification? _pending;
  Future<void>? _ready;
  Future<void> _queue = Future.value();
  Future<void> Function()? onPermissionGranted;
  int _generation = 0;
  bool vibrate = true;
  NotificationDetails get _details => reminderNotificationDetails(vibrate);
  Future<void> init() => _ready ??= (() async {
        tzdata.initializeTimeZones();
        await sdk.initialize(
            settings: const InitializationSettings(
                android: AndroidInitializationSettings('ic_notification')),
            onDidReceiveNotificationResponse: (response) =>
                _open(response.payload));
        await _android
            ?.createNotificationChannel(const AndroidNotificationChannel(
          'an_nhien_updates',
          'Gia đình và hệ thống',
          description: 'Cập nhật lịch, kết nối và thông báo từ An Nhiên',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));
        final launch = await sdk.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          _open(launch?.notificationResponse?.payload);
        }
      })();
  Stream<AppNotification> get onOpened async* {
    await init();
    final pending = _pending;
    _pending = null;
    if (pending != null) yield pending;
    yield* _opened.stream;
  }

  void _open(String? payload) {
    try {
      final data = jsonDecode(payload ?? '') as Map;
      if (data['uid'] != currentUid()) return;
      if (data['type'] == 'push' && data['notificationId'] is String) {
        final item = AppNotification(
            id: data['notificationId'] as String,
            parentUid: data['parentUid'] as String?,
            title: 'An Nhiên',
            body: '',
            receivedAt: DateTime.now(),
            route: firebaseNotificationTarget(data['route'] as String?));
        if (_opened.hasListener) {
          _opened.add(item);
        } else {
          _pending = item;
        }
        return;
      }
      if (data['taskId'] is! String) return;
      final id = data['taskId'] as String;
      final item = AppNotification(
          id: 'local-$id',
          title: 'Lời nhắc',
          body: 'Đến giờ xem việc của Bác.',
          receivedAt: DateTime.now(),
          route: id == 'test'
              ? '/inbox'
              : '/reminder/${Uri.encodeComponent(id)}${data['date'] is String ? '?date=${Uri.encodeComponent(data['date'] as String)}' : ''}');
      if (_opened.hasListener) {
        _opened.add(item);
      } else {
        _pending = item;
      }
    } catch (_) {/* Ignore foreign or stale notification payloads. */}
  }

  /// FCM already presents background pushes. Present only foreground messages
  /// here, using the same plugin/channel as reminders to keep tap handling intact.
  Future<void> showForegroundPush(AppNotification item, String uid) =>
      _run(() async {
        if (uid != currentUid()) return;
        final id = item.id.codeUnits.fold<int>(
            0x10000000, (value, unit) => ((value * 31) + unit) & 0x3fffffff);
        await sdk.show(
            id: id,
            title: item.title,
            body: item.body,
            notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                    'an_nhien_updates', 'Gia đình và hệ thống',
                    channelDescription:
                        'Cập nhật lịch, kết nối và thông báo từ An Nhiên',
                    importance: Importance.high,
                    priority: Priority.high,
                    playSound: true,
                    enableVibration: true,
                    icon: 'ic_notification')),
            payload: jsonEncode({
              'type': 'push',
              'uid': uid,
              'notificationId': item.id,
              'parentUid': item.parentUid,
              'route': item.route
            }));
      });

  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      await init();
      return await action();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
          'Chưa đặt được lời nhắc. Bác kiểm tra quyền thông báo rồi thử lại.',
          cause: e);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      sdk.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  @override
  Future<bool> hasPermission() =>
      _run(() async => await _android?.areNotificationsEnabled() ?? false);
  @override
  Future<bool> requestPermission() => _run(() async {
        final granted =
            await _android?.requestNotificationsPermission() ?? false;
        if (granted) await onPermissionGranted?.call();
        return granted;
      });

  /// Báo thức chính xác được phép không (Android 12+ có thể bị tắt).
  Future<bool> _canExact() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _place(PlannedReminder plan, String uid, {bool? exact}) async {
    final useExact = exact ?? await _canExact();
    await sdk.zonedSchedule(
      id: plan.id,
      title: plan.title,
      body: plan.body,
      scheduledDate:
          tz.TZDateTime.from(plan.time, tz.getLocation('Asia/Ho_Chi_Minh')),
      notificationDetails:
          reminderNotificationDetails(vibrate, bigText: plan.body),
      androidScheduleMode: useExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({
        'uid': uid,
        'taskId': plan.taskId,
        'date': dateKey(plan.time.toUtc().add(const Duration(hours: 7)))
      }),
    );
  }

  Future<void> sync(List<ScheduleOccurrence> occurrences) => _run(() async {
        final uid = currentUid();
        if (uid == null) return;
        final generation = ++_generation;
        final plans = planReminders(uid, occurrences, DateTime.now());
        await _serial(() async {
          if (generation != _generation || uid != currentUid()) return;
          await sdk.cancelAllPendingNotifications();
          if (!await hasPermission()) return;
          final exact = await _canExact();
          for (final plan in plans) {
            if (generation != _generation || uid != currentUid()) return;
            await _place(plan, uid, exact: exact);
          }
        });
      });
  Future<void> clearAll({bool preservePending = false}) async {
    ++_generation;
    if (!preservePending) _pending = null;
    await _run(() => _serial(sdk.cancelAll));
  }

  @override
  Future<void> schedule(TaskItem task) => _run(() async {
        final uid = currentUid();
        if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
        if (!await hasPermission()) {
          throw const AppException(
              'Bác chưa cho phép nhắc việc. Bật lại trong Cài đặt nhé.');
        }
        await cancel(task.id);
        final now = DateTime.now().toUtc().add(const Duration(hours: 7));
        final normalized =
            task.copyWith(startDate: task.startDate ?? dateKey(now));
        final list = [
          for (var i = 0; i < 31; i++)
            ScheduleOccurrence(
                normalized, calendarDate(now).add(Duration(days: i)))
        ];
        final exact = await _canExact();
        for (final plan in planReminders(uid, list, DateTime.now())) {
          if (currentUid() != uid) return;
          await _place(plan, uid, exact: exact);
        }
      });
  @override
  Future<void> cancel(String taskId) => _run(() async {
        final uid = currentUid();
        for (final request in await sdk.pendingNotificationRequests()) {
          try {
            final payload = jsonDecode(request.payload ?? '') as Map;
            if (payload['uid'] == uid && payload['taskId'] == taskId) {
              await sdk.cancel(id: request.id);
            }
          } on FormatException {
            /* Ignore payloads owned by another notification source. */
          }
        }
      });
  @override
  Future<void> snooze(String taskId, int minutes) => _run(() async {
        if (minutes < 1 || minutes > 1440) {
          throw const AppException('Chọn số phút từ 1 đến 1440.');
        }
        final uid = currentUid();
        if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
        if (!await hasPermission()) {
          throw const AppException('Bác chưa cho phép nhắc việc.');
        }
        final today =
            dateKey(DateTime.now().toUtc().add(const Duration(hours: 7)));
        // Giữ tên việc của lời nhắc cũ cho lời nhắc lại.
        String? title, body;
        for (final request in await sdk.pendingNotificationRequests()) {
          final payload = jsonDecode(request.payload ?? '{}') as Map;
          if (payload['uid'] == uid && payload['taskId'] == taskId) {
            title ??= request.title;
            body ??= request.body;
            if (payload['date'] == today) await sdk.cancel(id: request.id);
          }
        }
        var hash = 0;
        for (final n in '$uid|$taskId'.codeUnits) {
          hash = (hash * 31 + n) & 0x3fffffff;
        }
        final plan = PlannedReminder(hash | 0x40000000, taskId,
            DateTime.now().toUtc().add(Duration(minutes: minutes)),
            title: title ?? reminderFallbackTitle,
            body: body ?? reminderFallbackBody);
        await _place(plan, uid);
      });
  @override
  Future<void> showTest() => _run(() async {
        final uid = currentUid();
        if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
        if (!await hasPermission()) {
          throw const AppException('Bác chưa cho phép nhắc việc.');
        }
        await sdk.show(
            id: 0x70000000,
            title: 'Lời nhắc thử An Nhiên',
            body: 'Bác đã nhận được lời nhắc thử.',
            notificationDetails: _details,
            payload: jsonEncode({'uid': uid, 'taskId': 'test'}));
      });
  Future<void> dispose() async {
    ++_generation;
    await _opened.close();
  }
}
