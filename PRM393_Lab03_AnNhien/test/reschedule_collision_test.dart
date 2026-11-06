import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/utils/app_error.dart';

void main() {
  test('reject moving daily occurrence onto another day of its series, keep both days unchanged', () async {
    const task = TaskItem(id:'walk',title:'Đi bộ',habitKey:'move',hour:8,minute:0,startDate:'2099-11-01');
    final repo = FakeTaskRepository([task]);
    final original = (await repo.tasksForDay(DateTime(2099,11,7))).single;
    await expectLater(repo.reschedule(original,targetDay:DateTime(2099,11,8),hour:15,minute:0), throwsA(isA<AppException>()));
    expect((await repo.tasksForDay(DateTime(2099,11,7))).single.hour,8);
    expect((await repo.tasksForDay(DateTime(2099,11,8))).single.hour,8);
  });
  test('reject two sources moved into same free target day; allow same-day time change', () {
    const task = TaskItem(id:'weekly',title:'Đi bộ',habitKey:'move',hour:8,minute:0,
      startDate:'2099-11-01',repeat:RepeatRule.weekly,weekdays:[DateTime.monday]);
    final target = DateTime(2099,11,8);
    final r = TaskReschedule(taskId:task.id,sourceDate:'2099-11-01',targetDate:dateKey(target),hour:10,minute:0);
    expect(() => validateRescheduleTarget(task,'2099-10-25',target,[r]),throwsA(isA<AppException>()));
    expect(() => validateRescheduleTarget(task,'2099-11-08',target,[]),returnsNormally);
  });
  test('stale Undo cannot replace a later move', () async {
    const task = TaskItem(id:'once',title:'Đi bộ',habitKey:'move',hour:8,minute:0,
      startDate:'2099-11-01',repeat:RepeatRule.once);
    final repo = FakeTaskRepository([task]);
    final first = await repo.reschedule((await repo.tasksForDay(DateTime(2099,11,1))).single,targetDay:DateTime(2099,11,2),hour:10,minute:0);
    final second = await repo.reschedule((await repo.tasksForDay(DateTime(2099,11,2))).single,targetDay:DateTime(2099,11,3),hour:11,minute:0);
    await expectLater(repo.restoreReschedule(first),throwsA(isA<AppException>()));
    await repo.restoreReschedule(second);
    expect((await repo.tasksForDay(DateTime(2099,11,2))).single.hour,10);
  });
}
