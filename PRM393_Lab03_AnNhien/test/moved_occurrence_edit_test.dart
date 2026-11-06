import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/task_repository.dart';

void main() {
  for(final deleting in [false,true]) {
    test('moved one-off ${deleting ? 'delete' : 'edit'} preserves original day and Undo restores move', () async {
      const task = TaskItem(id:'walk', title:'Đi bộ', habitKey:'move', hour:8,
        minute:0, repeat:RepeatRule.once, startDate:'2099-11-07');
      const moved = TaskReschedule(taskId:'walk', sourceDate:'2099-11-07', targetDate:'2099-11-08', hour:10, minute:30);
      final service = FakeCaregiverScheduleService([task]); addTearDown(service.dispose);
      service.reschedules[moved.key] = moved;
      final original = (await service.watch('u',DateTime(2099,11,8),DateTime(2099,11,8)).first).single.task;
      expect(original.isRescheduled, true);
      final undo = await service.change('u',original,DateTime(2099,11,8),
        deleting ? null : original.copyWith(title:'Đi bộ cùng con',hour:11),ChangeScope.occurrence);
      final current = await service.watch('u',DateTime(2099,11,7),DateTime(2099,11,8)).first;
      expect(current.length,deleting ? 0 : 1);
      if(!deleting) { expect(current.single.task.title,'Đi bộ cùng con'); expect(current.single.task.hour,11); }
      expect(service.reschedules, isEmpty);
      await service.undo(undo);
      final restored = await service.watch('u',DateTime(2099,11,7),DateTime(2099,11,8)).first;
      expect(restored.single.date,DateTime(2099,11,8));
      expect(restored.single.task.hour,10);
      expect(restored.single.task.isRescheduled,true);
    });
  }
  test('editing moved daily occurrence leaves all other repetitions unchanged', () {
    const task = TaskItem(id:'daily',title:'Đi bộ',habitKey:'move',hour:8,minute:0,startDate:'2099-11-01');
    const moved = TaskReschedule(taskId:'daily',sourceDate:'2099-11-07',targetDate:'2099-11-08',hour:10,minute:0);
    final plan = planScheduleChange(task,DateTime(2099,11,8),task.copyWith(title:'Đổi riêng lần dời'),ChangeScope.occurrence,'detached',moved:moved);
    expect(plan.after['daily']!.occursOn(DateTime(2099,11,7)),false);
    expect(plan.after['daily']!.occursOn(DateTime(2099,11,9)),true);
    expect(plan.after['detached']!.repeat,RepeatRule.once);
    expect(plan.after['detached']!.occursOn(DateTime(2099,11,9)),false);
  });
}
