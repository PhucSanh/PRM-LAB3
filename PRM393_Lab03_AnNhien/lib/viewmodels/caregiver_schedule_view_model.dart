import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../services/caregiver_schedule_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'account_view_model.dart';
import 'ui_state.dart';

DateTime vietnamToday() =>
    calendarDate(DateTime.now().toUtc().add(const Duration(hours: 7)));
final pairedMomUidProvider =
    Provider<String?>((ref) => ref.watch(profileProvider).value?.pairedMomUid);

enum CalendarView { day, week, month }

class CaregiverCalendarState {
  const CaregiverCalendarState(
      {required this.date,
      this.view = CalendarView.day,
      this.items = const UiLoading(),
      this.message,
      this.busy = false});
  final DateTime date;
  final CalendarView view;
  final UiState<List<ScheduleOccurrence>> items;
  final String? message;
  final bool busy;
  CaregiverCalendarState copyWith(
          {DateTime? date,
          CalendarView? view,
          UiState<List<ScheduleOccurrence>>? items,
          String? message,
          bool? busy}) =>
      CaregiverCalendarState(
          date: date ?? this.date,
          view: view ?? this.view,
          items: items ?? this.items,
          message: message,
          busy: busy ?? this.busy);
}

class CaregiverScheduleViewModel extends Notifier<CaregiverCalendarState> {
  StreamSubscription<List<ScheduleOccurrence>>? _subscription;
  int _generation = 0;
  @override
  CaregiverCalendarState build() {
    ref.watch(pairedMomUidProvider);
    ref.watch(caregiverScheduleServiceProvider);
    ref.onDispose(() => _subscription?.cancel());
    Future.microtask(load);
    return CaregiverCalendarState(date: vietnamToday());
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    final generation = ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (!ref.mounted || generation != _generation) return;
    final mom = ref.read(pairedMomUidProvider);
    if (mom == null) {
      state = state.copyWith(
          items: const UiEmpty(),
          message: 'Cần ghép nối với máy của mẹ để xem lịch.');
      return;
    }
    state = state.copyWith(items: const UiLoading());
    final date = state.date;
    final from = switch (state.view) {
      CalendarView.day => date,
      CalendarView.week => date.subtract(Duration(days: date.weekday - 1)),
      CalendarView.month => DateTime(date.year, date.month)
    };
    final through = switch (state.view) {
      CalendarView.day => date,
      CalendarView.week => from.add(const Duration(days: 6)),
      CalendarView.month => DateTime(date.year, date.month + 1, 0)
    };
    _subscription = ref
        .read(caregiverScheduleServiceProvider)
        .watch(mom, from, through)
        .listen((items) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
            items: items.isEmpty ? const UiEmpty() : UiData(items));
      }
    }, onError: (Object e) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
            items: UiError(e is AppException
                ? e.userMessage
                : 'Chưa tải được lịch. Thử lại nhé.'));
      }
    });
  }

  void selectDate(DateTime date) {
    if (calendarDate(date) == state.date) return;
    final next = calendarDate(date);
    final previous = state.date;
    final sameRange = switch (state.view) {
      CalendarView.day => false,
      CalendarView.week =>
        previous.subtract(Duration(days: previous.weekday - 1)) ==
            next.subtract(Duration(days: next.weekday - 1)),
      CalendarView.month =>
        previous.year == next.year && previous.month == next.month,
    };
    state = state.copyWith(date: next);
    if (!sameRange) load();
  }

  void selectView(CalendarView view) {
    if (view == state.view) return;
    state = state.copyWith(view: view);
    load();
  }

  void move(int direction) {
    final d = state.date;
    selectDate(switch (state.view) {
      CalendarView.day => d.add(Duration(days: direction)),
      CalendarView.week => d.add(Duration(days: 7 * direction)),
      CalendarView.month => DateTime(d.year, d.month + direction)
    });
  }

  Future<ScheduleUndo?> stop(TaskItem task, DateTime date) async {
    if (state.busy) return null;
    final mom = ref.read(pairedMomUidProvider);
    if (mom == null) return null;
    state = state.copyWith(busy: true);
    try {
      final undo = await ref
          .read(caregiverScheduleServiceProvider)
          .change(mom, task, date, null, ChangeScope.future);
      if (ref.mounted) state = state.copyWith(busy: false);
      return undo;
    } catch (e, st) {
      await _error(e, st);
      return null;
    }
  }

  Future<void> undo(ScheduleUndo undo) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      await ref.read(caregiverScheduleServiceProvider).undo(undo);
      if (ref.mounted) state = state.copyWith(busy: false);
    } catch (e, st) {
      await _error(e, st);
    }
  }

  Future<void> _error(Object e, StackTrace st) async {
    try {
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'caregiver_schedule');
    } catch (_) {}
    if (ref.mounted) {
      state = state.copyWith(
          busy: false,
          message: e is AppException
              ? e.userMessage
              : 'Chưa lưu được lịch. Thử lại nhé.');
    }
  }
}

final caregiverScheduleViewModelProvider =
    NotifierProvider<CaregiverScheduleViewModel, CaregiverCalendarState>(
        CaregiverScheduleViewModel.new);
