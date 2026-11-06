import 'calm_feature_providers.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../models/task_item.dart';
import '../services/providers.dart';
import '../theme/display_settings.dart';
import '../utils/app_error.dart';
import 'onboarding_view_model.dart';
import 'ui_state.dart';

/// F2 Việc đầu tiên – chủ: Hương. Màn N04 → N05 → N18 (`/setup/first-task`).
/// Gợi ý = 9 thói quen từ `HabitRepository` (Habit chưa có `suggestions[]`, DT-27);
/// việc lưu lặp mỗi ngày, bắt đầu hôm nay, chỉ đổi được giờ.

/// N04 chọn việc · N05 xem lại + đổi giờ · N18 đã lưu.
enum FirstTaskStep { pick, time, saved }

class FirstTaskData {
  const FirstTaskData({
    required this.habits,
    this.step = FirstTaskStep.pick,
    this.habitKey,
    // Figma N05 `38:108`: "Giờ nhắc 9:00 sáng".
    this.time = const TimeOfDay(hour: 9, minute: 0),
    this.saving = false,
    this.saveError,
  });

  /// Gợi ý nạp từ `HabitRepository.all()` (không hard-code 9 thói quen).
  final List<Habit> habits;
  final FirstTaskStep step;
  final String? habitKey;
  final TimeOfDay time;

  /// Đang lưu việc / đang hoàn tất onboarding: nút hiện vòng xoay.
  final bool saving;

  /// Lỗi lưu (`AppException.userMessage`); lựa chọn vẫn giữ.
  final String? saveError;

  Habit? get habit => habits.where((h) => h.key == habitKey).firstOrNull;

  /// Tên việc = tên thói quen đã chọn.
  String get title => habit?.name ?? '';

  FirstTaskData copyWith({
    FirstTaskStep? step,
    String? habitKey,
    TimeOfDay? time,
    bool? saving,
    String? saveError,
  }) =>
      FirstTaskData(
        habits: habits,
        step: step ?? this.step,
        habitKey: habitKey ?? this.habitKey,
        time: time ?? this.time,
        saving: saving ?? this.saving,
        saveError: saveError,
      );
}

class FirstTaskViewModel extends Notifier<UiState<FirstTaskData>> {
  /// Mốc mở N04 để tính `add_task.duration_sec`.
  DateTime _startedAt = DateTime.now();
  bool _hasFirstTask = false;

