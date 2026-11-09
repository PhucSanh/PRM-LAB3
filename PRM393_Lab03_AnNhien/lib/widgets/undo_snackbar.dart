import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Snackbar "Hoàn tác" (Figma S03b `12:2`, S03-skip `10:193`, G09 `66:2`; handoff › Snackbar).
/// Hai tầng: câu chính đậm (+ câu phụ) ở trên, hàng nút "Đóng" · "Hoàn tác" căn phải ở dưới.
/// Tự tắt sau 6 giây; vẫn có thể đóng hoặc hoàn tác ngay.
///
/// Gọi từ View sau khi ViewModel báo hành động thành công, vd.
/// `showUndoSnackbar(context, title: 'Đã ghi: Đi bộ xong lúc 9:42 sáng.', onUndo: vm.undoDone)`.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showUndoSnackbar(
  BuildContext context, {
  required String title,
  String? subtitle,
  required VoidCallback onUndo,
  String undoLabel = 'Hoàn tác',
  String closeLabel = 'Đóng',
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      persist: false,
      duration: const Duration(seconds: 6),
      padding: const EdgeInsets.all(AppSpacing.base),
      content: _UndoSnackbarContent(
        title: title,
        subtitle: subtitle,
        undoLabel: undoLabel,
        closeLabel: closeLabel,
        onUndo: () {
          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
          onUndo();
        },
        onClose: () =>
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss),
      ),
    ),
  );
}

class _UndoSnackbarContent extends StatelessWidget {
  const _UndoSnackbarContent({
    required this.title,
    required this.subtitle,
    required this.undoLabel,
    required this.closeLabel,
    required this.onUndo,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final String undoLabel;
  final String closeLabel;
  final VoidCallback onUndo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Chữ sáng trên nền tối của snackbar (= màu `surface` trên nền `onSurface`).
    final fg = theme.colorScheme.surface;
    final base =
        theme.snackBarTheme.contentTextStyle ?? theme.textTheme.bodyMedium;
    return Semantics(
      liveRegion: true,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: base?.copyWith(color: fg, fontWeight: FontWeight.w700)),
            if (subtitle != null)
              Text(subtitle!, style: base?.copyWith(color: fg)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.betweenTargets,
              runSpacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: onClose,
                  style: TextButton.styleFrom(foregroundColor: fg),
                  icon: const Icon(AppIcons.x, size: AppSizes.iconInChip),
                  label: Text(closeLabel),
                ),
                OutlinedButton.icon(
                  onPressed: onUndo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fg,
                    backgroundColor: theme.snackBarTheme.backgroundColor ??
                        theme.colorScheme.onSurface,
                    side: BorderSide(color: fg, width: AppSizes.border),
                  ),
                  // undo-2 (DESIGN.md › Từ điển icon › Hoàn tác). TODO(F0): chuyển vào AppIcons.undo.
                  icon:
                      const Icon(Icons.undo_rounded, size: AppSizes.iconInChip),
                  label: Text(undoLabel),
                ),
              ],
            ),
          ]),
    );
  }
}
