import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_item.dart';
import '../../services/caregiver_schedule_service.dart';
import '../../services/providers.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/caregiver_form_view_model.dart';
import '../../viewmodels/caregiver_schedule_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/caregiver_parts.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/undo_snackbar.dart';

final caregiverDetailProvider = StreamProvider.autoDispose
    .family<List<ScheduleOccurrence>, ({String id, String day})>((ref, key) {
  final mom = ref.watch(pairedMomUidProvider);
  if (mom == null) return Stream.value([]);
  final day = DateTime.tryParse(key.day) ?? vietnamToday();
  return ref
      .watch(caregiverScheduleServiceProvider)
      .watch(mom, day.subtract(const Duration(days: 366)), day)
      .map((list) => list.where((o) => o.task.id == key.id).toList());
});

class CaregiverDetailScreen extends ConsumerWidget {
  const CaregiverDetailScreen({super.key, required this.id, required this.day});
  final String id, day;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (id: id, day: day),
        state = ref.watch(caregiverDetailProvider((id: id, day: day)));
    final actions = ref.watch(caregiverScheduleViewModelProvider);
    return CaregiverPage(
        title: 'Chi tiết việc',
        onBack: () => context.go('/caregiver/schedule'),
        children: [
          if (actions.message != null) FieldMessage.error(actions.message!),
          state.when(
              loading: () => const LoadingView(),
              error: (e, st) => ErrorView(
                  message: 'Chưa tải được chi tiết việc.',
                  onRetry: () => ref.invalidate(caregiverDetailProvider(key))),
              data: (items) {
                final selected =
                    items.where((o) => dateKey(o.date) == day).firstOrNull;
                if (selected == null) {
                  return const EmptyView(
                      icon: Icons.event_busy_rounded,
                      title: 'Không có việc vào ngày này',
                      message: 'Lịch có thể đã thay đổi hoặc ngưng lặp lại.');
                }
                final t = selected.task;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TaskRow(
                          time: TimeOfDay(hour: t.hour, minute: t.minute),
                          title: t.title,
                          habitKey: t.habitKey,
                          status: t.status,
                          note:
                              '${repeatLabel(t)} · ${t.durationMinutes} phút'),
                      const SizedBox(height: AppSpacing.base),
                      Text('6 lần gần nhất',
                          style: Theme.of(context).textTheme.titleLarge),
                      for (final o in items.reversed.take(6))
                        CaregiverInfoCard(children: [
                          Text(dateKey(o.date)),
                          TaskStatusChip(status: o.task.status)
                        ]),
                      AppButton(
                          label: 'Sửa việc',
                          icon: Icons.edit_rounded,
                          wrapLabel: true,
                          onPressed: actions.busy
                              ? null
                              : () {
                                  ref
                                      .read(caregiverFormViewModelProvider
                                          .notifier)
                                      .start(
                                          existing: t,
                                          occurrence: selected.date);
                                  context.push('/caregiver/task/new');
                                }),
                      const SizedBox(height: AppSpacing.betweenTargets),
                      AppButton(
                          label: 'Ngưng lặp lại',
                          icon: Icons.event_busy_rounded,
                          kind: AppButtonKind.dangerOutline,
                          wrapLabel: true,
                          onPressed: actions.busy
                              ? null
                              : () async {
                                  final yes = await showConfirmDialog<bool>(
                                      context,
                                      icon: Icons.event_busy_rounded,
                                      title: 'Ngưng lặp lại việc này?',
                                      message:
                                          'Từ ${dateKey(selected.date)}, mẹ sẽ không được nhắc việc này. Những lần đã làm vẫn được giữ lại.',
                                      options: const [
                                        ConfirmOption(
                                            label: 'Giữ lại',
                                            icon: Icons.close_rounded,
                                            value: false),
                                        ConfirmOption(
                                            label: 'Ngưng lặp lại',
                                            icon: Icons.event_busy_rounded,
                                            value: true,
                                            kind: AppButtonKind.dangerOutline)
                                      ]);
                                  if (yes != true) return;
                                  final vm = ref.read(
                                      caregiverScheduleViewModelProvider
                                          .notifier);
                                  final undo = await vm.stop(t, selected.date);
                                  if (undo != null && context.mounted) {
                                    showUndoSnackbar(context,
                                        title: 'Đã ngưng lặp lại việc.',
                                        onUndo: () => vm.undo(undo));
                                    context.go('/caregiver/schedule');
                                  }
                                }),
                    ]);
              }),
        ]);
  }
}
