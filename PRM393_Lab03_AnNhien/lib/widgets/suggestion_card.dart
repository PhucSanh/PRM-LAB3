import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Thẻ G12 "Mai gửi Bác 2 việc" ở đầu S03 (Figma `71:209`): ô icon thư, tiêu đề, tên các việc gợi ý,
/// "Chưa thêm vào lịch. Bác tự chọn.", nút viền "Xem gợi ý" (→ G03). Lịch **không** đổi cho tới khi Bác nhận.
/// [onDismiss] (tuỳ chọn) thêm nút chữ "Bỏ qua gợi ý"; ViewModel phải hiện `showUndoSnackbar` (G09).
///
/// Cách Khang đặt thẻ lên S03 (F3 không phải sửa ViewModel của mình; dữ liệu do F12 – `SuggestionInboxViewModel`):
/// ```dart
/// // lib/screens/today/today_screen.dart › _TodayList.build, phần tử đầu tiên của ListView:
/// Consumer(builder: (context, ref, _) {
///   final inbox = ref.watch(suggestionInboxViewModelProvider); // F12 – Sanh
///   return switch (inbox) {
///     UiData(:final data) when data.pendingCard != null => Padding(
///         padding: const EdgeInsets.only(bottom: AppSpacing.base),
///         child: SuggestionCard(
///           fromName: data.pendingCard!.fromName,
///           itemCount: data.pendingCard!.items.length,
///           previewTitles: [for (final i in data.pendingCard!.items) i.title],
///           onOpen: () => context.push('/today/suggestions/${data.pendingCard!.id}'),
///           onDismiss: () => ref.read(suggestionInboxViewModelProvider.notifier).dismiss(data.pendingCard!.id),
///         ),
///       ),
///     _ => const SizedBox.shrink(), // Đang tải / lỗi / không có gợi ý: không chiếm chỗ trên S03.
///   };
/// }),
/// ```
/// Tên provider / trường dữ liệu trên là dự kiến của F12; chốt khi F12 merge.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.fromName,
    required this.itemCount,
    this.previewTitles = const [],
    required this.onOpen,
    this.onDismiss,
  });

  /// Tên người gửi giữ nguyên (SG-05), vd. "Mai".
  final String fromName;
  final int itemCount;

  /// Tên việc gợi ý, hiện tối đa [maxPreview] dòng.
  final List<String> previewTitles;
  final VoidCallback onOpen;
  final VoidCallback? onDismiss;

  static const maxPreview = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = '$fromName gửi Bác $itemCount việc';
    final shown = previewTitles.take(maxPreview).toList();
    final hidden = previewTitles.length - shown.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(
            header: true,
            child: Row(children: [
              ExcludeSemantics(
                child: Container(
                  width: AppSizes.habitIcon,
                  height: AppSizes.habitIcon,
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.mdAll),
                  child: Icon(AppIcons.suggestion, size: AppSizes.icon, color: scheme.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ]),
          ),
          if (shown.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final t in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('• $t', style: theme.textTheme.bodyLarge),
              ),
            if (hidden > 0)
              Text(
                'và $hidden việc khác',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chưa thêm vào lịch. Bác tự chọn.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.base),
          AppButton(label: 'Xem gợi ý', icon: AppIcons.view, kind: AppButtonKind.secondary, onPressed: onOpen),
          if (onDismiss != null) ...[
            const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(label: 'Bỏ qua gợi ý', icon: AppIcons.x, kind: AppButtonKind.text, onPressed: onDismiss),
          ],
        ]),
      ),
    );
  }
}
