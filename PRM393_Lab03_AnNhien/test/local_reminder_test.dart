import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/local_reminder_service.dart';

void main() {
  test(
      'planner uses Vietnam wall time, excludes past/completed/disabled and respects bounds',
      () {
    final now = DateTime.utc(2026, 10, 4, 0); // 7:00 UTC+7
    const task = TaskItem(
        id: 'walk',
        title: 'Đi bộ',
        habitKey: 'move',
        hour: 8,
        minute: 0,
        startDate: '2026-10-04');
    final day = DateTime(2026, 10, 4);
    final plans = planReminders(
        'u',
        [
          ScheduleOccurrence(task, day),
          ScheduleOccurrence(task, day),
          ScheduleOccurrence(task.copyWith(id: 'past', hour: 6), day),
          ScheduleOccurrence(
              task.copyWith(id: 'done', status: TaskStatus.done), day),
          ScheduleOccurrence(task.copyWith(id: 'off', remind: false), day),
          ScheduleOccurrence(
              task.copyWith(id: 'old', endDate: '2026-10-03'), day),
          ScheduleOccurrence(task, day.add(const Duration(days: 31))),
        ],
        now);
    expect(plans.length, 1);
    expect(plans.single.time, DateTime.utc(2026, 10, 4, 1));
    expect(planReminders('u', [ScheduleOccurrence(task, day)], now).single.id,
        plans.single.id);
    expect(
        planReminders('other', [ScheduleOccurrence(task, day)], now).single.id,
        isNot(plans.single.id));
  });
  test('planner caps native alarm count and keeps distinct occurrence IDs', () {
    final now = DateTime.utc(2026, 10, 4);
    final plans = planReminders(
        'u',
        [
          for (var i = 0; i < 300; i++)
            ScheduleOccurrence(
                TaskItem(
                    id: 't$i',
                    title: 'Đi bộ',
                    habitKey: 'move',
                    hour: 8,
                    minute: 0,
                    startDate: '2026-10-04'),
                DateTime(2026, 10, 4))
        ],
        now);
    expect(plans.length, 128);
    expect(plans.map((p) => p.id).toSet().length, 128);
  });
}
