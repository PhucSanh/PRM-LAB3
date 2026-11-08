import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'icon_circle.dart';

/// Một lựa chọn trong [ConfirmDialog]. Bấm → đóng hộp thoại và trả [value].
class ConfirmOption<T> {
  const ConfirmOption(
      {required this.label,
      required this.icon,
      required this.value,
      this.kind = AppButtonKind.secondary});

  /// Nhãn nhắc lại đúng việc (AppStyleGuide SG-16, SG-18): "Đúng, đã xong", không "Có".
  final String label;
  final IconData icon;
  final T value;
  final AppButtonKind kind;
}

/// Một dòng thông tin dưới câu hỏi: icon (hoặc [leading]) + chữ. Vd. "🕘 9:30 sáng", "ⓘ Lịch sử được giữ lại".
class ConfirmDetail extends StatelessWidget {
  const ConfirmDetail({super.key, this.icon, this.leading, required this.text})
      : assert(icon != null || leading != null);

  final IconData? icon;

  /// Thay cho [icon], vd. ô màu thói quen ở DLG-Done.
  final Widget? leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(children: [
        leading ??
            Icon(icon, size: AppSizes.icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

/// Hộp hỏi lại dùng chung: DLG-Done · DLG-Later · DLG-Skip · DLG-Delete · N13 · N14 (Figma `29:125`,
/// `29:156`, `29:211`, `29:98`, `43:195`, `43:239`). Icon trong vòng tròn, tiêu đề, câu mô tả,
/// [details], rồi các nút xếp dọc full-width theo đúng thứ tự [options].
///
/// Thứ tự nút: lựa chọn huỷ ("Chưa, để sau", "Không dời nữa", "Giữ nguyên") đặt **cuối**. Riêng khi
/// hậu quả khó lấy lại (xoá, bỏ thay đổi), nút an toàn là nút chính và đứng **trên** (SG-19, Figma
/// DLG-Delete / N14).
class ConfirmDialog<T> extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    this.message,
    this.details = const [],
    this.iconColor,
    this.iconBackground,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> details;
  final List<ConfirmOption<T>> options;
  final Color? iconColor;
  final Color? iconBackground;

  /// Icon đỏ trên nền `errorContainer` (DLG-Delete).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen, vertical: AppSpacing.lg),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconCircle(
              icon: icon,
              color: iconColor,
              background: iconBackground,
              danger: danger),
          const SizedBox(height: AppSpacing.base),
          Semantics(
            header: true,
            child: Text(title,
                style: theme.dialogTheme.titleTextStyle,
                textAlign: TextAlign.center),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          ...details,
          const SizedBox(height: AppSpacing.lg),
          for (final (i, option) in options.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(
              label: option.label,
              icon: option.icon,
              kind: option.kind,
              onPressed: () => Navigator.of(context).pop(option.value),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Mở [ConfirmDialog]. Trả giá trị của nút đã bấm, hoặc `null` khi chạm ra ngoài / bấm Back hệ thống.
Future<T?> showConfirmDialog<T>(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<ConfirmOption<T>> options,
  String? message,
  List<Widget> details = const [],
  Color? iconColor,
  Color? iconBackground,
  bool danger = false,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => ConfirmDialog<T>(
      icon: icon,
      title: title,
      message: message,
      details: details,
      options: options,
      iconColor: iconColor,
      iconBackground: iconBackground,
      danger: danger,
    ),
  );
}
