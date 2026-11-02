import 'package:flutter_riverpod/flutter_riverpod.dart';

/// F2 Thử lời nhắc – chủ: Hương. Màn N01 / N02 / N03 (`/setup/try-reminder`).
/// Màn không tải dữ liệu nên không dùng `UiState`; lỗi gửi thử nằm ở [TryReminderState.error].
/// Bước 01 chỉ dựng khung; bước 05 điền logic.

/// idle (N01) → sending → waitingAnswer → received (N02) / notReceived (N03).
enum TryReminderPhase { idle, sending, waitingAnswer, received, notReceived }

class TryReminderState {
  const TryReminderState({this.phase = TryReminderPhase.idle, this.error});

  final TryReminderPhase phase;

  /// Lỗi gửi thử (`AppException.userMessage`); View hiện kèm nút "Thử lại".
  final String? error;

  TryReminderState copyWith({TryReminderPhase? phase, String? error}) =>
      TryReminderState(phase: phase ?? this.phase, error: error);
}

class TryReminderViewModel extends Notifier<TryReminderState> {
  @override
  TryReminderState build() => const TryReminderState();

  /// TODO bước 05: `ReminderService.showTest()`; lỗi → [TryReminderState.error]
  /// + `CrashService.recordError`.
  Future<void> sendTest() async {}

  /// TODO bước 05: received / notReceived + log `test_reminder` (`received`: bool).
  Future<void> answer(bool received) async {}

  /// TODO bước 05: về idle rồi gửi lại.
  Future<void> retry() async {}
}

final tryReminderViewModelProvider =
    NotifierProvider<TryReminderViewModel, TryReminderState>(
        TryReminderViewModel.new);
