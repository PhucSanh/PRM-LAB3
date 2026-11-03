import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/suggestion_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';

final pendingSuggestionsProvider =
    StreamProvider<List<ScheduleSuggestion>>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(suggestionServiceProvider).watchPending();
});

class SuggestionDemoState {
  const SuggestionDemoState({this.busy = false, this.message});
  final bool busy;
  final String? message;
}

class SuggestionDemoViewModel extends Notifier<SuggestionDemoState> {
  @override
  SuggestionDemoState build() {
    ref.watch(sessionProvider);
    return const SuggestionDemoState();
  }

  Future<bool> resolve(String id, List<int> selected,
          {Map<int, ({int hour, int minute})> times = const {}}) =>
      _run(() async {
        await ref
            .read(suggestionServiceProvider)
            .resolve(id, selected, times: times);
        try {
          await ref.read(analyticsServiceProvider).logEvent(
              selected.isEmpty ? 'dismiss_suggestion' : 'accept_suggestion',
              {'task_count': selected.length});
        } catch (_) {}
      });
  Future<bool> undo(String id) =>
      _run(() => ref.read(suggestionServiceProvider).undoDismiss(id));
  Future<bool> _run(Future<void> Function() action) async {
    if (state.busy) return false;
    state = const SuggestionDemoState(busy: true);
    try {
      await action();
      if (ref.mounted) state = const SuggestionDemoState();
      return true;
    } catch (e, st) {
      try {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'suggestion_demo');
      } catch (_) {}
      if (ref.mounted)
        state = SuggestionDemoState(
            message: e is AppException
                ? e.userMessage
                : 'Chưa xử lý được gợi ý. Bác thử lại nhé.');
      return false;
    }
  }
}

final suggestionDemoViewModelProvider =
    NotifierProvider<SuggestionDemoViewModel, SuggestionDemoState>(
        SuggestionDemoViewModel.new);
