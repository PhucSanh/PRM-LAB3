import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/guided_activity.dart';
import '../../models/task_item.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/calm_feature_providers.dart';
import '../../viewmodels/task_form_view_model.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/velora_parts.dart';
import '../../widgets/task_detail_parts.dart';
import '../../widgets/state_views.dart';

class GuidedActivityScreen extends ConsumerWidget {
  const GuidedActivityScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = guidedActivityById(id), text = Theme.of(context).textTheme;
    if (activity == null) {
      return Scaffold(
          appBar: AppBackBar.adaptive(context),
          body: const EmptyView(
              icon: Icons.spa_outlined,
              title: 'Hoạt động này không còn trong thư viện.'));
    }
    return Scaffold(
        body: SafeArea(
            child: VeloraDetailBody(
      hero: TaskHeroArt(
          habitKey: activity.habitKey,
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/activities')),
      footer: AppButton(
          label: 'Thêm vào lịch',
          icon: Icons.add_alarm_rounded,
          onPressed: () {
            ref.read(taskFormViewModelProvider.notifier).startCreate(
                day: ref.read(calendarDateProvider),
                activity: activity.habitKey,
                title: activity.title,
                durationMinutes: activity.minutes,
                repeat: RepeatRule.once);
            context.push('/today/add/time');
          }),
      children: [
        Text(activity.title, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('${activity.minutes} phút · Theo nhịp của Bác',
            style: text.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        Text('Bác có thể bắt đầu như sau', style: text.titleLarge),
        for (final (index, step) in activity.steps.indexed) ...[
          const SizedBox(height: AppSpacing.md),
          Text('${index + 1}. $step', style: text.bodyLarge),
        ],
        if (activity.habitKey == 'family') ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
              label: 'Chọn người thân để gọi',
              icon: Icons.call_outlined,
              kind: AppButtonKind.secondary,
              onPressed: () => context.go('/family')),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Text(
            'Bác có thể thay đổi thời lượng, ngày và giờ trước khi lưu.'),
      ],
    )));
  }
}
