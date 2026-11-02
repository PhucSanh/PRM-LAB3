import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Nút "🔊 Đọc to" (Figma S04 `1:580`, S16 `1:1934`): nút viền cao ≥ 72.
/// Đang đọc (S14 `1:635`): dòng "🔊 Đang đọc…" (TalkBack tự đọc) + nút "⏹ Dừng đọc".
/// Widget không gọi TTS: [onPressed] báo cho ViewModel bật / dừng `SpeechService`, ViewModel trả lại [speaking].
class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({super.key, required this.onPressed, this.speaking = false});

  final VoidCallback? onPressed;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    if (!speaking) {
      return AppButton(label: 'Đọc to', icon: AppIcons.volume, kind: AppButtonKind.secondary, onPressed: onPressed);
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        liveRegion: true,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ExcludeSemantics(child: Icon(AppIcons.volume, size: AppSizes.icon, color: scheme.primary)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text('Đang đọc…', style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary)),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppButton(label: 'Dừng đọc', icon: AppIcons.stopReading, kind: AppButtonKind.secondary, onPressed: onPressed),
    ]);
  }
}
