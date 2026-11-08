import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_item.dart';
import '../../services/caregiver_schedule_service.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/caregiver_form_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/caregiver_parts.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';
import '../../widgets/switch_row.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/time_field.dart';

class CaregiverFormScreen extends ConsumerStatefulWidget {
  const CaregiverFormScreen({super.key, this.step = 1});
  final int step;
  @override
  ConsumerState<CaregiverFormScreen> createState() =>
      _CaregiverFormScreenState();
}

class _CaregiverFormScreenState extends ConsumerState<CaregiverFormScreen> {
  late final TextEditingController title, message;
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void initState() {
    super.initState();
    final s = ref.read(caregiverFormViewModelProvider);
    title = TextEditingController(text: s.task.title);
    message = TextEditingController(text: s.message);
  }

  @override
  void didUpdateWidget(CaregiverFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    title.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> back() async {
    if (ref.read(caregiverFormViewModelProvider).busy) return;
    if (widget.step > 1) {
      context.go('/caregiver/task/new');
      return;
    }
    if (!ref.read(caregiverFormViewModelProvider).dirty) {
      context.go('/caregiver/schedule');
      return;
    }
    final discard = await showConfirmDialog<bool>(context,
        icon: Icons.edit_note_rounded,
        title: 'Rời màn khi chưa lưu?',
        message: 'Thông tin đang nhập chưa được gửi cho mẹ.',
        options: const [
          ConfirmOption(
              label: 'Tiếp tục nhập', icon: Icons.edit_rounded, value: false),
          ConfirmOption(
              label: 'Bỏ thay đổi',
              icon: Icons.close_rounded,
              value: true,
              kind: AppButtonKind.dangerOutline)
        ]);
    if (discard == true && mounted) {
      ref.read(caregiverFormViewModelProvider.notifier).start();
      context.go('/caregiver/schedule');
    }
  }

  Future<void> submit() async {
    final vm = ref.read(caregiverFormViewModelProvider.notifier);
    var ok = await vm.submit();
    if (!mounted) return;
    if (!ok && ref.read(caregiverFormViewModelProvider).conflicts.isNotEmpty) {
      final input = ref.read(caregiverFormViewModelProvider);
      final canSend = input.original == null && input.needsConsent;
      final send = await showConfirmDialog<bool>(context,
          icon: Icons.schedule_rounded,
          title: 'Có việc trùng giờ',
          message:
              'Lịch trùng giờ với việc đã có trong lịch. Mẹ có thể khó làm cả hai việc.',
          options: [
            const ConfirmOption(
                label: 'Đổi giờ khác', icon: Icons.edit_rounded, value: false),
            if (canSend)
              const ConfirmOption(
                  label: 'Vẫn gửi', icon: Icons.send_rounded, value: true)
          ]);
      if (!mounted) return;
      if (send == true) {
        ok = await vm.submit(allowConflict: true);
      } else if (send == false) {
        context.go('/caregiver/task/new');
      }
    }
    if (ok && mounted) context.go('/caregiver/task/sent');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(caregiverFormViewModelProvider),
        vm = ref.read(caregiverFormViewModelProvider.notifier);
    final t = s.task;
    final text = Theme.of(context).textTheme;
    void update(TaskItem task) => vm.updateTask(task);
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) back();
        },
        child: CaregiverPage(
            title: switch (widget.step) {
              1 => 'Thông tin việc',
              2 => 'Lặp lại',
              _ => 'Xem lại và gửi'
            },
            step: widget.step == 2
                ? 'Lịch lặp'
                : 'Bước ${widget.step == 1 ? 1 : 2}/2',
            scrollController: _scroll,
            onBack: back,
            footer: AppButton(
                label: widget.step == 3
                    ? (s.original != null ? 'Lưu thay đổi' : 'Gửi lịch cho mẹ')
                    : widget.step == 2
                        ? 'Dùng lịch này'
                        : 'Xem lại',
                icon: widget.step == 3
                    ? Icons.send_rounded
                    : Icons.arrow_forward_rounded,
                busy: s.busy,
                wrapLabel: true,
                onPressed: () {
                  if (widget.step == 3) {
                    submit();
                  } else if (widget.step == 2) {
                    context.go('/caregiver/task/new');
                  } else if (vm.validate()) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(0);
                    }
                    context.go('/caregiver/task/new/review');
                  } else if (_scroll.hasClients) {
                    _scroll.animateTo(0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                  }
                }),
            children: [
              if (s.error != null) FieldMessage.error(s.error!),
              if (widget.step == 1) ...[
                Text('Chọn nhanh một việc', style: text.titleSmall),
                LayoutBuilder(
                    builder: (context, box) => Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            for (final preset in const [
                              (
                                'Đi bộ buổi sáng',
                                'move',
                                Icons.directions_walk_rounded
                              ),
                              (
                                'Uống trà',
                                'tea',
                                Icons.emoji_food_beverage_rounded
                              ),
                              (
                                'Thư giãn',
                                'downshift',
                                Icons.self_improvement_rounded
                              ),
                              (
                                'Gọi cho gia đình',
                                'family',
                                Icons.call_rounded
                              ),
                            ])
                              SizedBox(
                                  width: MediaQuery.textScalerOf(context)
                                              .scale(1) >
                                          1.3
                                      ? box.maxWidth
                                      : (box.maxWidth - AppSpacing.md) / 2,
                                  child: OutlinedButton.icon(
                                    icon: Icon(preset.$3),
                                    label: Text(switch (preset.$2) {
                                      'move' => 'Đi bộ',
                                      'family' => 'Gọi nhà',
                                      _ => preset.$1,
                                    }),
                                    onPressed: () {
                                      title.value = TextEditingValue(
                                          text: preset.$1,
                                          selection: TextSelection.collapsed(
                                              offset: preset.$1.length));
                                      update(t.copyWith(
                                          title: preset.$1,
                                          habitKey: preset.$2));
                                    },
                                  )),
                          ],
                        )),
                AppTextField(
                    label: 'Tên việc',
                    controller: title,
                    hint: 'Đi bộ buổi sáng. Mẹ sẽ thấy đúng tên này.',
                    maxLength: 80,
                    onChanged: (v) => update(t.copyWith(title: v))),
                TimeField(
                    label: 'Giờ nhắc',
                    value: TimeOfDay(hour: t.hour, minute: t.minute),
                    onChanged: (v) =>
                        update(t.copyWith(hour: v.hour, minute: v.minute))),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final hour in const [7, 9, 15, 19])
                      OutlinedButton(
                        onPressed: () =>
                            update(t.copyWith(hour: hour, minute: 0)),
                        child: Text(
                            '${t.hour == hour && t.minute == 0 ? '✓ ' : ''}${hour.toString().padLeft(2, '0')}:00'),
                      ),
                  ],
                ),
                Text('Thời lượng thực hiện', style: text.titleLarge),
                ChoiceGroup<int>(
                    options: const [
                      ChoiceOption(value: 15, label: '15 phút'),
                      ChoiceOption(value: 30, label: '30 phút'),
                      ChoiceOption(value: 60, label: '60 phút')
                    ],
                    value: t.durationMinutes,
                    onChanged: (v) => update(t.copyWith(durationMinutes: v))),
                Text('Lịch nhắc: ${repeatLabel(t)}', style: text.titleSmall),
                Text(
                    'Bắt đầu: ${DateTime.parse(t.startDate!).day}/${DateTime.parse(t.startDate!).month}/${DateTime.parse(t.startDate!).year}',
                    style: text.bodyMedium),
                AppButton(
                  label: 'Đổi ngày hoặc lịch lặp',
                  icon: Icons.event_repeat_rounded,
                  kind: AppButtonKind.secondary,
                  wrapLabel: true,
                  onPressed: () {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(0);
                    }
                    context.go('/caregiver/task/new/repeat');
                  },
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Đổi nhóm thói quen', style: text.titleSmall),
                  subtitle: Text(ref
                          .watch(caregiverHabitsProvider)
                          .asData
                          ?.value
                          .where((habit) => habit.key == t.habitKey)
                          .firstOrNull
                          ?.name ??
                      'Chọn nhóm phù hợp'),
                  children: [
                    ref.watch(caregiverHabitsProvider).when(
                          loading: () => const LoadingView(),
                          error: (e, st) => ErrorView(
                              message: 'Chưa tải được thói quen.',
                              onRetry: () =>
                                  ref.invalidate(caregiverHabitsProvider)),
                          data: (habits) => habits.isEmpty
                              ? const FieldMessage.hint(
                                  'Chưa có thói quen. Tải dữ liệu mẫu trước.')
                              : CaregiverHabitChoices(
                                  habits: habits,
                                  value: t.habitKey,
                                  onChanged: (key) =>
                                      update(t.copyWith(habitKey: key))),
                        ),
                  ],
                ),
              ] else if (widget.step == 2) ...[
                ChoiceGroup<RepeatRule>(
                    options: const [
                      ChoiceOption(value: RepeatRule.once, label: 'Một lần'),
                      ChoiceOption(value: RepeatRule.daily, label: 'Mỗi ngày'),
                      ChoiceOption(value: RepeatRule.weekly, label: 'Mỗi tuần'),
                      ChoiceOption(
                          value: RepeatRule.monthly, label: 'Mỗi tháng')
                    ],
                    value: t.repeat == RepeatRule.someDays
                        ? RepeatRule.weekly
                        : t.repeat,
                    onChanged: (v) => update(t.copyWith(
                        repeat: v,
                        clearEndDate: v == RepeatRule.once,
                        weekdays: t.weekdays.isEmpty
                            ? [DateTime.parse(t.startDate!).weekday]
                            : t.weekdays,
                        monthDays: t.monthDays.isEmpty
                            ? [DateTime.parse(t.startDate!).day]
                            : t.monthDays))),
                if ([RepeatRule.weekly, RepeatRule.someDays]
                    .contains(t.repeat)) ...[
                  Text('Nhắc vào các ngày trong tuần', style: text.titleLarge),
                  Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          OutlinedButton(
                              onPressed: () {
                                final days = [...t.weekdays];
                                days.contains(day)
                                    ? days.remove(day)
                                    : days.add(day);
                                days.sort();
                                update(t.copyWith(weekdays: days));
                              },
                              child: Text(
                                  '${t.weekdays.contains(day) ? '✓ ' : ''}${day == 7 ? 'CN' : 'T${day + 1}'}')),
                      ]),
                ],
                if (t.repeat == RepeatRule.monthly) ...[
                  Text('Chọn ngày trong tháng', style: text.titleLarge),
                  const FieldMessage.hint(
                      'Ngày 29–31 chỉ xuất hiện trong tháng có ngày đó. Chọn Cuối tháng nếu muốn luôn nhắc ngày cuối.'),
                  Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (var day = 1; day <= 31; day++)
                          OutlinedButton(
                              onPressed: () {
                                final days = [...t.monthDays];
                                days.contains(day)
                                    ? days.remove(day)
                                    : days.add(day);
                                days.sort();
                                update(t.copyWith(monthDays: days));
                              },
                              child: Text(
                                  '${t.monthDays.contains(day) ? '✓ ' : ''}$day')),
                      ]),
                  SwitchRow(
                      title: 'Cuối tháng',
                      value: t.lastDayOfMonth,
                      onChanged: (v) => update(t.copyWith(lastDayOfMonth: v))),
                ],
                CalendarDateField(
                    label: 'Bắt đầu',
                    value: DateTime.parse(t.startDate!),
                    onChanged: (d) =>
                        update(t.copyWith(startDate: dateKey(d)))),
                if (t.repeat != RepeatRule.once && t.endDate != null)
                  CalendarDateField(
                      label: 'Kết thúc',
                      value: DateTime.parse(t.endDate ?? t.startDate!),
                      firstDate: DateTime.parse(t.startDate!),
                      onChanged: (d) =>
                          update(t.copyWith(endDate: dateKey(d)))),
                if (t.repeat != RepeatRule.once)
                  AppButton(
                      label: t.endDate == null
                          ? 'Thêm ngày kết thúc (hiện không giới hạn)'
                          : 'Bỏ ngày kết thúc',
                      icon: Icons.all_inclusive_rounded,
                      kind: AppButtonKind.text,
                      wrapLabel: true,
                      onPressed: () async {
                        if (t.endDate != null) {
                          update(t.copyWith(clearEndDate: true));
                          return;
                        }
                        final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(t.startDate!),
                            firstDate: DateTime.parse(t.startDate!),
                            lastDate: DateTime(2100));
                        if (date != null && mounted) {
                          update(t.copyWith(endDate: dateKey(date)));
                        }
                      }),
                Text(repeatLabel(t), style: text.bodyLarge),
              ] else ...[
                TaskRow(
                    time: TimeOfDay(hour: t.hour, minute: t.minute),
                    title: t.title,
                    habitKey: t.habitKey,
                    note: '${repeatLabel(t)} · ${t.durationMinutes} phút'),
                Text(
                    'Từ ${t.startDate}${t.endDate == null ? ' · Không giới hạn' : ' đến ${t.endDate}'}',
                    style: text.bodyLarge),
                AppButton(
                  label: 'Sửa thông tin lịch',
                  icon: Icons.edit_rounded,
                  kind: AppButtonKind.secondary,
                  wrapLabel: true,
                  onPressed:
                      s.busy ? null : () => context.go('/caregiver/task/new'),
                ),
                if (s.original == null) ...[
                  AppTextField(
                      label: 'Lời nhắn cho mẹ (không bắt buộc)',
                      controller: message,
                      maxLength: 500,
                      onChanged: vm.message),
                  SwitchRow(
                      title: 'Mẹ nhận trước khi thêm',
                      value: s.needsConsent,
                      onChanged: vm.consent),
                  Text(
                      s.needsConsent
                          ? 'Mẹ tự chọn nhận hoặc bỏ qua.'
                          : 'Lịch được thêm trực tiếp vào máy của mẹ theo quyền ghép nối.',
                      style: text.bodyLarge),
                ] else
                  ChoiceGroup<ChangeScope>(options: const [
                    ChoiceOption(
                        value: ChangeScope.occurrence, label: 'Chỉ lần này'),
                    ChoiceOption(
                        value: ChangeScope.future, label: 'Từ lần này về sau'),
                    ChoiceOption(
                        value: ChangeScope.all, label: 'Tất cả các lần')
                  ], value: s.scope, onChanged: vm.scope),
              ],
            ]));
  }
}

class CaregiverSentScreen extends ConsumerWidget {
  const CaregiverSentScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(caregiverFormViewModelProvider);
    return CaregiverPage(
        title: s.saved
            ? (s.original != null
                ? 'Đã lưu thay đổi'
                : s.needsConsent
                    ? 'Đã gửi gợi ý cho mẹ'
                    : 'Đã thêm vào lịch của mẹ')
            : 'Chưa có lịch vừa gửi',
        onBack: () => context.go('/caregiver/schedule'),
        children: [
          if (s.saved)
            Text(s.original != null
                ? 'Lịch đã được cập nhật.'
                : s.needsConsent
                    ? 'Mẹ sẽ chọn nhận trước khi việc xuất hiện trong lịch.'
                    : 'Mẹ có thể xem việc trong lịch.'),
          AppButton(
              label: 'Xem lịch của mẹ',
              icon: Icons.calendar_month_rounded,
              wrapLabel: true,
              onPressed: () => context.go('/caregiver/schedule')),
        ]);
  }
}
