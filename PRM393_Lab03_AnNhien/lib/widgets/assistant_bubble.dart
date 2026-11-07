import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/device_access_view_model.dart';

/// Bong bóng trợ lý AI nổi ở góc dưới bên phải, đi theo các tab của Bác.
/// Bấm vào mở màn "Nói để thêm việc". Ẩn khi Remote Config tắt giọng nói.
class AssistantBubble extends ConsumerWidget {
  const AssistantBubble({super.key});

  static const double size = 72;

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
      label: 'Nói để thêm việc',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Nói để thêm việc',
        child: SizedBox.square(
          dimension: size,
          child: FloatingActionButton(
            key: const Key('assistant-bubble'),
            heroTag: null,
            onPressed: () => context.push('/today/voice'),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 4,
            shape: const CircleBorder(),
            child: Stack(clipBehavior: Clip.none, children: [
              const Icon(AppIcons.mic, size: AppSizes.icon + 8),
              Positioned(
                right: -AppSpacing.sm,
                top: -AppSpacing.sm,
                child: Icon(Icons.auto_awesome_rounded,
                    size: AppSizes.icon * .7, color: colors.onPrimary),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Câu trả lời của cháu (trợ lý) trong khung nói, dạng bong bóng chat.
/// TalkBack tự đọc khi câu đổi.
class AssistantReply extends StatelessWidget {
  const AssistantReply({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      label: 'Cháu trả lời: $text',
      excludeSemantics: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
            radius: AppSizes.icon,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: const Icon(Icons.auto_awesome_rounded)),
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
