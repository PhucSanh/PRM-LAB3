import '../models/habit.dart';
import 'habit_widgets.dart';
import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../theme/app_spacing.dart';
import 'app_back_bar.dart';
import 'app_button.dart';

/// Bố cục F13/F14 dùng token và thanh/nút F0; footer cuộn được khi chữ lớn.
class CaregiverPage extends StatelessWidget {
  const CaregiverPage(
      {super.key,
      required this.title,
      required this.children,
      this.step,
      this.footer,
      this.onBack,
      this.scrollController});
  final String title;
  final List<Widget> children;
  final String? step;
  final Widget? footer;
  final VoidCallback? onBack;
  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBackBar(step: step, onBack: onBack),
        body: SafeArea(
            child: ListView(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              for (final child in children) ...[
                child,
                const SizedBox(height: AppSpacing.base)
              ],
            ])),
        bottomNavigationBar: footer == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant)),
                ),
                child: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.md,
                            AppSpacing.screen,
                            AppSpacing.screen),
                        child: footer)),
              ),
      );
}

class CaregiverInfoCard extends StatelessWidget {
  const CaregiverInfoCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              child
            ],
          ])));
}

String repeatLabel(TaskItem t) => switch (t.repeat) {
      RepeatRule.once => 'Một lần',
      RepeatRule.daily => 'Mỗi ngày',
      RepeatRule.weekly ||
      RepeatRule.someDays =>
        'Mỗi tuần: ${t.weekdays.map((d) => d == 7 ? 'CN' : 'T${d + 1}').join(', ')}',
      RepeatRule.monthly => 'Mỗi tháng: ${[
          ...t.monthDays.map((n) => '$n'),
          if (t.lastDayOfMonth) 'cuối tháng'
        ].join(', ')}',
    };

class CalendarDateField extends StatelessWidget {
  const CalendarDateField(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged,
      this.firstDate});
  final String label;
  final DateTime value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => AppButton(
      label: '$label: ${value.day}/${value.month}/${value.year}',
      icon: Icons.calendar_month,
      kind: AppButtonKind.secondary,
      wrapLabel: true,
      onPressed: () async {
        final first = firstDate ?? DateTime(2020);
        final date = await showDatePicker(
            context: context,
            initialDate: value.isBefore(first) ? first : value,
            firstDate: first,
            lastDate: DateTime(2100));
        if (date != null) onChanged(date);
      });
}

/// Bốn nhóm ở C06; chuyển từ hai cột sang một cột khi chữ lớn.
class CaregiverHabitChoices extends StatelessWidget {
  const CaregiverHabitChoices(
      {super.key,
      required this.habits,
      required this.value,
      required this.onChanged});
  final List<Habit> habits;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final compact = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final width =
            compact ? (box.maxWidth - AppSpacing.md) / 2 : box.maxWidth;
        const commonKeys = {'move', 'downshift', 'eighty', 'family'};
        return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final habit in habits
                  .where((h) => commonKeys.contains(h.key) || h.key == value))
                SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      selected: habit.key == value,
                      inMutuallyExclusiveGroup: true,
                      label: habit.name,
                      child: HabitAccentCard(
                        habitKey: habit.key,
                        selected: habit.key == value,
                        onTap: () => onChanged(habit.key),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  HabitBadge(habitKey: habit.key),
                                  Icon(
                                      habit.key == value
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      size: AppSizes.icon,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(habit.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              if (habit.key == value)
                                Text('Đang chọn',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                            ]),
                      ),
                    )),
            ]);
      });
}
