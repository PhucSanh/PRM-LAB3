import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../viewmodels/daily_actions_view_model.dart';
import '../utils/app_error.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'undo_snackbar.dart';

class QuickTaskActions extends ConsumerWidget {
  const QuickTaskActions(
      {super.key,
      required this.task,
      required this.day,
      this.completeOnly = false});
  final TaskItem task;
  final DateTime day;
  final bool completeOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(dailyActionsProvider),
        vm = ref.read(dailyActionsProvider.notifier);
    Future<void> run(
        Future<QuickTaskUndo?> Function() action, String message) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final change = await action();
        if (change == null || !context.mounted) return;
        showUndoSnackbar(context, title: message, onUndo: () async {
          try {
            await vm.undo(change);
          } catch (e) {
            if (messenger.mounted)
              messenger.showSnackBar(SnackBar(
                  content: Text(e is AppException
                      ? e.userMessage
                      : 'Chưa hoàn tác được. Bác thử lại nhé.')));
          }
        });
      } catch (e) {
        if (messenger.mounted)
          messenger.showSnackBar(SnackBar(
              content: Text(e is AppException
                  ? e.userMessage
                  : 'Chưa cập nhật được. Bác thử lại nhé.')));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppButton(
          label: 'Đã làm',
          icon: Icons.check_circle_outline_rounded,
          busy: busy,
          onPressed: () =>
              run(() => vm.complete(task, day), 'Đã đánh dấu làm xong')),
      if (!completeOnly) ...[
        const SizedBox(height: AppSpacing.md),
        AppButton(
            label: 'Nhắc sau 10 phút',
            icon: Icons.snooze_rounded,
            kind: AppButtonKind.secondary,
            onPressed: busy
                ? null
                : () => run(
                    () => vm.move(task, day,
                        vietnamNow().add(const Duration(minutes: 10))),
                    task.remind
                        ? 'Đã dời việc sau 10 phút'
                        : 'Đã dời việc sau 10 phút. Lời nhắc đang tắt.')),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            label: 'Dời sang giờ khác',
            icon: Icons.edit_calendar_rounded,
            kind: AppButtonKind.secondary,
            onPressed: busy
                ? null
                : () async {
                    final now = vietnamNow();
                    final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(now.year, now.month, now.day),
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(2100, 12, 31));
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay(hour: task.hour, minute: task.minute));
                    if (time == null || !context.mounted) return;
                    await run(
                        () => vm.move(
                            task,
                            day,
                            DateTime(date.year, date.month, date.day, time.hour,
                                time.minute)),
                        'Đã dời giờ cho lần này');
                  }),
        const SizedBox(height: AppSpacing.sm),
        const Text(
            'Chỉ dời lần này; các lần lặp khác giữ nguyên. Thời gian thông báo còn tuỳ cài đặt điện thoại.'),
      ],
    ]);
  }
}
