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
  const CaregiverScheduleScreen({super.key, this.view, this.date});
  final CalendarView? view;
  final DateTime? date;
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
      if (mounted && widget.date != null) {
        ref
            .read(caregiverScheduleViewModelProvider.notifier)
            .selectDate(widget.date!);
      }
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
    if (old.date != widget.date && widget.date != null) {
      Future.microtask(() {
        if (mounted) {
          ref
              .read(caregiverScheduleViewModelProvider.notifier)
              .selectDate(widget.date!);
        }
      });
    }
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
        root: true,
        titleAction: IconButton(
            tooltip: 'Hộp thông báo',
            onPressed: () => context.push('/inbox'),
            icon: const Icon(Icons.notifications_none_rounded)),
        onBack: () => context.go('/account'),
        footer: AppButton(
            label: 'Tạo lịch cho mẹ',
            icon: Icons.add_rounded,
            wrapLabel: true,
            onPressed: ref.watch(pairedMomUidProvider) == null
                ? null
                : () {
                    ref.read(caregiverFormViewModelProvider.notifier).start();
                    context.push('/caregiver/task/new');
                  }),
        children: [
          Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                for (final entry in const {
                  CalendarView.day: 'Ngày',
                  CalendarView.week: 'Tuần',
                  CalendarView.month: 'Tháng'
                }.entries)
                  Expanded(
                      child: TextButton(
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: s.view == entry.key
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          onPressed: () => vm.selectView(entry.key),
                          child: Text(entry.value))),
              ])),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final speed = details.primaryVelocity ?? 0;
              if (speed.abs() > 250) vm.move(speed < 0 ? 1 : -1);
            },
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(children: [
                      Row(children: [
                        IconButton(
                            tooltip: 'Trước',
                            onPressed: () => vm.move(-1),
                            icon: const Icon(Icons.chevron_left_rounded)),
                        Expanded(
                            child: TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                      context: context,
                                      initialDate: s.date,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100));
                                  if (date != null) vm.selectDate(date);
                                },
                                child: Text(
                                    '${s.date.day}/${s.date.month}/${s.date.year}',
                                    textAlign: TextAlign.center))),
                        IconButton(
                            tooltip: 'Sau',
                            onPressed: () => vm.move(1),
                            icon: const Icon(Icons.chevron_right_rounded)),
                      ]),
                      if (s.view != CalendarView.day) _calendar(context, s, vm),
                    ]))),
          ),
          if (dateKey(s.date) != dateKey(vietnamToday()))
            TextButton.icon(
                onPressed: () => vm.selectDate(vietnamToday()),
                icon: const Icon(Icons.today_rounded),
                label: const Text('Về hôm nay')),
          Text('Việc ngày ${s.date.day}/${s.date.month}',
              style: Theme.of(context).textTheme.titleLarge),
          if (s.message != null) FieldMessage.hint(s.message!),
          if (ref.watch(pairedMomUidProvider) == null)
            AppButton(
                label: 'Ghép nối',
                icon: Icons.phonelink_rounded,
                onPressed: () => context.push('/caregiver/pair')),
          switch (s.items) {
            UiLoading() => const LoadingView(),
            UiError(:final message) =>
              ErrorView(message: message, onRetry: vm.load),
            UiEmpty() => EmptyView(
                icon: Icons.event_available_rounded,
                title: 'Chưa có việc trong khoảng này',
                message: ref.watch(pairedMomUidProvider) == null
                    ? 'Ghép nối trước để cùng xem lịch.'
                    : 'Chọn Tạo lịch cho mẹ để thêm một việc.'),
            UiData(:final data) => Builder(builder: (context) {
                final selected = data
                    .where((o) => dateKey(o.date) == dateKey(s.date))
                    .toList();
                return selected.isEmpty
                    ? const EmptyView(
                        icon: Icons.event_available_rounded,
                        title: 'Ngày này chưa có việc')
                    : Column(children: [
                        for (final o in selected) ...[
                          _row(context, o),
                          const SizedBox(height: AppSpacing.base)
                        ]
                      ]);
              }),
          },
        ]);
  }

  Widget _calendar(BuildContext context, CaregiverCalendarState s,
      CaregiverScheduleViewModel vm) {
    final month = s.view == CalendarView.month;
    final first = month
        ? DateTime(s.date.year, s.date.month)
        : s.date.subtract(Duration(days: s.date.weekday - 1));
    final offset = month ? first.weekday - 1 : 0;
    final count = month ? DateTime(s.date.year, s.date.month + 1, 0).day : 7;
    final slots = ((offset + count) / 7).ceil() * 7;
    final data = switch (s.items) {
      UiData(:final data) => data,
      _ => <ScheduleOccurrence>[]
    };
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final text = Theme.of(context).textTheme.bodySmall;
      final painter = TextPainter(
        text: TextSpan(text: 'T7', style: text),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final cellWidth = (painter.width + 2 * AppSpacing.md)
          .clamp(AppSizes.minTarget, double.infinity);
      painter.dispose();
      // Keep all seven days readable; horizontal scroll replaces font shrinking.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth.clamp(7 * cellWidth, double.infinity),
          child: Column(children: [
            Row(children: [
              for (final label in const [
                'T2',
                'T3',
                'T4',
                'T5',
                'T6',
                'T7',
                'CN'
              ])
                Expanded(
                    child: ExcludeSemantics(
                        child: Text(label,
                            textAlign: TextAlign.center, style: text)))
            ]),
            const SizedBox(height: 8),
            for (var row = 0; row < slots ~/ 7; row++)
              Row(children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: Builder(builder: (context) {
                    final index = row * 7 + col - offset;
                    if (index < 0 || index >= count) {
                      return const SizedBox(height: AppSizes.minTarget);
                    }
                    final day = first.add(Duration(days: index));
                    final selected = dateKey(day) == dateKey(s.date);
                    final n = data
                        .where((o) => dateKey(o.date) == dateKey(day))
                        .length;
                    return Semantics(
                        button: true,
                        selected: selected,
                        label: 'Ngày ${day.day} tháng ${day.month}, $n việc',
                        child: ExcludeSemantics(
                            child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => vm.selectDate(day),
                                child: Container(
                                    constraints: const BoxConstraints(
                                        minHeight: AppSizes.minTarget),
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        color: selected ? colors.primary : null,
                                        borderRadius: BorderRadius.circular(18),
                                        border: dateKey(day) ==
                                                dateKey(vietnamToday())
                                            ? Border.all(color: colors.primary)
                                            : null),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('${day.day}',
                                              style: text?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: selected
                                                      ? colors.onPrimary
                                                      : colors.onSurface)),
                                          const SizedBox(height: 3),
                                          Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: n == 0
                                                      ? Colors.transparent
                                                      : selected
                                                          ? colors.onPrimary
                                                          : colors.primary)),
                                        ])))));
                  }))
              ]),
          ]),
        ),
      );
    });
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