  @override
  UiState<FirstTaskData> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      final habits = await ref.read(habitRepositoryProvider).all();
      if (!ref.mounted) return;
      _startedAt = DateTime.now();
      // Figma N04: việc đầu danh sách chọn sẵn.
      state = habits.isEmpty
          ? const UiEmpty()
          : UiData(FirstTaskData(habits: habits, habitKey: habits.first.key));
    } catch (e, st) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'load_first_task');
      if (!ref.mounted) return;
      state = UiError(
          e is AppException ? e.userMessage : 'Chưa tải được việc gợi ý.');
    }
  }

  void _update(FirstTaskData Function(FirstTaskData) change) {
    if (state case UiData(:final data)) state = UiData(change(data));
  }

  /// Chạm một thói quen ở N04.
  void pick(String habitKey) => _update((d) => d.copyWith(habitKey: habitKey));

  /// "Tiếp tục" ở N04 → N05.
  void confirmPick() => _update(
      (d) => d.habitKey == null ? d : d.copyWith(step: FirstTaskStep.time));

  /// "Quay lại" ở N05 → N04 (giữ lựa chọn).
  void backToPick() => _update((d) => d.copyWith(step: FirstTaskStep.pick));

  void setTime(TimeOfDay time) => _update((d) => d.copyWith(time: time));

  /// "Lưu việc" ở N05: lưu việc lặp mỗi ngày → N18. Lỗi → `saveError`, giữ
  /// lựa chọn. Log `add_task` (chỉ khoá / số, không gửi tên việc).
  Future<bool> save() async {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data == null || data.saving || data.habitKey == null) return false;
    state = UiData(data.copyWith(saving: true));
    final task = TaskItem(
      id: 'first-${DateTime.now().millisecondsSinceEpoch}',
      title: data.title,
      habitKey: data.habitKey!,
      hour: data.time.hour,
      minute: data.time.minute,
      repeat: RepeatRule.daily,
    );
    try {
      await ref.read(taskRepositoryProvider).save(task);
    } catch (e, st) {
      if (!ref.mounted) return false;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'save_first_task');
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          saving: false,
          saveError: e is AppException
              ? e.userMessage
              : 'Chưa lưu được việc. Bác bấm "Thử lại" nhé.'));
      return false;
    }
    if (!ref.mounted) return false;
    ref.invalidate(calendarTasksProvider);
    _hasFirstTask = true;
    _update((d) => d.copyWith(saving: false, step: FirstTaskStep.saved));
    await _scheduleReminder(task);
    try {
      await ref.read(analyticsServiceProvider).logEvent('add_task', {
        'habit_key': task.habitKey,
        'repeat': task.repeat.name,
        'source': 'first_task',
        'duration_sec': DateTime.now().difference(_startedAt).inSeconds,
      });
    } catch (_) {/* Analytics không được chặn Bác. */}
    return true;
  }

  /// Bác đã cho phép nhắc việc (S13) thì đặt lời nhắc cho việc vừa lưu.
  /// Lỗi không chặn Bác (việc đã lưu), chỉ ghi Crashlytics.
  Future<void> _scheduleReminder(TaskItem task) async {
    try {
      if (!await _notificationsOn()) return;
      await ref.read(reminderServiceProvider).schedule(task);
    } catch (e, st) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'schedule_first_task');
    }
  }

  /// Cờ từ S13 (OnboardingViewModel) hoặc quyền thật của máy (Bác đã cho phép
  /// từ trước / bỏ qua S13 vì có quyền sẵn).
  Future<bool> _notificationsOn() async {
    if (ref.read(onboardingViewModelProvider) case UiData(:final data)
        when data.notificationsOn) {
      return true;
    }
    return ref.read(reminderServiceProvider).hasPermission();
  }

  /// Hoàn tất onboarding – "Xem lịch" / "Thêm việc khác" (N18) hoặc "Để sau"
  /// (N04, không có việc đầu tiên). `ProfileService.markOnboarded` + log
  /// `tutorial_complete`. `true` → View đi tiếp. Lỗi → `saveError`.
  Future<bool> finish() async {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data?.saving ?? false) return false;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      _update((d) =>
          d.copyWith(saveError: 'Bác cần đăng nhập lại rồi mới lưu được.'));
      return false;
    }
    _update((d) => d.copyWith(saving: true));
    try {
      await ref.read(profileServiceProvider).markOnboarded(uid);
    } catch (e, st) {
      if (!ref.mounted) return false;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'mark_onboarded');
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          saving: false,
          saveError: e is AppException
              ? e.userMessage
              : AppException.unknown.userMessage));
      return false;
    }
    if (!ref.mounted) return false;
    _update((d) => d.copyWith(saving: false));
    try {
      final notificationsOn = await _notificationsOn();
      await ref.read(analyticsServiceProvider).logEvent('tutorial_complete', {
        'font_size': _fontSizeKey(ref.read(fontScaleProvider)),
        'notifications_on': notificationsOn,
        'has_first_task': _hasFirstTask,
      });
    } catch (_) {/* Analytics không được chặn Bác. */}
    return true;
  }

  /// Giá trị `font_size` theo docs/analytics-plan.md: vua / lon / rat_lon.
  static String _fontSizeKey(AppFontScale scale) => switch (scale) {
        AppFontScale.vua => 'vua',
        AppFontScale.lon => 'lon',
        AppFontScale.ratLon => 'rat_lon',
      };
}

final firstTaskViewModelProvider =
    NotifierProvider<FirstTaskViewModel, UiState<FirstTaskData>>(
        FirstTaskViewModel.new);
