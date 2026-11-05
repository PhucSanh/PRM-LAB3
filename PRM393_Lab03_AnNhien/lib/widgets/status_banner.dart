import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Banner báo kết quả nằm trong màn, **không tự tắt** (Figma S09b `26:7` "Đã thêm Cháu Bin",
/// N21 `52:48` "Con gái Mai đã được xóa" + "Hoàn tác"). F11 bước 02 đề xuất, F0 – Sanh duyệt.
///
/// Nền `primaryContainer`, viền `primary` 2 dp, bo 16; icon 32 + tiêu đề đậm + câu phụ;
/// [action] (tuỳ chọn) là nút đặt dưới chữ, vd. "Hoàn tác". TalkBack đọc ngay (`liveRegion`).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final AppButton? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onPrimaryContainer;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: scheme.primary, width: AppSizes.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExcludeSemantics(
                  child: Icon(icon, size: AppSizes.icon, color: fg)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              theme.textTheme.titleMedium?.copyWith(color: fg)),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(message!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: fg)),
                      ],
                    ]),
              ),
            ]),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.base),
              action!,
            ],
          ]),
        ),
      ),
    );
  }
}
