import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_item.dart';
import '../../services/caregiver_schedule_service.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/caregiver_schedule_view_model.dart';
import '../../viewmodels/caregiver_form_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/caregiver_parts.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';

class CaregiverScheduleScreen extends ConsumerStatefulWidget {
  const CaregiverScheduleScreen({super.key, this.view});
  final CalendarView? view;
  @override
  ConsumerState<CaregiverScheduleScreen> createState() =>
      _CaregiverScheduleScreenState();
}

class _CaregiverScheduleScreenState
    extends ConsumerState<CaregiverScheduleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && widget.view != null) {
        ref
            .read(caregiverScheduleViewModelProvider.notifier)
            .selectView(widget.view!);
      }
    });
  }

  @override
  void didUpdateWidget(CaregiverScheduleScreen old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) {
      Future.microtask(() {
        if (mounted && widget.view != null) {
          ref
              .read(caregiverScheduleViewModelProvider.notifier)
              .selectView(widget.view!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(caregiverScheduleViewModelProvider),
        vm = ref.read(caregiverScheduleViewModelProvider.notifier);
    return CaregiverPage(
        title: 'Lịch của mẹ',
        onBack: () => context.go('/account'),
        footer: AppButton(
            label: 'Tạo lịch cho mẹ',
            icon: Icons.add,
            wrapLabel: true,
            onPressed: ref.watch(pairedMomUidProvider) == null
                ? null
                : () {
                    ref.read(caregiverFormViewModelProvider.notifier).start();
                    context.push('/caregiver/task/new');
                  }),
        children: [
          if (ref.watch(pairedMomUidProvider) == null)
            AppButton(
                label: 'Ghép nối',
                icon: Icons.phonelink,
                kind: AppButtonKind.text,
                wrapLabel: true,
                onPressed: () => context.push('/caregiver/pair')),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            for (final entry in const {
              CalendarView.day: 'Ngày',
              CalendarView.week: 'Tuần',
              CalendarView.month: 'Tháng'
            }.entries)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      backgroundColor: s.view == entry.key
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null),
                  onPressed: () => vm.selectView(entry.key),
                  child: Text(entry.value)),
          ]),
          Text('Đang chọn: ${switch (s.view) {
            CalendarView.day => 'Ngày',
            CalendarView.week => 'Tuần',
            CalendarView.month => 'Tháng'
          }}'),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final speed = details.primaryVelocity ?? 0;
              if (speed.abs() > 250) vm.move(speed < 0 ? 1 : -1);
            },
            child: CalendarDateField(
                label: 'Chọn ngày', value: s.date, onChanged: vm.selectDate),
          ),
          const Text('Vuốt ngang trên ngày để chuyển nhanh.'),
          Wrap(
              spacing: AppSpacing.betweenTargets,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                    onPressed: () => vm.move(-1), child: const Text('← Trước')),
                OutlinedButton(
                    onPressed: () => vm.move(1), child: const Text('Sau →')),
              ]),
          if (dateKey(s.date) != dateKey(vietnamToday()))
            AppButton(
              label: 'Về hôm nay',
              icon: Icons.today_rounded,
              kind: AppButtonKind.tonal,
              onPressed: () => vm.selectDate(vietnamToday()),
            ),
          if (s.message != null) FieldMessage.hint(s.message!),
          switch (s.items) {
            UiLoading() => const LoadingView(),
            UiError(:final message) =>
              ErrorView(message: message, onRetry: vm.load),
            UiEmpty() => EmptyView(
                icon: Icons.event_available,
                title: 'Chưa có việc trong khoảng này',
                message: ref.watch(pairedMomUidProvider) == null
                    ? 'Ghép nối trước để cùng xem lịch.'
                    : 'Chọn Tạo lịch cho mẹ để thêm một việc.'),
            UiData(:final data) => s.view == CalendarView.day
                ? Column(children: [
                    for (final o in data) ...[
                      _row(context, o),
                      const SizedBox(height: AppSpacing.base)
                    ]
                  ])
                : Column(children: [
                    for (final day in _days(s)) ...[
                      AppButton(
                          label:
                              '${day.day}/${day.month}/${day.year} · ${data.where((o) => dateKey(o.date) == dateKey(day)).length} việc',
                          icon: Icons.calendar_today,
                          kind: AppButtonKind.secondary,
                          wrapLabel: true,
                          onPressed: () {
                            vm.selectView(CalendarView.day);
                            vm.selectDate(day);
                          }),
                      const SizedBox(height: AppSpacing.betweenTargets),
                    ]
                  ]),
          },
        ]);
  }

  List<DateTime> _days(CaregiverCalendarState s) {
    final from = s.view == CalendarView.week
        ? s.date.subtract(Duration(days: s.date.weekday - 1))
        : DateTime(s.date.year, s.date.month);
    final n = s.view == CalendarView.week
        ? 7
        : DateTime(s.date.year, s.date.month + 1, 0).day;
    return List.generate(n, (i) => from.add(Duration(days: i)));
  }

  Widget _row(BuildContext context, ScheduleOccurrence o) => TaskRow(
      time: TimeOfDay(hour: o.task.hour, minute: o.task.minute),
      title: o.task.title,
      habitKey: o.task.habitKey,
      status: o.task.status,
      note: repeatLabel(o.task),
      onTap: () => context.push(
          '/caregiver/task/${o.task.id}?date=${dateKey(o.date)}',
          extra: o));
}
