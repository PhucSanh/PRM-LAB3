import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../theme/app_spacing.dart';
import 'section_card.dart';
import 'quick_task_actions.dart';

class UpcomingActivityCard extends StatelessWidget {
  const UpcomingActivityCard(
      {super.key,
      required this.task,
      required this.day,
      required this.canComplete,
      required this.onOpen});
  final TaskItem task;
  final DateTime day;
  final bool canComplete;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => SectionCard(
      icon: Icons.schedule_rounded,
      title: 'Việc sắp tới',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        if (canComplete)
          QuickTaskActions(task: task, day: day, completeOnly: true),
        TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Xem chi tiết')),
      ]));
}
