import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// F2 Việc đầu tiên – chủ: Hương. Màn N04 → N05 → N18 (`/setup/first-task`).
/// Bước 01 chỉ dựng khung; bước 06 điền logic.

/// N04 chọn việc · N05 chọn giờ · N18 đã lưu.
enum FirstTaskStep { pick, time, saved }

class FirstTaskData {
  const FirstTaskData({
    required this.habits,
    this.step = FirstTaskStep.pick,
    this.habitKey,
    // TODO bước 06: mặc định theo Figma N05 / giờ thức dậy đã lưu.
    this.time = const TimeOfDay(hour: 7, minute: 0),
    this.saving = false,
    this.saveError,
  });

  /// Gợi ý nạp từ `HabitRepository.all()` (không hard-code 9 thói quen).
  final List<Habit> habits;
  final FirstTaskStep step;
  final String? habitKey;
  final TimeOfDay time;
  final bool saving;

  /// Lỗi lưu (`AppException.userMessage`); lựa chọn vẫn giữ.
  final String? saveError;

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
      state = habits.isEmpty
          ? const UiEmpty()
          : UiData(FirstTaskData(habits: habits));
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

  /// TODO bước 06: chọn thói quen → N05.
  void pick(String habitKey) {}

  /// TODO bước 06.
  void setTime(TimeOfDay time) {}

  /// TODO bước 06: `TaskRepository.save` + log `add_task`
  /// (`habit_key`, `repeat`, `source: "first_task"`, `duration_sec`) → N18.
  Future<bool> save() async => false;

  /// TODO bước 06 (từ N18): `ProfileService.markOnboarded(uid)` + log
  /// `tutorial_complete` (`font_size`, `notifications_on`, `has_first_task`).
  Future<bool> finish() async => false;
}

final firstTaskViewModelProvider =
    NotifierProvider<FirstTaskViewModel, UiState<FirstTaskData>>(
        FirstTaskViewModel.new);
