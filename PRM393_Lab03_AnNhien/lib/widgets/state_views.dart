import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'icon_circle.dart';

/// Loading / Empty / Error dùng chung cho mọi màn tải dữ liệu (Figma ST-Loading `26:191`,
/// ST-Empty `15:39`, ST-Error `26:159`). Nội dung căn giữa, cuộn được khi chữ phóng to.
class _CenteredColumn extends StatelessWidget {
  const _CenteredColumn({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen, vertical: AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// ST-Loading: vòng xoay trong vòng tròn, câu đậm ("Đang lưu việc…") + câu phụ ("Không cần bấm gì thêm"). Không có nút.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Đang tải…', this.hint});
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: _CenteredColumn(children: [
        IconCircle(
          child: SizedBox.square(
            dimension: AppSizes.stateIcon,
            child: CircularProgressIndicator(
                strokeWidth: AppSizes.spinnerStrokeLarge,
                color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(message,
            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            hint!,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ]),
    );
  }
}

/// ST-Empty: icon, tiêu đề, mô tả, nút chính + nút phụ (tuỳ chọn).
/// Vd. "Hôm nay chưa có việc nào" · "Bắt đầu nhẹ nhàng với một việc nhỏ." · "Thêm việc đầu tiên" · "Dùng lịch mẫu".
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
  });
  final IconData icon;
  final String title;
  final String? message;
  final AppButton? action;
  final AppButton? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredColumn(children: [
      IconCircle(icon: icon),
      const SizedBox(height: AppSpacing.lg),
      Semantics(
          header: true,
          child: Text(title,
              style: theme.textTheme.titleLarge, textAlign: TextAlign.center)),
      if (message != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          message!,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
      if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
      if (secondaryAction != null) ...[
        const SizedBox(height: AppSpacing.betweenTargets),
        secondaryAction!
      ],
    ]);
  }
}

/// ST-Error: icon cảnh báo trên nền `errorContainer`, tiêu đề (tuỳ chọn), câu lỗi cho Bác, nút "Thử lại"
/// luôn có + nút phụ (vd. "Kiểm tra lại lịch", "Quay lại sửa"). Lỗi nói 3 điều (AppStyleGuide): chuyện gì,
/// dữ liệu có mất không ([detail]), làm gì tiếp. TalkBack đọc ngay nhờ `liveRegion`.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
    this.detail,
    this.retryLabel = 'Thử lại',
    this.extraActions = const [],
  });
  final String message;
  final VoidCallback onRetry;
  final String? title;
  final String? detail;
  final String retryLabel;
  final List<AppButton> extraActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: _CenteredColumn(children: [
        const IconCircle(icon: AppIcons.alert, danger: true),
        const SizedBox(height: AppSpacing.lg),
        if (title != null) ...[
          Semantics(
              header: true,
              child: Text(title!,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center)),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(message,
            style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            detail!,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: retryLabel, icon: AppIcons.retry, onPressed: onRetry),
        for (final a in extraActions) ...[
          const SizedBox(height: AppSpacing.betweenTargets),
          a
        ],
      ]),
    );
  }
}
