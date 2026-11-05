import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relative.dart';
import '../services/contact_launcher_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// F11 Nhắn tin cho người thân – chủ: Hương. `/family/:personId/share`.
/// S17 `1:2278` (chọn Zalo / SMS), S17b `26:122` + N10 `41:205` (đã mở app nhắn tin).
/// App **không bao giờ** báo "Đã gửi": chỉ biết đã mở được app (S17b "chưa biết tin
/// này đã đến … chưa").

/// Nội dung mẫu Figma S17b. Cách soạn nội dung (xưng hô theo quan hệ, việc hôm nay
/// từ `TaskRepository`…) chốt ở bước 05.
const figmaSampleMessage = 'Mẹ nhớ con. Hôm nay mẹ khỏe, con nhé!';

class ShareMessage {
  const ShareMessage({
    required this.recipient,
    required this.text,
    this.channel = ShareChannel.zalo,
    this.opened = false,
    this.sending = false,
    this.error,
  });

  final Relative recipient;

  /// Nội dung soạn sẵn ("Mai sẽ thấy").
  final String text;

  /// Mặc định Zalo (Figma S17).
  final ShareChannel channel;

  /// Đã mở được app nhắn tin → S17b / N10 (không phải "đã gửi").
  final bool opened;
  final bool sending;

  /// Không mở được app (câu cho Bác); vẫn ở S17.
  final String? error;

  ShareMessage copyWith({
    ShareChannel? channel,
    String? text,
    bool? opened,
    bool? sending,
    String? error,
  }) =>
      ShareMessage(
        recipient: recipient,
        text: text ?? this.text,
        channel: channel ?? this.channel,
        opened: opened ?? this.opened,
        sending: sending ?? this.sending,
        error: error,
      );
}

const _loadFailed = 'Chưa tải được người thân. Bác bấm "Thử lại" nhé.';

/// Tham số family: `personId`.
class ShareMessageViewModel extends Notifier<UiState<ShareMessage>> {
  ShareMessageViewModel(this.personId);

  final String personId;

  @override
  UiState<ShareMessage> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  /// Người nhận từ `FamilyRepository.all()`; không tìm thấy → Empty; lỗi → Error.
  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      final list = await ref.read(familyRepositoryProvider).all();
      if (!ref.mounted) return;
      final r = list.where((x) => x.id == personId).firstOrNull;
      // TODO bước 05: soạn nội dung theo quan hệ / việc hôm nay.
      state = r == null
          ? const UiEmpty()
          : UiData(ShareMessage(recipient: r, text: figmaSampleMessage));
    } catch (e) {
      if (!ref.mounted) return;
      state = UiError(e is AppException ? e.userMessage : _loadFailed);
    }
  }

  Future<void> retry() => load();

  void _update(ShareMessage Function(ShareMessage) change) {
    if (state case UiData(:final data)) state = UiData(change(data));
  }

  /// "Gửi bằng": Zalo / Tin nhắn SMS.
  void selectChannel(ShareChannel channel) =>
      _update((d) => d.copyWith(channel: channel));

  /// "Tiếp tục nhắn tin cho …": `openZalo` / `openSms`; mở được → `opened` (S17b /
  /// N10) + log `share { method, topic }` (không gửi nội dung / tên / số).
  /// Trả `true` khi đã mở app.
  Future<bool> send() async {
    // TODO bước 05
    return false;
  }

  /// "Gọi điện cho …" ở S17b: mở gọi ngay. `null` = đã mở, ngược lại câu lỗi.
  Future<String?> call() async {
    // TODO bước 05: contactLauncherServiceProvider.call(recipient.phone).
    return null;
  }
}

final shareMessageViewModelProvider = NotifierProvider.autoDispose
    .family<ShareMessageViewModel, UiState<ShareMessage>, String>(
        ShareMessageViewModel.new);
