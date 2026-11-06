import 'package:flutter/material.dart';
import '../models/voice_task_draft.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'section_card.dart';

class VoiceTaskReview extends StatelessWidget {
  const VoiceTaskReview({super.key, required this.draft});
  final VoiceTaskDraft draft;
  @override
  Widget build(BuildContext context) => SectionCard(
        icon: AppIcons.tabWeek,
        title: 'Lịch Bác vừa nói',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(draft.title ?? 'Chưa rõ tên việc',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text('Ngày: ${draft.dateLabel}'),
          const SizedBox(height: AppSpacing.sm),
          Text('Giờ: ${draft.timeLabel}'),
          const SizedBox(height: AppSpacing.sm),
          Text('Lặp: ${draft.repeatLabel}'),
          const SizedBox(height: AppSpacing.md),
          const Text('Đây là bản nháp. Bác kiểm tra lại rồi mới lưu nhé.'),
        ]),
      );
}
