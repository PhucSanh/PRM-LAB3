import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/first_task_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import 'onboarding_layout.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/icon_circle.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/time_field.dart';

/// N04 Chọn việc đầu tiên (`38:2`) → N05 Xem lại (`38:108`) → N18 Đã lưu
/// (`47:170`) – chủ: Hương (F2). Cùng route `/setup/first-task`, vẽ theo
/// `FirstTaskData.step`. Loading / Empty / Error (+ Thử lại) khi nạp gợi ý.
/// Xong (N18 hoặc "Để sau" ở N04) → `/today` (N19 là state S03 của Khang).
class FirstTaskScreen extends ConsumerWidget {
  const FirstTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(firstTaskViewModelProvider);
    final vm = ref.read(firstTaskViewModelProvider.notifier);

    Future<void> finishTo(String route) async {
      if (await vm.finish() && context.mounted) context.go(route);
    }

    Future<void> save() async {
      await vm.save();
    }

    final step = switch (state) {
      UiData(:final data) => data.step,
      _ => FirstTaskStep.pick,
    };
    return Scaffold(
      // N18 là màn kết quả (đã lưu), không có Quay lại – theo Figma `47:170`.
      appBar: step == FirstTaskStep.saved
          ? null
          : AppBackBar(
              onBack: step == FirstTaskStep.time
                  ? vm.backToPick
                  : () => context.go('/setup/notifications'),
            ),
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải việc gợi ý…'),
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          UiEmpty() => EmptyView(
              icon: AppIcons.list,
              title: 'Chưa có việc gợi ý',
              message: 'Bác có thể thêm việc sau ở Hôm nay.',
              action: AppButton(
                label: 'Về Hôm nay',
                icon: AppIcons.arrowRight,
                onPressed: () => finishTo('/today'),
              ),
            ),
          UiData(:final data) => switch (data.step) {
              FirstTaskStep.pick => _Pick(
                  data: data,
                  onPick: vm.pick,
                  onNext: vm.confirmPick,
                  onLater: () => finishTo('/today'),
                ),
              FirstTaskStep.time =>
                _Review(data: data, onTime: vm.setTime, onSave: save),
              FirstTaskStep.saved => _Saved(
                  data: data,
                  onSchedule: () => finishTo('/today'),
                  onAddMore: () => finishTo('/today/add'),
                ),
            },
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineMedium)),
      const SizedBox(height: AppSpacing.xs),
      Text(subtitle,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

/// Dòng icon + nhãn nhỏ + giá trị đậm (chỉ xem).
class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.label, this.value);
  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: label == null ? value : '$label: $value',
      excludeSemantics: true,
      child: Row(children: [
        Icon(icon, size: AppSizes.icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (label != null)
              Text(label!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.titleMedium),
          ]),
        ),
      ]),
    );
  }
}

/// Lỗi lưu / hoàn tất: câu lỗi đặt ngay trên nút.
List<Widget> _errorLine(FirstTaskData data) =>
    [if (data.saveError != null) FieldMessage.error(data.saveError!)];

/// N04 – chọn một việc (một thói quen).
class _Pick extends StatelessWidget {
  const _Pick({
    required this.data,
    required this.onPick,
    required this.onNext,
    required this.onLater,
  });

  final FirstTaskData data;
  final ValueChanged<String> onPick;
  final VoidCallback onNext;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      // Các thẻ thói quen bấm được kề nhau: cách nhau ≥ 20 dp (rule.md R-TAP-03).
      gap: AppSpacing.betweenTargets,
      body: [
        const _Header('Bác muốn làm gì?',
            'Chọn một việc nhỏ để bắt đầu ngày mới nhẹ nhàng.'),
        for (final habit in data.habits)
          HabitTile(
            habitKey: habit.key,
            name: habit.name,
            description: habit.description,
            selected: habit.key == data.habitKey,
            onTap: () => onPick(habit.key),
          ),
        const FieldMessage.hint(
            'Bác cứ chọn thử, bước tiếp theo Bác mới bấm lưu vào lịch nhé.'),
      ],
      footer: [
        ..._errorLine(data),
        AppButton(
          label: 'Tiếp tục',
          icon: AppIcons.arrowRight,
          onPressed: data.saving ? null : onNext,
        ),
        AppButton(
          label: 'Để sau',
          icon: AppIcons.later,
          kind: AppButtonKind.text,
          busy: data.saving,
          onPressed: onLater,
        ),
      ],
    );
  }
}

/// N05 – xem lại việc đã chọn, đổi giờ, lưu.
class _Review extends StatelessWidget {
  const _Review(
      {required this.data, required this.onTime, required this.onSave});

  final FirstTaskData data;
  final ValueChanged<TimeOfDay> onTime;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = data.saveError != null;
    return OnboardingLayout(
      body: [
        const _Header(
            'Xem lại việc đầu tiên', 'Bác xem lại một lần trước khi lưu nhé.'),
        // Tên việc = tên thói quen nên dòng phụ ghi nhịp lặp thay vì lặp lại tên.
        TaskRow(
            time: data.time,
            title: data.title,
            habitKey: data.habitKey!,
            note: 'Mỗi ngày'),
        Text('Thời gian và lặp lại',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        TimeField(
          label: 'Giờ nhắc',
          icon: AppIcons.clock,
          value: data.time,
          dialogTitle: 'Bác muốn làm việc này lúc mấy giờ?',
          onChanged: onTime,
        ),
        const _InfoLine(Icons.event_outlined, 'Ngày bắt đầu', 'Hôm nay'),
        const _InfoLine(AppIcons.repeat, 'Nhịp nhắc', 'Mỗi ngày'),
        const FieldMessage.hint('Bác bấm "Lưu việc" để thêm vào lịch.'),
      ],
      footer: [
        ..._errorLine(data),
        AppButton(
          label: failed ? 'Thử lại' : 'Lưu việc',
          icon: failed ? AppIcons.retry : AppIcons.save,
          busy: data.saving,
          onPressed: onSave,
        ),
      ],
    );
  }
}

/// N18 – đã lưu, tóm tắt việc, về lịch.
class _Saved extends StatelessWidget {
  const _Saved({
    required this.data,
    required this.onSchedule,
    required this.onAddMore,
  });

  final FirstTaskData data;
  final VoidCallback onSchedule;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return OnboardingLayout(
      body: [
        Center(
          child: IconCircle(
            icon: AppIcons.save,
            color: scheme.onPrimary,
            background: scheme.primary,
          ),
        ),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text('Đã lưu việc đầu tiên!',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center),
        ),
        HabitAccentCard(
          habitKey: data.habitKey!,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              HabitBadge(habitKey: data.habitKey!),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(data.title, style: theme.textTheme.titleMedium)),
            ]),
            const SizedBox(height: AppSpacing.md),
            _InfoLine(AppIcons.clock, null, formatTimeOfDay(data.time)),
            const SizedBox(height: AppSpacing.sm),
            const _InfoLine(AppIcons.repeat, null, 'Mỗi ngày'),
          ]),
        ),
      ],
      footer: [
        ..._errorLine(data),
        AppButton(
          label: 'Xem lịch',
          icon: AppIcons.tabWeek,
          busy: data.saving,
          onPressed: onSchedule,
        ),
        AppButton(
          label: 'Thêm việc khác',
          icon: Icons.add,
          kind: AppButtonKind.secondary,
          onPressed: data.saving ? null : onAddMore,
        ),
      ],
    );
  }
}
