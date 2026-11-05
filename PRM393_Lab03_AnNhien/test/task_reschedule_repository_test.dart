import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dời nhiều lần dùng thời gian mới nhất và hoàn tác từng lần', () async {
    final today = DateTime(2026, 11, 5);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final repository = FakeTaskRepository([
      TaskItem(
        id: 'walk',
        title: 'Đi bộ',
        habitKey: 'move',
        hour: 9,
        minute: 0,
        repeat: RepeatRule.once,
        startDate: dateKey(today),
      ),
    ]);

    final firstOccurrence = (await repository.tasksForDay(today)).single;
    final firstChange = await repository.reschedule(firstOccurrence,
        targetDay: tomorrow, hour: 10, minute: 0);
    final secondOccurrence = (await repository.tasksForDay(tomorrow)).single;
    final secondChange = await repository.reschedule(secondOccurrence,
        targetDay: dayAfterTomorrow, hour: 15, minute: 30);

    expect(await repository.tasksForDay(today), isEmpty);
    expect(await repository.tasksForDay(tomorrow), isEmpty);
    final newest = (await repository.tasksForDay(dayAfterTomorrow)).single;
    expect((newest.hour, newest.minute), (15, 30));
    expect(newest.status, TaskStatus.pending);

    await repository.restoreReschedule(secondChange);
    final restoredFirstMove = (await repository.tasksForDay(tomorrow)).single;
    expect((restoredFirstMove.hour, restoredFirstMove.minute), (10, 0));

    await repository.restoreReschedule(firstChange);
    final restoredOriginal = (await repository.tasksForDay(today)).single;
    expect((restoredOriginal.hour, restoredOriginal.minute), (9, 0));
  });
}
