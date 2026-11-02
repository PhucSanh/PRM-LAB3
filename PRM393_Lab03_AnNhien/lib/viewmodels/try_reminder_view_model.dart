import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers.dart';
import '../utils/app_error.dart';

/// F2 Thử lời nhắc – chủ: Hương. Màn N01 / N02 / N03 (`/setup/try-reminder`).
/// Màn không tải dữ liệu nên không dùng `UiState`; lỗi gửi thử nằm ở [TryReminderState.error].

/// idle (N01 `31:68`) → sending → waitingAnswer (N02 `31:170`: "Bác đã nhận được
/// chưa?") → received (View đi tiếp) / notReceived (N03 `31:218`).
enum TryReminderPhase { idle, sending, waitingAnswer, received, notReceived }

class TryReminderState {
  const TryReminderState({this.phase = TryReminderPhase.idle, this.error});

  final TryReminderPhase phase;

  /// Lỗi gửi thử (`AppException.userMessage`); View hiện kèm nút "Thử lại".
  final String? error;

  bool get sending => phase == TryReminderPhase.sending;

  TryReminderState copyWith({TryReminderPhase? phase, String? error}) =>
      TryReminderState(phase: phase ?? this.phase, error: error);
}

class TryReminderViewModel extends Notifier<TryReminderState> {
  @override
  TryReminderState build() => const TryReminderState();

  /// "Gửi thử" (N01): hiện ngay một lời nhắc thử rồi hỏi Bác đã nhận chưa.
  /// Lỗi → về N01 kèm câu lỗi + "Thử lại".
  Future<void> sendTest() async {
    if (state.sending) return;
    state = const TryReminderState(phase: TryReminderPhase.sending);
    try {
      await ref.read(reminderServiceProvider).showTest();
      if (!ref.mounted) return;
      state = const TryReminderState(phase: TryReminderPhase.waitingAnswer);
    } catch (e, st) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'show_test_reminder');
      if (!ref.mounted) return;
      state = TryReminderState(
        phase: TryReminderPhase.idle,
        error: e is AppException
            ? e.userMessage
            : 'Chưa gửi được lời nhắc thử. Bác bấm "Thử lại" nhé.',
      );
    }
  }

  /// "Đã nhận được" / "Chưa nhận được" (N02). Log `test_reminder` một lần
  /// mỗi câu trả lời, chỉ gửi cờ `received`.
  Future<void> answer(bool received) async {
    if (state.phase != TryReminderPhase.waitingAnswer) return;
    state = TryReminderState(
        phase: received
            ? TryReminderPhase.received
            : TryReminderPhase.notReceived);
    try {
      await ref
          .read(analyticsServiceProvider)
          .logEvent('test_reminder', {'received': received});
    } catch (_) {/* Analytics không được chặn Bác. */}
  }

  /// "Thử lại" (N03 hoặc sau lỗi): gửi lại lời nhắc thử.
  Future<void> retry() => sendTest();

  /// "Quay lại" ở N02 / N03 → về N01 (cùng route).
  void backToStart() => state = const TryReminderState();
}

final tryReminderViewModelProvider =
    NotifierProvider<TryReminderViewModel, TryReminderState>(
        TryReminderViewModel.new);
