import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/suggestion.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// F12 Con cháu soạn và gửi gợi ý – chủ: Sanh. Route `/caregiver/suggest` (máy con cháu).
/// Cùng một màn, vẽ theo [SuggestionComposeStep]:
/// G01 `52:161` soạn (2 việc cho ngày mai, chọn giờ từng việc, lời nhắn) ·
/// G01b `52:230` xác nhận "Gửi gợi ý cho mẹ?" · G02 `56:2` đã gửi.
/// Chưa ghép nối → [SuggestionComposeStep.needsPairing] (View dẫn tới `/caregiver/pair`).
/// Gửi **không** đổi lịch của mẹ: chỉ ghi gợi ý `pending`, mẹ tự nhận / đổi giờ / bỏ qua.
enum SuggestionComposeStep { needsPairing, compose, confirm, sent }

class SuggestionCompose {
  const SuggestionCompose({
    required this.step,
    required this.fromUid,
    this.fromName = '',
    this.momUid,
    this.items = const [],
    this.habitNames = const {},
    this.message = '',
    this.sending = false,
    this.sendError,
  });

  final SuggestionComposeStep step;

  /// uid + tên của người gửi (máy con cháu). Tên không gửi lên analytics.
  final String fromUid;
  final String fromName;

  /// `null` khi chưa ghép nối.
  final String? momUid;

  /// Việc gợi ý; giờ đang chọn = `hour` / `minute` của từng việc.
  final List<SuggestionItem> items;

  /// Tên thói quen theo khoá (nạp từ `HabitRepository`), vd. move → "Vận động tự nhiên".
  /// Thiếu (lỗi nạp) thì View chỉ hiện thời lượng.
  final Map<String, String> habitNames;

  /// Lời nhắn (không bắt buộc).
  final String message;

  /// Đang gửi: nút hiện vòng xoay, chặn bấm lần 2.
  final bool sending;

  /// Lỗi gửi (`AppException.userMessage`); nội dung đã soạn vẫn giữ.
  final String? sendError;

  bool get needsPairing => step == SuggestionComposeStep.needsPairing;

  SuggestionCompose copyWith({
    SuggestionComposeStep? step,
    List<SuggestionItem>? items,
    String? message,
    bool? sending,
    String? sendError,
  }) =>
      SuggestionCompose(
        step: step ?? this.step,
        fromUid: fromUid,
        fromName: fromName,
        momUid: momUid,
        items: items ?? this.items,
        habitNames: habitNames,
        message: message ?? this.message,
        sending: sending ?? this.sending,
        sendError: sendError,
      );
}

/// Giờ hiện tại – test override để cố định "ngày mai".
final suggestionClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

const _loadFailed = 'Chưa tải được tài khoản. Bấm "Thử lại" nhé.';
const _sendFailed = 'Chưa gửi được gợi ý. Bấm "Thử lại" nhé.';

class SuggestionComposeViewModel extends Notifier<UiState<SuggestionCompose>> {
  String _requestId = '';

  /// 2 việc gợi ý mặc định cho ngày mai, đúng Figma G01 `52:161` (người dùng chọn 04/11:
  /// mẫu trong ViewModel). Không phải danh sách thói quen – tên thói quen nạp từ `HabitRepository`.
  /// TODO(Hiếu): thay bằng `habits/{key}.suggestions[]` khi có dữ liệu.
  static List<SuggestionItem> defaultItems(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    const options = [SuggestionTime(8, 0), SuggestionTime(9, 0)];
    return [
      SuggestionItem(
        title: 'Đi bộ nhẹ nhàng',
        habitKey: 'move',
        date: tomorrow,
        hour: 8,
        minute: 0,
        durationMin: 20,
        timeOptions: options,
      ),
      SuggestionItem(
        title: 'Thư giãn nhẹ nhàng',
        habitKey: 'downshift',
        date: tomorrow,
        hour: 9,
        minute: 0,
        durationMin: 15,
        timeOptions: options,
      ),
    ];
  }

