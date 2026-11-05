import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/reminder_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/read_aloud_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/time_field.dart';

/// S14 – lời nhắc toàn màn hình. `preview` từ S10/N08 chỉ xem UI, không ghi dữ liệu.
class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key, required this.taskId, this.preview = false});

  final String taskId;
  final bool preview;

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  bool _speaking = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(reminderViewModelProvider.notifier)
        .load(widget.taskId, preview: widget.preview));
  }

  Future<void> _act(Future<bool> Function() action, String message) async {
    setState(() => _busy = true);
    final saved = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa thực hiện được. Bác thử lại nhé.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.go('/today?view=main');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderViewModelProvider);
    final vm = ref.read(reminderViewModelProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang mở lời nhắc…'),
          UiEmpty() => const EmptyView(
              icon: AppIcons.bell,
              title: 'Chưa có lời nhắc',
              message: 'Bác có thể xem lịch hôm nay.'),
          UiError(:final message) => ErrorView(
              message: message,
              onRetry: () => vm.load(widget.taskId, preview: widget.preview)),
          UiData(:final data) => _ReminderBody(
              data: data,
              speaking: _speaking,
              busy: _busy,
              onRead: () => setState(() => _speaking = !_speaking),
              onStart: () => _act(vm.start, 'Bác bắt đầu làm việc nhé.'),
              onSnooze: () => _act(vm.snooze,
                  'Đã nhắc lại sau ${data.snoozeMinutes} phút.'),
              onSkip: () => _act(vm.skip, 'Đã bỏ qua việc hôm nay.'),
            ),
        },
      ),
    );
  }
}

class _ReminderBody extends StatelessWidget {
  const _ReminderBody({
    required this.data,
    required this.speaking,
    required this.busy,
    required this.onRead,
    required this.onStart,
    required this.onSnooze,
    required this.onSkip,
  });

  final ReminderData data;
  final bool speaking;
  final bool busy;
  final VoidCallback onRead;
  final VoidCallback onStart;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = data.task;
    final time = formatTimeOfDay(
        TimeOfDay(hour: task.hour, minute: task.minute),
        wholeHourInWords: true);
    return Column(children: [
      const SizedBox(height: AppSpacing.lg),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(AppIcons.bell, color: Theme.of(context).colorScheme.primary,
            size: AppSizes.icon),
        const SizedBox(width: AppSpacing.sm),
        Text('Lời nhắc', style: theme.textTheme.titleLarge),
      ]),
      const SizedBox(height: AppSpacing.base),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          children: [
            SectionCard(
              child: Column(children: [
                HabitBadge(habitKey: task.habitKey, size: 64),
                const SizedBox(height: AppSpacing.md),
                Text(time, style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(task.title, style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(AppIcons.clock, size: AppSizes.icon),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Còn ${data.snoozeMinutes} phút nữa',
                      style: theme.textTheme.bodyLarge),
                ]),
              ]),
            ),
            const SizedBox(height: AppSpacing.base),
            ReadAloudButton(speaking: speaking, onPressed: onRead),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0,
              AppSpacing.screen, AppSpacing.screen),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppButton(label: 'Bắt đầu làm', icon: AppIcons.arrowRight,
                busy: busy, onPressed: onStart),
            const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(
              label: 'Nhắc lại sau ${data.snoozeMinutes} phút',
              icon: AppIcons.later,
              kind: AppButtonKind.secondary,
              busy: busy,
              onPressed: onSnooze,
            ),
            const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(
              label: 'Hôm nay bỏ qua',
              icon: AppIcons.skipToday,
              kind: AppButtonKind.tonal,
              busy: busy,
              onPressed: onSkip,
            ),
          ]),
        ),
      ),
    ]);
  }
}
