import 'package:flutter/material.dart';
import '../models/voice_task_draft.dart';
import '../theme/app_spacing.dart';
import 'assistant_mascot.dart';

/// A proposal, never a saved task: the caller provides explicit confirmation.
class VoiceTaskReview extends StatelessWidget {
  const VoiceTaskReview({super.key, required this.draft});
  final VoiceTaskDraft draft;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const AssistantMascot(size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text('Lịch đề xuất cho Bác',
                  style: theme.textTheme.labelLarge)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text(draft.title ?? 'Chưa rõ tên việc',
            style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        _detail(
            context, Icons.calendar_today_outlined, 'Ngày: ${draft.dateLabel}'),
        _detail(context, Icons.schedule_rounded, 'Giờ: ${draft.timeLabel}'),
        _detail(context, Icons.timelapse_rounded,
            'Làm trong: ${draft.durationLabel}'),
        _detail(context, Icons.repeat_rounded, 'Lặp: ${draft.repeatLabel}'),
        const SizedBox(height: AppSpacing.md),
        Text('Bản nháp · Chỉ lưu khi Bác xác nhận.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant)),
      ]),
    );
  }

  Widget _detail(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}
