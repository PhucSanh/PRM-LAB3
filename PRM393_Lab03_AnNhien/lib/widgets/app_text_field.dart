import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import 'form_parts.dart';
import 'read_aloud_region.dart';

/// Ô nhập chữ (Figma S02 `1:103`, S02 Nhập lại tên `1:176`, S06e `12:193`, S12e `14:196`, ST-Validation `29:2`).
/// Nhãn đặt **trên** ô (không floating label); [hint] hiện **dưới** ô, tự thêm "Ví dụ: ".
/// Có [errorText]: nền `errorContainer`, viền `error`, dòng lỗi có icon (TalkBack tự đọc), gợi ý vẫn giữ bên dưới.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.errorText,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
    this.icon,
    this.autofillHints,
    this.textInputAction,
    this.inputFormatters,
    this.onSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final int minLines;
  final int? maxLines;
  final String label;

  /// Câu gợi ý, vd. "Đi bộ buổi sáng" → hiện "Ví dụ: Đi bộ buổi sáng".
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;

  /// Câu lỗi nói rõ thiếu gì, vd. "Bác chưa nhập tên việc." (AppStyleGuide › Lỗi nhập).
  final String? errorText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  /// Icon trước nhãn (S06: ✎ "Tên việc").
  final IconData? icon;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = errorText != null;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ReadAloudRegion(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
          ExcludeSemantics(child: FieldLabel(label, icon: icon)),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: MergeSemantics(
                child: Semantics(
              label: label,
              child: TextField(
                enabled: enabled,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                maxLength: maxLength,
                minLines: minLines,
                maxLines: maxLines,
                onChanged: onChanged,
                autofillHints: autofillHints,
                textInputAction: textInputAction ?? TextInputAction.done,
                inputFormatters: inputFormatters,
                onSubmitted: onSubmitted,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  fillColor: hasError
                      ? scheme.errorContainer
                      : scheme.secondaryContainer,
                  enabledBorder: border(
                      hasError ? scheme.error : scheme.outlineVariant,
                      hasError ? AppSizes.border : 1),
                  // Viền dày gấp đôi khi đang gõ: dấu hiệu tiêu điểm không chỉ bằng màu.
                  focusedBorder: border(
                      hasError ? scheme.error : scheme.primary,
                      2 * AppSizes.border),
                ),
              ),
            )),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.error(errorText!),
          ],
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.hint(exampleHint(hint!), showIcon: !hasError),
          ],
        ]));
  }
}
