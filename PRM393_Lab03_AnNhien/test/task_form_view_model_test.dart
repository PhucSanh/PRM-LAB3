import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeTaskRepository repository;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    repository = FakeTaskRepository([]);
    analytics = FakeAnalyticsService();
    container = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(repository),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
  });
  tearDown(() => container.dispose());

  test('F4: tên trống hiển thị validation và không lưu', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.setTitle('');

    expect(await vm.save(), isFalse);
    expect(container.read(taskFormViewModelProvider).showValidation, isTrue);
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
  });

  test('F4: chọn hoạt động điền sẵn tên và giờ tròn kế tiếp', () {
    final before = DateTime.now();
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    var state = container.read(taskFormViewModelProvider);
    expect(state.title, 'Đi bộ nhẹ nhàng');
    expect(state.minute, 0);
    expect(state.hour, (before.hour + 1) % 24);

    vm.selectActivity('tea', suggestedTitle: 'Uống trà với bạn');
    state = container.read(taskFormViewModelProvider);
    expect(state.activity, 'tea');
    expect(state.title, 'Uống trà với bạn');
  });

  test('F4: không lưu giờ đã qua khi ngày làm là hôm nay', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    vm.setDate(DateTime.now());
    vm.setTime(hour: past.hour, minute: past.minute, isAm: past.hour < 12);

    expect(container.read(taskFormViewModelProvider).isTimeInPastToday, isTrue);
    expect(await vm.save(), isFalse);
    expect(container.read(taskFormViewModelProvider).showValidation, isTrue);
  });

  test('F4: tạo việc lưu repository và ghi analytics add_task', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.selectActivity('move');
    vm.setTitle('Đi bộ buổi sáng');

    expect(await vm.save(), isTrue);
    final saved = await repository
        .tasksForDay(container.read(taskFormViewModelProvider).date!);
    expect(saved.single.title, 'Đi bộ buổi sáng');
    expect(saved.single.repeat, RepeatRule.daily);
    expect(analytics.logged, contains('add_task'));
  });

  test('F4: sửa rồi xóa task lặp có analytics edit/delete', () async {
    await repository.save(const TaskItem(
        id: 'repeat', title: 'Đi bộ', habitKey: 'move', hour: 9, minute: 30));
    final vm = container.read(taskFormViewModelProvider.notifier);
    expect(await vm.startEdit('repeat'), isTrue);
    vm.setTitle('Đi bộ quanh công viên');
    vm.setDate(DateTime.now().add(const Duration(days: 1)));
    expect(await vm.save(scope: ChangeScope.thisAndFollowing), isTrue);
    expect((await repository.tasksForDay(DateTime.now())).single.title,
        'Đi bộ quanh công viên');
    expect(await vm.delete(ChangeScope.once), isTrue);
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
    expect(analytics.logged, containsAll(['edit_task', 'delete_task']));
  });
}
