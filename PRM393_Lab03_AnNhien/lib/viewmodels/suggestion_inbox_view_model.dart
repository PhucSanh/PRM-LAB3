import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/suggestion.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';
import 'suggestion_compose_view_model.dart' show suggestionClockProvider;
import 'suggestion_review_view_model.dart' show suggestionDayLabel;
import 'ui_state.dart';

/// F12 Hộp gợi ý của Bác – chủ: Sanh. G10 `66:119` / G11 `71:2` popup "gợi ý mới" (hiện **một lần**,
/// không tự đóng, đóng bằng "Để sau") + G12 `71:209` thẻ đầu S03 (`SuggestionCard`, Khang đặt).
/// Tên provider / trường giữ đúng comment trong `lib/widgets/suggestion_card.dart`.
class SuggestionInbox {
  const SuggestionInbox(
      {required this.momUid, required this.pending, required this.now});

  /// uid của Bác (máy đang mở).
  final String momUid;

  /// Gợi ý `pending`, mới nhất trước.
  final List<Suggestion> pending;

  /// Lúc nhận dữ liệu – để biết gợi ý gửi hôm nay (G10) hay trước đó (G11).
  final DateTime now;

  /// Thẻ G12: gợi ý `pending` mới nhất (`id`, `fromName`, `items`).
  Suggestion? get pendingCard => pending.firstOrNull;

  /// Popup G10 / G11: gợi ý `pending` mới nhất chưa `popupShown`.
  Suggestion? get popupToShow =>
      pending.where((s) => !s.popupShown).firstOrNull;

  /// G10 (có dòng "Mai vừa gửi lúc 4:20 chiều") khi gợi ý gửi **hôm nay**; ngược lại G11 (DT-33).
  bool sentToday(Suggestion s) =>
      s.createdAt.year == now.year &&
      s.createdAt.month == now.month &&
      s.createdAt.day == now.day;

  /// "ngày mai" trong "2 việc cho ngày mai".
  String dayLabel(Suggestion s) => s.items.isEmpty
      ? 'ngày mai'
      : suggestionDayLabel(s.items.first.date, now);
}

const _loadFailed = 'Chưa tải được gợi ý. Bác bấm "Thử lại" nhé.';

/// UiEmpty = chưa đăng nhập hoặc không có gợi ý chờ (S03 không chiếm chỗ cho thẻ, không có popup).
/// Theo dõi phiên đăng nhập: đổi tài khoản thì nghe lại đúng `users/{uid}/suggestions`.
class SuggestionInboxViewModel extends Notifier<UiState<SuggestionInbox>> {
  StreamSubscription<List<Suggestion>>? _sub;

  @override
  UiState<SuggestionInbox> build() {
    ref.onDispose(() => _sub?.cancel());
    final session = ref.watch(sessionProvider);
    if (session.isLoading) return const UiLoading();
    final uid = session.value?.uid;
    if (uid == null) return const UiEmpty();
    _sub = ref.read(suggestionServiceProvider).watchPending(uid).listen(
      (list) {
        if (!ref.mounted) return;
        state = list.isEmpty
            ? const UiEmpty()
            : UiData(SuggestionInbox(
                momUid: uid,
                pending: list,
                now: ref.read(suggestionClockProvider)()));
      },
      onError: (Object e, StackTrace st) {
        if (!ref.mounted) return;
        // Lỗi đọc dữ liệu, không phải lỗi lưu → không ghi Crashlytics.
        state = UiError(e is AppException ? e.userMessage : _loadFailed);
      },
    );
    return const UiLoading();
  }

  /// "Thử lại" khi lỗi tải.
  void retry() => ref.invalidateSelf();

  /// Popup G10 / G11 vừa hiện: đánh dấu ngay để mở lại app không hiện lại. Lỗi ghi không chặn Bác
  /// (popup đã hiện; lần sau có thể hiện lại – chấp nhận được).
  Future<void> markPopupShown(String id) async {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data == null) return;
    try {
      await ref.read(suggestionServiceProvider).markPopupShown(data.momUid, id);
    } catch (e, st) {
      try {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'mark_popup_shown');
      } catch (_) {}
    }
  }

  /// G11 "Để sau": chỉ đóng popup; gợi ý vẫn `pending` → thẻ G12 trên S03.
  /// Gọi lại `markPopupShown` (không đổi gì nếu đã đánh dấu) phòng lần đánh dấu lúc hiện bị lỗi.
  Future<void> later(String id) => markPopupShown(id);
}

final suggestionInboxViewModelProvider =
    NotifierProvider<SuggestionInboxViewModel, UiState<SuggestionInbox>>(
        SuggestionInboxViewModel.new);
