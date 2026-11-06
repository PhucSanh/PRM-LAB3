import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'form_parts.dart';

/// Giờ viết kiểu nói hằng ngày (AppStyleGuide SG-10): "6:00 sáng", "3:30 chiều", "8:00 tối".
/// Sáng 0–11 giờ, chiều 12–17 giờ, tối 18–23 giờ.
/// [wholeHourInWords] = true: giờ chẵn viết "3 giờ chiều" (thẻ việc S03 / G12); ô giờ giữ "3:00 chiều".
String formatTimeOfDay(TimeOfDay time, {bool wholeHourInWords = false}) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final part = _dayPart(time);
  if (wholeHourInWords && time.minute == 0) return '$hour giờ $part';
  return '$hour:${time.minute.toString().padLeft(2, '0')} $part';
}

/// Câu để TalkBack đọc (SG-41): "6 giờ sáng", "9 giờ 30 sáng" – không có dấu ":".
String speakTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute =
      time.minute == 0 ? '' : ' ${time.minute.toString().padLeft(2, '0')}';
  return '$hour giờ$minute ${_dayPart(time)}';
}

String _dayPart(TimeOfDay time) =>
    time.hour < 12 ? 'sáng' : (time.hour < 18 ? 'chiều' : 'tối');

/// Ô giờ (Figma S02 `1:103` "Bác thức dậy lúc", S06 `1:890` / ST-Validation `29:2` "Giờ làm"): là **nút**, không
/// phải ô gõ. Hiện "6:00 sáng" + "Đổi giờ ⌄"; bấm mở [showTimeWheel]. Chưa có giờ thì hiện [placeholder].
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.dialogTitle,
    this.dialogIcon = AppIcons.clock,
    this.errorText,
    this.placeholder = 'Chọn giờ',
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;

  /// Icon trước nhãn (S02: ⏰, S06: 🕘).
  final IconData? icon;

  /// Tiêu đề hộp chọn giờ: "Giờ làm" (DLG-TaskTime), "Giờ thức dậy" (DLG-WakeTime). Mặc định = [label].
  final String? dialogTitle;
  final IconData dialogIcon;

  /// Vd. C06: "Chọn giờ để nhắc mẹ đúng lúc".
  final String? errorText;
  final String placeholder;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimeWheel(context,
        initial: value, title: dialogTitle ?? label, icon: dialogIcon);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = errorText != null;
    final text = value == null ? placeholder : formatTimeOfDay(value!);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: FieldLabel(label, icon: icon)),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            button: true,
            label: '$label: $text',
            hint: 'Đổi giờ',
            excludeSemantics: true,
            onTap: () => _pick(context),
            child: Material(
              color: hasError ? scheme.errorContainer : scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
                side: BorderSide(
                    color: hasError ? scheme.error : scheme.outline,
                    width: AppSizes.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _pick(context),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: AppSizes.minTarget),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base, vertical: AppSpacing.md),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: double.infinity,
                        // Chữ phóng to không đủ chỗ thì "Đổi giờ" xuống dòng thay vì tràn.
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text(
                              text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: value == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(
                                child: Text('Đổi giờ',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: scheme.primary)),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Icon(AppIcons.chevronDown,
                                  size: AppSizes.icon, color: scheme.primary),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.error(errorText!),
          ],
        ]);
  }
}

/// Bộ chọn giờ dạng bánh xe, phút 00–59; chỉ áp dụng khi Bác bấm Lưu giờ.
Future<TimeOfDay?> showTimeWheel(
  BuildContext context, {
  TimeOfDay? initial,
  String title = 'Giờ làm',
  IconData icon = AppIcons.clock,
}) =>
    showDialog<TimeOfDay>(
        context: context,
        builder: (_) => TimeGridDialog(
            initial: initial ?? const TimeOfDay(hour: 8, minute: 0),
            title: title,
            icon: icon));

/// Giữ tên public để các màn dùng chung API; giao diện hiện là bánh xe giờ/phút.
class TimeGridDialog extends StatefulWidget {
  const TimeGridDialog(
      {super.key,
      required this.initial,
      required this.title,
      this.icon = AppIcons.clock});
  final TimeOfDay initial;
  final String title;
  final IconData icon;
  @override
  State<TimeGridDialog> createState() => _TimeGridDialogState();
}

class _TimeGridDialogState extends State<TimeGridDialog> {
  late TimeOfDay _value = widget.initial;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.screen),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.base),
              const Text('Vuốt lên hoặc xuống để chọn giờ và phút.',
                  textAlign: TextAlign.center),
              SizedBox(
                  height: AppSizes.timeWheelHeight * scale.clamp(1.0, 1.5),
                  child: CupertinoTheme(
                      data: CupertinoThemeData(
                          brightness: theme.brightness,
                          primaryColor: theme.colorScheme.primary,
                          textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle:
                                  theme.textTheme.titleMedium!)),
                      child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          itemExtent: AppSizes.minTarget * scale,
                          initialDateTime:
                              DateTime(2026, 1, 1, _value.hour, _value.minute),
                          onDateTimeChanged: (date) => setState(
                              () => _value = TimeOfDay.fromDateTime(date))))),
              Semantics(
                  liveRegion: true,
                  child: Text('Bác chọn: ${formatTimeOfDay(_value)}',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center)),
              const SizedBox(height: AppSpacing.base),
              AppButton(
                  label: 'Lưu giờ',
                  icon: AppIcons.save,
                  onPressed: () => Navigator.of(context).pop(_value)),
              const SizedBox(height: AppSpacing.betweenTargets),
              AppButton(
                  label: 'Hủy',
                  icon: AppIcons.x,
                  kind: AppButtonKind.secondary,
                  onPressed: () => Navigator.of(context).pop()),
            ])));
  }
}
