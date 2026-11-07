import 'package:flutter/material.dart';

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

/// Mở hộp chọn giờ DLG-TaskTime `29:256` / DLG-WakeTime `31:2`: lưới nút chạm (không phải vuốt) – giờ 1–12,
/// Sáng / Chiều, phút 00 / 15 / 30 / 45, dòng "Bác chọn: 8:00 sáng", nút "Lưu giờ" + "Hủy".
/// Trả giờ đã chọn, hoặc `null` khi bấm Hủy / chạm ra ngoài / Back. Mặc định mở ở 8:00 sáng.
///
/// Tên hàm giữ theo architecture.md mục 13; bố cục theo Figma (DT-12).
Future<TimeOfDay?> showTimeWheel(
  BuildContext context, {
  TimeOfDay? initial,
  String title = 'Giờ làm',
  IconData icon = AppIcons.clock,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => TimeGridDialog(
        initial: initial ?? const TimeOfDay(hour: 8, minute: 0),
        title: title,
        icon: icon),
  );
}

/// Nội dung của [showTimeWheel]. Nút "Lưu giờ" / "Hủy" luôn ở đáy, phần lưới cuộn khi chữ phóng to.
class TimeGridDialog extends StatefulWidget {
  const TimeGridDialog(
      {super.key,
      required this.initial,
      required this.title,
      this.icon = AppIcons.clock});

  final TimeOfDay initial;
  final String title;
  final IconData icon;

  /// Các mốc phút, cách nhau 5 phút (00, 05, … 55): 12 ô, lưới 4 cột như
  /// phần Giờ. Figma ban đầu chỉ có 00/15/30/45, quá thưa khi đặt lịch.
  static const minuteSteps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  @override
  State<TimeGridDialog> createState() => _TimeGridDialogState();
}

class _TimeGridDialogState extends State<TimeGridDialog> {
  late int _hour = widget.initial.hourOfPeriod == 0
      ? 12
      : widget.initial.hourOfPeriod; // 1–12
  late int _minute = widget.initial.minute;
  late bool _afternoon = widget.initial.period == DayPeriod.pm;

  /// Giờ đã lưu có phút lẻ (vd. 9:40) thì vẫn hiện mốc đó để Bác thấy và giữ được.
  late final List<int> _minutes =
      {...TimeGridDialog.minuteSteps, widget.initial.minute}.toList()..sort();

  final _scroll = ScrollController();

  TimeOfDay get _value =>
      TimeOfDay(hour: _hour % 12 + (_afternoon ? 12 : 0), minute: _minute);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sectionStyle = theme.textTheme.titleSmall;

    // Lưới cao hơn màn 800 dp ở cỡ chữ lớn: phần lưới cuộn (thanh cuộn luôn hiện), còn "Bác chọn: …"
    // và 2 nút ghim ở đáy. Sáng / Chiều đứng ngay dưới giờ, phút (thường để 00) xuống cuối (DT-12).
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen, vertical: AppSpacing.base),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExcludeSemantics(
                                child: Icon(widget.icon,
                                    size: AppSizes.icon,
                                    color: scheme.primary)),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                                child: Text(widget.title,
                                    style: theme.dialogTheme.titleTextStyle)),
                          ]),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Chạm vào số Bác muốn',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Giờ', style: sectionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _CellGrid(columns: 4, children: [
                      for (var h = 1; h <= 12; h++)
                        _TimeCell(
                          text: '$h',
                          semanticLabel: 'Giờ, $h',
                          selected: _hour == h,
                          onTap: () => setState(() => _hour = h),
                        ),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    _CellGrid(columns: 2, children: [
                      _TimeCell(
                        text: 'Sáng',
                        semanticLabel: 'Buổi sáng',
                        selected: !_afternoon,
                        small: true,
                        onTap: () => setState(() => _afternoon = false),
                      ),
                      _TimeCell(
                        text: 'Chiều',
                        semanticLabel: 'Buổi chiều',
                        selected: _afternoon,
                        small: true,
                        onTap: () => setState(() => _afternoon = true),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Text('Phút', style: sectionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _CellGrid(columns: 4, children: [
                      for (final m in _minutes)
                        _TimeCell(
                          text: m.toString().padLeft(2, '0'),
                          semanticLabel:
                              'Phút, ${m.toString().padLeft(2, '0')}',
                          selected: _minute == m,
                          onTap: () => setState(() => _minute = m),
                        ),
                    ]),
                  ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Semantics(
              liveRegion: true,
              child: Text(
                'Bác chọn: ${formatTimeOfDay(_value)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: scheme.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Lưu giờ',
                icon: AppIcons.save,
                onPressed: () => Navigator.of(context).pop(_value)),
            const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(
              label: 'Hủy',
              icon: AppIcons.x,
              kind: AppButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Xếp ô thành hàng [columns] cột đều nhau, cách nhau 8 (Figma: ô 62 × 48, khe 8).
class _CellGrid extends StatelessWidget {
  const _CellGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(
          text: columns == 2 ? 'Chiều' : '00',
          style: columns == 2
              ? theme.textTheme.titleSmall
              : theme.textTheme.titleMedium),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final minWidth = (painter.width + 2 * AppSpacing.md)
        .clamp(AppSizes.minTarget, double.infinity);
    painter.dispose();
    return LayoutBuilder(builder: (context, constraints) {
      final effectiveColumns =
          ((constraints.maxWidth + AppSpacing.sm) / (minWidth + AppSpacing.sm))
              .floor()
              .clamp(1, columns);
      final rows = <Widget>[];
      for (var start = 0; start < children.length; start += effectiveColumns) {
        if (start > 0) rows.add(const SizedBox(height: AppSpacing.sm));
        rows.add(Row(children: [
          for (var i = start; i < start + effectiveColumns; i++) ...[
            if (i > start) const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: i < children.length
                    ? children[i]
                    : const SizedBox.shrink()),
          ],
        ]));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    });
  }
}

/// Một ô chọn trong hộp chọn giờ. Đang chọn: nền `primaryContainer`, viền `primary` dày gấp đôi.
class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.text,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.small = false,
  });

  final String text;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  /// Chữ 22 (Sáng / Chiều) thay vì 24 (số).
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style =
        small ? theme.textTheme.titleSmall : theme.textTheme.titleMedium;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonAll,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 * AppSizes.border : AppSizes.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.md),
              child: Center(
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: style?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface))),
            ),
          ),
        ),
      ),
    );
  }
}
