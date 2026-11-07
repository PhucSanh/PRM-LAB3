import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/schedule_limits.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

final day = DateTime(2030, 1, 7);
TaskItem task(String id, int hour,
        {String title = 'Đi bộ',
        int minute = 0,
        RepeatRule repeat = RepeatRule.once,
        List<int> weekdays = const [],
        String date = '2030-01-07'}) =>
    TaskItem(
        id: id,
        title: title,
        hour: hour,
        minute: minute,
        habitKey: 'move',
        startDate: date,
        repeat: repeat,
        weekdays: weekdays);
void check(List<TaskItem> tasks, {List<TaskReschedule> moves = const []}) =>
    validateScheduleLimits(tasks, moves, {tasks.last.id}, day);
void main() {
  test('same exact time is refused even for different activities', () {
    expect(() => check([task('a', 8), task('b', 8, title: 'Uống trà')]),
        throwsA(isA<AppException>()));
    check([task('a', 8), task('b', 8, minute: 1, title: 'Uống trà')]);
  });
  test('two normalized names allowed, third refused regardless of habit group',
      () {
    check([task('a', 8), task('b', 9, title: '  ĐI   BỘ ')]);
    expect(
        () => check(
            [task('a', 8), task('b', 9), task('c', 10, title: ' ĐI  BỘ ')]),
        throwsA(isA<AppException>()));
    check([task('a', 8), task('b', 9), task('c', 10, title: 'Tập yoga')]);
  });
  test('same name on another date is allowed', () {
    check([task('a', 8), task('b', 9), task('c', 10, date: '2030-01-08')]);
  });
  test('future recurrence collision is caught, not only the first day', () {
    expect(
        () => check([
              task('a', 8, date: '2060-03-15'),
              task('b', 8, repeat: RepeatRule.daily)
            ]),
        throwsA(isA<AppException>()));
  });
  test('different weekdays at the same time do not collide', () {
    check([
      task('a', 8, repeat: RepeatRule.weekly, weekdays: [1]),
      task('b', 8, repeat: RepeatRule.weekly, weekdays: [2])
    ]);
  });
  test('excluded dates and moved occurrences are respected', () {
    check([
      task('a', 8).copyWith(excludedDates: ['2030-01-07']),
      task('b', 8)
    ]);
    check([
      task('a', 8),
      task('b', 8)
    ], moves: [
      const TaskReschedule(
          taskId: 'a',
          sourceDate: '2030-01-07',
          targetDate: '2030-01-08',
          hour: 8,
          minute: 0)
    ]);
    expect(
        () => check([
              task('a', 7),
              task('b', 8)
            ], moves: [
              const TaskReschedule(
                  taskId: 'a',
                  sourceDate: '2030-01-07',
                  targetDate: '2030-01-07',
                  hour: 8,
                  minute: 0)
            ]),
        throwsA(isA<AppException>()));
  });
  test('repository refuses conflicting create, allows editing the same ID',
      () async {
    final repo = FakeTaskRepository([]);
    await repo.save(task('a', 8));
    await repo.save(task('a', 8, title: 'Tưới cây'));
    await expectLater(repo.save(task('b', 8)), throwsA(isA<AppException>()));
    expect(await repo.tasksForDay(day), hasLength(1));
  });
}
