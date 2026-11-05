import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../models/habit.dart';
import '../models/relative.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';
import 'caregiver_schedule_view_model.dart' show vietnamToday;
import 'today_view_model.dart';

class CalendarDate extends Notifier<DateTime> {
  @override
  DateTime build() {
    ref.watch(sessionProvider.select((s) => s.asData?.value?.uid));
    return vietnamToday();
  }

  void select(DateTime date) =>
      state = DateTime(date.year, date.month, date.day);
  void move(int days) => select(state.add(Duration(days: days)));
}

final calendarDateProvider =
    NotifierProvider<CalendarDate, DateTime>(CalendarDate.new);

final calendarTasksProvider =
    FutureProvider.family<List<TaskItem>, String>((ref, day) async {
  ref.watch(sessionProvider.select((s) => s.asData?.value?.uid));
  final tasks =
      await ref.watch(taskRepositoryProvider).tasksForDay(DateTime.parse(day));
  return [
    ...tasks
  ]..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
});
final habitsListProvider = FutureProvider<List<Habit>>((ref) {
  ref.watch(sessionProvider.select((s) => s.asData?.value?.uid));
  return ref.watch(habitRepositoryProvider).all();
});
final habitDetailProvider = FutureProvider.family<Habit?, String>((ref, key) {
  ref.watch(sessionProvider.select((s) => s.asData?.value?.uid));
  return ref.watch(habitRepositoryProvider).byKey(key);
});
final familyListProvider = FutureProvider<List<Relative>>((ref) {
  ref.watch(sessionProvider.select((s) => s.asData?.value?.uid));
  return ref.watch(familyRepositoryProvider).all();
});

/// Existing repository status contract is TODAY only. Other dates stay read-only.
class CalendarActions extends Notifier<bool> {
  @override
  bool build() => false;
  Future<void> setDone(TaskItem task, DateTime day, {bool undo = false}) async {
    if (state) return;
    if (dateKey(day) != dateKey(vietnamToday())) {
      throw const AppException(
          'Chỉ cập nhật trạng thái của hoạt động hôm nay.');
    }
    state = true;
    try {
      final today = ref.read(todayViewModelProvider.notifier);
      // Let the notifier's initial microtask start before awaiting our load.
      await Future<void>.value();
      if (undo) {
        await today.undo(task.id, previousStatus: task.status);
      } else {
        if (today.taskById(task.id) == null) await today.load();
        if (!await today.markDone(task.id, source: 'calendar')) {
          throw const AppException(
              'Chưa thể cập nhật hoạt động. Vui lòng thử lại.');
        }
      }
      if (ref.mounted) ref.invalidate(calendarTasksProvider(dateKey(day)));
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final calendarActionsProvider =
    NotifierProvider<CalendarActions, bool>(CalendarActions.new);

class FamilySaved {
  const FamilySaved(this.saved, this.previous, this.ownerUid);
  final Relative saved;
  final Relative? previous;
  final String? ownerUid;
}

class FamilyEditor extends Notifier<bool> {
  @override
  bool build() => false;
  Future<FamilySaved> save(Relative person, {Relative? previous}) async {
    if (state) throw const AppException('Đang lưu thông tin. Vui lòng chờ.');
    final uid = ref.read(sessionProvider).asData?.value?.uid;
    if (person.name.trim().isEmpty || person.phone.trim().isEmpty) {
      throw const AppException(
          'Vui lòng nhập tên và số điện thoại người thân.');
    }
    if (!RegExp(r'^\+?[0-9 ()-]{6,20}$').hasMatch(person.phone.trim())) {
      throw const AppException('Vui lòng kiểm tra lại số điện thoại.');
    }
    state = true;
    try {
      await ref.read(familyRepositoryProvider).save(person);
      if (ref.mounted) ref.invalidate(familyListProvider);
      return FamilySaved(person, previous, uid);
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<void> undoSave(FamilySaved change) async {
    if (change.ownerUid == null ||
        ref.read(sessionProvider).asData?.value?.uid != change.ownerUid) {
      throw const AppException(
          'Tài khoản đã thay đổi. Vui lòng mở lại danh bạ.');
    }
    final repository = ref.read(familyRepositoryProvider);
    if (change.previous != null) {
      await repository.save(change.previous!);
    } else {
      await repository.delete(change.saved.id);
    }
    if (ref.mounted) ref.invalidate(familyListProvider);
  }
}

final familyEditorProvider =
    NotifierProvider<FamilyEditor, bool>(FamilyEditor.new);
