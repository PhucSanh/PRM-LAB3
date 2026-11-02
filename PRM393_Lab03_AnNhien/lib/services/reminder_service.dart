import '../models/task_item.dart';
import '../utils/app_error.dart';

/// Lời nhắc trên máy (F2 S13 / N01, F4 N16, F6). Bản thật dùng
/// flutter_local_notifications – package do Hiếu / Khang đề xuất trong PR.
abstract interface class ReminderService {
  Future<bool> hasPermission();

  /// Hỏi quyền thông báo của hệ thống; trả `true` nếu Bác cho phép.
  Future<bool> requestPermission();
  Future<void> schedule(TaskItem task);
  Future<void> cancel(String taskId);
  Future<void> snooze(String taskId, int minutes);

  /// Gửi ngay một lời nhắc thử (N01).
  Future<void> showTest();
}

/// Giữ trong bộ nhớ.
/// - `permissionGranted: false` → Bác từ chối khi được hỏi quyền.
/// - `alreadyGranted: true` → máy đã có quyền từ trước (bỏ qua S13).
/// - `failOnShowTest: true` → gửi lời nhắc thử bị lỗi.
class FakeReminderService implements ReminderService {
  FakeReminderService({
    this.permissionGranted = true,
    bool alreadyGranted = false,
    this.failOnShowTest = false,
    this.delay = const Duration(milliseconds: 200),
  }) : _granted = alreadyGranted;

  final bool permissionGranted;
  final bool failOnShowTest;
  final Duration delay;
  bool _granted;

  final scheduled = <String, TaskItem>{};
  final snoozed = <String, int>{};
  int requestCount = 0;
  int testShownCount = 0;

  static const _noPermission = AppException(
      'Máy chưa cho phép nhắc việc. Bác bật lại trong Cài đặt nhé.');

  @override
  Future<bool> hasPermission() async => _granted;

  @override
  Future<bool> requestPermission() async {
    await Future<void>.delayed(delay);
    requestCount++;
    _granted = permissionGranted;
    return _granted;
  }

  @override
  Future<void> schedule(TaskItem task) async {
    if (!_granted) throw _noPermission;
    scheduled[task.id] = task;
  }

  @override
  Future<void> cancel(String taskId) async {
    scheduled.remove(taskId);
    snoozed.remove(taskId);
  }

  @override
  Future<void> snooze(String taskId, int minutes) async {
    if (!_granted) throw _noPermission;
    snoozed[taskId] = minutes;
  }

  @override
  Future<void> showTest() async {
    await Future<void>.delayed(delay);
    if (!_granted) throw _noPermission;
    if (failOnShowTest) {
      throw const AppException('Chưa gửi được lời nhắc thử. Bác thử lại nhé.');
    }
    testShownCount++;
  }
}
