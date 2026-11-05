import 'calm_feature_providers.dart';
import 'today_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/caregiver_suggestion_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';

final pendingSuggestionsProvider =
    StreamProvider<List<ScheduleSuggestion>>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(caregiverSuggestionServiceProvider).watchPending();
});

class SuggestionDemoState {
  const SuggestionDemoState({this.busy = false, this.message});
  final bool busy;
  final String? message;
}

class SuggestionDemoViewModel extends Notifier<SuggestionDemoState> {
  int _generation = 0;
  @override
  SuggestionDemoState build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const SuggestionDemoState();
  }

  Future<bool> resolve(String id, List<int> selected,
          {Map<int, ({int hour, int minute})> times = const {}}) =>
      _run(() async {
        await ref
            .read(caregiverSuggestionServiceProvider)
            .resolve(id, selected, times: times);
        if (ref.mounted && selected.isNotEmpty) {
          ref.invalidate(todayViewModelProvider);
      ref.invalidate(calendarTasksProvider);
        }
        try {
          await ref.read(analyticsServiceProvider).logEvent(
              selected.isEmpty ? 'dismiss_suggestion' : 'accept_suggestion',
              {'task_count': selected.length});
        } catch (_) {}
      });
  Future<bool> undo(String id) =>
      _run(() => ref.read(caregiverSuggestionServiceProvider).undoDismiss(id));
  Future<bool> _run(Future<void> Function() action) async {
    if (state.busy) return false;
    final generation = _generation;
    state = const SuggestionDemoState(busy: true);
    try {
      await action();
      if (!ref.mounted || generation != _generation) return false;
      state = const SuggestionDemoState();
      return true;
    } catch (e, st) {
      try {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'suggestion_demo');
      } catch (_) {}
      if (ref.mounted && generation == _generation) {
        state = SuggestionDemoState(
            message: e is AppException
                ? e.userMessage
                : 'Chưa xử lý được gợi ý. Bác thử lại nhé.');
      }
      return false;
    }
  }
}

final suggestionDemoViewModelProvider =
    NotifierProvider<SuggestionDemoViewModel, SuggestionDemoState>(
        SuggestionDemoViewModel.new);
