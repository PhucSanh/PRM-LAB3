import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/device_access_view_model.dart';
import '../viewmodels/assistant_view_model.dart';
import 'app_button.dart';
import 'assistant_mascot.dart';
import 'form_parts.dart';

/// Bong bóng trợ lý AI nổi ở góc dưới bên phải, đi theo các tab của Bác.
/// Mở trợ lý chung: gọi người thân, xem/thêm/sửa/xoá lịch theo ý định.
class AssistantBubble extends ConsumerWidget {
  const AssistantBubble({super.key});

  static const double size = AppSizes.assistanceTarget;

  /// Khoảng trống cuối danh sách để nội dung cuối không nằm dưới bong bóng.
  static const double clearance = size + AppSpacing.lg;

  /// Các màn gốc của tab mà AppShell tự gắn bong bóng. `/calendar` có thanh
  /// "Thêm hoạt động" riêng nên tự gắn trong Scaffold của nó.
  static const shellPaths = {'/today', '/activities', '/family'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remote Config chưa sẵn sàng (Fake/test) thì dùng mặc định `true`
    // (remote-config-defaults.json) thay vì làm hỏng cả tab.
    var enabled = true;
    try {
      enabled = ref.watch(voiceInputEnabledProvider);
    } catch (_) {}
    if (!enabled) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Trợ lý An Nhiên',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Trợ lý An Nhiên',
        child: SizedBox.square(
          dimension: size,
          child: FloatingActionButton(
            key: const Key('assistant-bubble'),
            heroTag: null,
            onPressed: () =>
                ref.read(assistantLauncherProvider.notifier).open(),
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.primary,
            elevation: 0,
            highlightElevation: 0,
            shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
            child: const AssistantMascot(),
          ),
        ),
      ),
    );
  }
}

/// Câu trả lời của cháu (trợ lý) trong khung nói, dạng bong bóng chat.
/// Lần đầu câu hiện ra thì tự đọc to (một lần cho mỗi câu); dưới bong bóng có
/// nút "Nghe lại" / "Dừng đọc" để Bác nghe lại bao nhiêu lần cũng được.
class AssistantReply extends ConsumerStatefulWidget {
  const AssistantReply({super.key, required this.text, this.autoRead = true});
  final String text;

  /// `false`: không tự đọc, chỉ đọc khi Bác bấm nút.
  final bool autoRead;

  @override
  ConsumerState<AssistantReply> createState() => _AssistantReplyState();
}

class _AssistantReplyState extends ConsumerState<AssistantReply> {
  @override
  void initState() {
    super.initState();
    _autoRead();
  }

  @override
  void didUpdateWidget(AssistantReply oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _autoRead();
  }

  /// Đọc câu mới đúng một lần. ViewModel có thể đã tự đọc câu này rồi thì
  /// không đọc chồng lên.
  void _autoRead() {
    if (!widget.autoRead) return;
    final text = widget.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.text != text) return;
      final speech = ref.read(speechViewModelProvider);
      if (speech.speaking && speech.text == text) return;
      ref.read(speechViewModelProvider.notifier).read(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final speech = ref.watch(speechViewModelProvider);
    final speaking = speech.speaking && speech.text == text;
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _bubble(theme, colors, text),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsetsDirectional.only(
                start: AppSizes.icon * 2 + AppSpacing.md),
            child: AppButton(
                key: const Key('assistant-reply-read-aloud'),
                label: speaking ? 'Dừng đọc' : 'Nghe lại',
                icon: speaking ? AppIcons.stopReading : AppIcons.volume,
                kind: AppButtonKind.secondary,
                onPressed: () =>
                    ref.read(speechViewModelProvider.notifier).toggle(text)),
          ),
          if (speech.error != null && !speech.speaking) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.error(speech.error!),
          ],
        ]);
  }

  Widget _bubble(ThemeData theme, ColorScheme colors, String text) {
    return Semantics(
      liveRegion: true,
      label: 'Cháu trả lời: $text',
      excludeSemantics: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
            radius: AppSizes.icon,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.primary,
            child: const AssistantMascot(size: 36)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppRadius.xl),
                  bottomLeft: Radius.circular(AppRadius.xl),
                  bottomRight: Radius.circular(AppRadius.xl)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Text(text,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: colors.onSecondaryContainer)),
            ),
          ),
        ),
      ]),
    );
  }
}