  @override
  UiState<SuggestionCompose> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    _requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      state = const UiError('Bạn cần đăng nhập lại.');
      return;
    }
    try {
      final profile = await ref
          .read(profileServiceProvider)
          .watch(user.uid)
          .first
          .timeout(const Duration(seconds: 15));
      if (!ref.mounted) return;
      final momUid = profile.pairedMomUid;
      state = UiData(SuggestionCompose(
        step: momUid == null
            ? SuggestionComposeStep.needsPairing
            : SuggestionComposeStep.compose,
        fromUid: user.uid,
        fromName: profile.displayName ?? user.displayName ?? '',
        momUid: momUid,
        items: defaultItems(ref.read(suggestionClockProvider)()),
        habitNames: await _habitNames(),
      ));
    } catch (e) {
      if (!ref.mounted) return;
      state = UiError(e is AppException ? e.userMessage : _loadFailed);
    }
  }

  /// Tên thói quen chỉ để hiện dòng phụ; lỗi nạp không chặn việc gửi.
  Future<Map<String, String>> _habitNames() async {
    try {
      final habits = await ref.read(habitRepositoryProvider).all();
      return {for (final h in habits) h.key: h.name};
    } catch (_) {
      return const {};
    }
  }

  void _update(SuggestionCompose Function(SuggestionCompose) change) {
    if (state case UiData(:final data)) state = UiData(change(data));
  }

  /// G01: bấm một nút giờ → việc [index] dùng giờ đó (một việc đúng một giờ).
  void selectTime(int index, SuggestionTime time) => _update((d) {
        if (d.sending || index < 0 || index >= d.items.length) return d;
        final items = [...d.items];
        items[index] =
            items[index].copyWith(hour: time.hour, minute: time.minute);
        return d.copyWith(items: items);
      });

  void setMessage(String text) => _update((d) => d.copyWith(message: text));

  /// G01 "Gửi gợi ý cho mẹ" → G01b (hỏi lại trước khi gửi).
  void requestSend() => _update((d) => d.step == SuggestionComposeStep.compose
      ? d.copyWith(step: SuggestionComposeStep.confirm)
      : d);

  /// G01b "Sửa lại" → G01, giữ nguyên giờ đã chọn và lời nhắn.
  void editAgain() =>
      _update((d) => d.step == SuggestionComposeStep.confirm && !d.sending
          ? d.copyWith(step: SuggestionComposeStep.compose)
          : d);

  /// G01b "Gửi gợi ý" → G02. `SuggestionService.send`; log `send_suggestion { items, source: suggest }`
  /// (không gửi tên, lời nhắn). Lỗi → Crashlytics non-fatal + `sendError`, giữ nguyên dữ liệu.
  /// `true` khi đã gửi.
  Future<bool> send() async {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data == null ||
        data.sending ||
        data.step != SuggestionComposeStep.confirm ||
        data.momUid == null ||
        data.items.isEmpty) {
      return false;
    }
    state = UiData(data.copyWith(sending: true));
    final suggestion = Suggestion(
      id: _requestId,
      fromUid: data.fromUid,
      fromName: data.fromName,
      // TODO(Hiếu): quan hệ với mẹ ("Con gái") khi ghép nối (F13) – chưa có trong hồ sơ (DT-30).
      fromRelation: null,
      message: data.message.trim(),
      items: data.items,
      createdAt: ref.read(suggestionClockProvider)(),
    );
    try {
      await ref.read(suggestionServiceProvider).send(data.momUid!, suggestion);
    } catch (e, st) {
      if (!ref.mounted) return false;
      try {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'send_suggestion');
      } catch (_) {/* Crashlytics không được chặn người dùng. */}
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          sending: false,
          sendError: e is AppException ? e.userMessage : _sendFailed));
      return false;
    }
    if (!ref.mounted) return false;
    _update(
        (d) => d.copyWith(sending: false, step: SuggestionComposeStep.sent));
    try {
      await ref.read(analyticsServiceProvider).logEvent('send_suggestion', {
        'items': data.items.length,
        'source': 'suggest',
      });
    } catch (_) {/* Analytics không được chặn người dùng. */}
    return true;
  }
}

/// autoDispose: rời màn rồi vào lại thì soạn gợi ý mới (không còn ở G02).
final suggestionComposeViewModelProvider = NotifierProvider.autoDispose<
    SuggestionComposeViewModel,
    UiState<SuggestionCompose>>(SuggestionComposeViewModel.new);
