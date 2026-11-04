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

    expect(await vm.save(), isFalse);
    expect(container.read(taskFormViewModelProvider).showValidation, isTrue);
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
  });

  test('F4: tạo việc lưu repository và ghi analytics add_task', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.selectActivity('move');
    vm.setTitle('Đi bộ buổi sáng');
    vm.setTime(hour: 8, minute: 0, isAm: true);

    expect(await vm.save(), isTrue);
    final saved = await repository.tasksForDay(DateTime.now());
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
    expect(await vm.save(scope: ChangeScope.thisAndFollowing), isTrue);
    expect((await repository.tasksForDay(DateTime.now())).single.title,
        'Đi bộ quanh công viên');
    expect(await vm.delete(ChangeScope.once), isTrue);
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
    expect(analytics.logged, containsAll(['edit_task', 'delete_task']));
  });
}
