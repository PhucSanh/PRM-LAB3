import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'habit_widgets.dart';
import 'time_field.dart';

/// Chữ của từng trạng thái việc (DESIGN.md › `status-done` / `status-todo`, Từ điển icon › Trạng thái).
extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
        TaskStatus.pending => 'Chưa làm',
        TaskStatus.done => 'Đã xong',
        TaskStatus.skipped => 'Bỏ qua',
        TaskStatus.postponed => 'Đã dời',
      };
}

/// Chip trạng thái việc: icon + chữ, màu chỉ là tín hiệu phụ (R-STA-01). Figma S03 `1:270`, S03-skip `10:193`,
/// S03-later `8:189`: "✓ Đã xong" nền `primary` chữ trắng · "○ Chưa làm" nền vàng nhạt viền vàng đậm ·
/// "⊖ Bỏ qua" / "↷ Đã dời" nền trắng viền `outline`.
class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Màu "Chưa làm" chỉ có trong AppColors (DESIGN.md warning-*), chưa có vai trò tương ứng trong ColorScheme.
    final (IconData icon, Color bg, Color fg, Color iconColor, Color? border) = switch (status) {
      TaskStatus.done => (AppIcons.checkCircle, scheme.primary, scheme.onPrimary, scheme.onPrimary, null),
      TaskStatus.pending => (
          AppIcons.radioOff,
          AppColors.warningContainer,
          AppColors.onWarningContainer,
          AppColors.warningStrong,
          AppColors.warningStrong,
        ),
      TaskStatus.skipped => (
          AppIcons.statusSkipped,
          scheme.surface,
          scheme.onSurfaceVariant,
          scheme.onSurfaceVariant,
          scheme.outline,
        ),
      TaskStatus.postponed => (
          AppIcons.statusPostponed,
          scheme.surface,
          scheme.onSurface,
          scheme.onSurface,
          scheme.outline,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: border == null ? null : Border.all(color: border, width: AppSizes.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: AppSizes.iconInChip, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child:
              Text(status.label, style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

/// Một dòng việc (DESIGN.md › `card-task`; Figma S03 `1:270`, S03b `12:2`, S03-skip `10:193`, S03-later `8:189`):
/// vạch màu thói quen · ô icon · giờ · tên việc · chip trạng thái · dòng phụ ([note], mặc định tên thói quen).
/// Cả thẻ bấm được (→ S04), cao ≥ 72. TalkBack đọc "6 giờ sáng, Đi bộ, đã xong".
///
/// Từ `TaskItem`: `TaskRow(time: TimeOfDay(hour: t.hour, minute: t.minute), title: t.title,
/// habitKey: t.habitKey, status: t.status, onTap: …)`.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.time,
    required this.title,
    required this.habitKey,
    this.status = TaskStatus.pending,
    this.note,
    this.onTap,
    this.showChevron = false,
  });

  final TimeOfDay time;
  final String title;
  final String habitKey;
  final TaskStatus status;

  /// Dòng phụ dưới chip, vd. "Hôm nay trời mưa" (lý do bỏ qua), "Mỗi ngày" (S16). Mặc định tên thói quen.
  final String? note;
  final VoidCallback? onTap;

  /// Mũi tên › cuối thẻ (S16 "Việc của Bác"); S03 không có.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subline = note ?? HabitStyle.nameOf(habitKey);

    return Semantics(
      container: true,
      button: onTap != null,
      label: '${speakTimeOfDay(time)}, $title, ${status.label.toLowerCase()}. $subline',
      excludeSemantics: true,
      onTap: onTap,
      child: HabitAccentCard(
        habitKey: habitKey,
        onTap: onTap,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HabitBadge(habitKey: habitKey),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                formatTimeOfDay(time, wholeHourInWords: true),
                style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              TaskStatusChip(status: status),
              const SizedBox(height: AppSpacing.xs),
              Text(subline, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(AppIcons.chevronRight, size: AppSizes.icon, color: scheme.onSurfaceVariant),
          ],
        ]),
      ),
    );
  }
}

/// Thẻ "Việc tiếp theo" ở đầu S03 (Figma G12 `71:209`, S03b `12:2`, S03-skip `10:193`, S03-later `8:189`):
/// "🔔 Việc tiếp theo · 9:30 sáng", ô icon + tên việc + "20 phút · Vận động tự nhiên", rồi các nút:
/// "Đã xong" (`AppButton` primary) · "Dời lại" (viền) · "Hôm nay bỏ qua" (chữ). Nút nào không truyền callback thì ẩn.
/// Chạm phần trên (tên việc) → [onTap] mở S04.
class NextTaskCard extends StatelessWidget {
  const NextTaskCard({
    super.key,
    required this.time,
    required this.title,
    required this.habitKey,
    required this.onDone,
    this.onLater,
    this.onSkip,
    this.onTap,
    this.durationMinutes,
  });

  final TimeOfDay time;
  final String title;
  final String habitKey;
  final VoidCallback onDone;
  final VoidCallback? onLater;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  /// "20 phút" trước tên thói quen ở dòng phụ.
  final int? durationMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final habitName = HabitStyle.nameOf(habitKey);
    final detail = durationMinutes == null ? habitName : '$durationMinutes phút · $habitName';
    final timeText = formatTimeOfDay(time, wholeHourInWords: true);

    final info = Semantics(
      container: true,
      button: onTap != null,
      label: 'Việc tiếp theo, ${speakTimeOfDay(time)}, $title. $detail',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(AppIcons.bell, size: AppSizes.icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Việc tiếp theo · $timeText',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.base),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              HabitBadge(habitKey: habitKey),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(detail, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );

    final buttons = [
      AppButton(label: 'Đã xong', icon: AppIcons.checkCircle, onPressed: onDone),
      if (onLater != null)
        AppButton(label: 'Dời lại', icon: AppIcons.later, kind: AppButtonKind.secondary, onPressed: onLater),
      if (onSkip != null)
        AppButton(label: 'Hôm nay bỏ qua', icon: AppIcons.skipToday, kind: AppButtonKind.text, onPressed: onSkip),
    ];

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(color: scheme.primary, width: AppSizes.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          info,
          for (final button in buttons) ...[
            const SizedBox(height: AppSpacing.betweenTargets),
            button,
          ],
        ]),
      ),
    );
  }
}
