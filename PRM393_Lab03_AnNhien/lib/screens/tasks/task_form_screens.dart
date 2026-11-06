import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/task_form_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/icon_circle.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/botanical_scene.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/form_parts.dart';

const _activities = <_Activity>[
  _Activity('move', 'Đi bộ nhẹ nhàng', Icons.directions_walk_rounded),
  _Activity('plant', 'Chăm cây', Icons.local_florist_rounded),
  _Activity('family', 'Gọi người thân', Icons.phone_in_talk_rounded),
  _Activity('eighty', 'Ăn sáng chậm rãi', Icons.restaurant_rounded),
  _Activity('tea', 'Uống trà với bạn', Icons.local_cafe_rounded),
];

class _Activity {
  const _Activity(this.key, this.name, this.icon);
  final String key;
  final String name;
  final IconData icon;
}

String _period(int hour) => hour < 12 ? 'sáng' : 'chiều';
String _time(TaskFormState state) =>
    '${state.hour}:${state.minute.toString().padLeft(2, '0')} ${_period(state.hour)}';
String _repeatText(TaskFormState state) => switch (state.repeat) {
      RepeatRule.once => 'Một lần',
      RepeatRule.daily => 'Mỗi ngày',
      RepeatRule.someDays => 'Vài ngày trong tuần',
      RepeatRule.weekly => 'Mỗi tuần',
      RepeatRule.monthly => 'Mỗi tháng',
    };

class ActivitySelectionScreen extends ConsumerStatefulWidget {
  const ActivitySelectionScreen({super.key});
  @override
  ConsumerState<ActivitySelectionScreen> createState() =>
      _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState
    extends ConsumerState<ActivitySelectionScreen> {
  bool expanded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(taskFormViewModelProvider.notifier).startCreate());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskFormViewModelProvider);
    final vm = ref.read(taskFormViewModelProvider.notifier);
    final items = expanded ? _activities : _activities.take(3).toList();
    return Scaffold(
      appBar: AppBackBar.adaptive(context,
          step: 'Bước 1/2',
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/calendar')),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: AppButton(
                  label: 'Tiếp tục',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.push('/today/add/time')))),
      body: ListView(padding: AppSpacing.screenPadding, children: [
        const BotanicalScene(height: 140, branch: false),
        const SizedBox(height: AppSpacing.lg),
        Text('Bác muốn làm gì?',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        for (final activity in items) ...[
          _ActivityChoice(
              activity: activity,
              selected: activity.key == state.activity,
              onTap: () => vm.selectActivity(activity.key,
                  suggestedTitle: activity.name)),
          const SizedBox(height: AppSpacing.betweenTargets),
        ],
        Row(children: [
          Expanded(
              child: AppButton(
                  label: 'Nói việc',
                  icon: Icons.mic_none_rounded,
                  kind: AppButtonKind.secondary,
                  onPressed: () => context.push('/today/voice'))),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: AppButton(
                  label: expanded ? 'Thu gọn' : 'Xem thêm',
                  icon:
                      expanded ? Icons.expand_less_rounded : Icons.add_rounded,
                  kind: AppButtonKind.secondary,
                  onPressed: () => setState(() => expanded = !expanded))),
        ]),
      ]),
    );
  }
}

class _ActivityChoice extends StatelessWidget {
  const _ActivityChoice(
      {required this.activity, required this.selected, required this.onTap});
  final _Activity activity;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HabitTile(
      habitKey: activity.key,
      name: activity.name,
      icon: activity.icon,
      selected: selected,
      onTap: onTap);
}

class TaskConfigureScreen extends ConsumerStatefulWidget {
  const TaskConfigureScreen({super.key, this.editId, this.day});
  final DateTime? day;
  final String? editId;
  @override
  ConsumerState<TaskConfigureScreen> createState() =>
      _TaskConfigureScreenState();
}

class _TaskConfigureScreenState extends ConsumerState<TaskConfigureScreen> {
  final _title = TextEditingController();
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final found = await ref
            .read(taskFormViewModelProvider.notifier)
            .startEdit(widget.editId!, day: widget.day);
        if (mounted) {
          setState(() {
            _loaded = found;
            _title.text = ref.read(taskFormViewModelProvider).title;
          });
        }
      });
    } else {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = ref.read(taskFormViewModelProvider.notifier);
        if (ref.read(taskFormViewModelProvider).date == null) vm.startCreate();
        if (mounted) _title.text = ref.read(taskFormViewModelProvider).title;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(taskFormViewModelProvider);
    if (!state.isDirty) return true;
    final leave = await showConfirmDialog<bool>(context,
        icon: Icons.info_outline_rounded,
        title: 'Chưa lưu thay đổi',
        message: 'Nếu rời khỏi đây, phần vừa chỉnh sẽ không được lưu.',
        options: const [
          ConfirmOption(
              label: 'Tiếp tục chỉnh',
              icon: Icons.edit_rounded,
              value: false,
              kind: AppButtonKind.primary),
          ConfirmOption(
              label: 'Bỏ thay đổi',
              icon: Icons.delete_outline_rounded,
              value: true),
        ]);
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded && widget.editId != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final state = ref.watch(taskFormViewModelProvider);
    final vm = ref.read(taskFormViewModelProvider.notifier);
    if (state.saveState == TaskSaveState.saving ||
        state.saveState == TaskSaveState.offline ||
        state.saveState == TaskSaveState.error) {
      return TaskSaveStatusScreen(onBackToForm: vm.restoreEditing);
    }
    final activity =
        _activities.where((item) => item.key == state.activity).firstOrNull ??
            _activities.first;
    final edit = state.mode == TaskFormMode.edit;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _onWillPop();
        if (!leave || !mounted) return;
        Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBackBar.adaptive(context,
            backLabel: edit ? 'Sửa việc' : 'Quay lại',
            step: edit ? null : 'Bước 2/2', onBack: () async {
          if (await _onWillPop() && context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/calendar');
            }
          }
        }),
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: AppButton(
                    label: edit ? 'Lưu thay đổi' : 'Lưu việc này',
                    icon: Icons.save_rounded,
                    onPressed: () async {
                      ChangeScope? scope;
                      if (edit && state.repeat != RepeatRule.once) {
                        scope = await showScopeDialog(context, state.title);
                        if (scope == null || !context.mounted) return;
                      }
                      final saved = await vm.save(scope: scope);
                      if (!context.mounted) return;
                      if (saved && edit) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Đã lưu: ${state.title} lúc ${_time(ref.read(taskFormViewModelProvider))}.'),
                            action: SnackBarAction(
                                label: 'Hoàn tác',
                                onPressed: vm.undoLastMutation)));
                        context.go('/calendar');
                      } else if (saved) {
                        context.go('/today/add/result');
                      }
                    }))),
        body: ListView(padding: AppSpacing.screenPadding, children: [
          _ActivitySummary(activity: activity),
          const SizedBox(height: AppSpacing.lg),
          if (!edit)
            Text('Thêm việc',
                style: Theme.of(context).textTheme.headlineMedium),
          AppTextField(
              label: 'Tên việc',
              icon: Icons.edit_rounded,
              hint: 'Đi bộ buổi sáng',
              controller: _title,
              errorText:
                  state.showValidation ? 'Bác chưa nhập tên việc.' : null,
              onChanged: vm.setTitle),
          if (state.showValidation) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Bác chạm để chọn nhanh:',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children:
                    ['Đi bộ buổi sáng', 'Đi bộ buổi chiều', 'Làm vườn 20 phút']
                        .map((title) => ActionChip(
                            label: Text(title),
                            onPressed: () {
                              _title.text = title;
                              vm.setTitle(title);
                            }))
                        .toList())
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(icon: Icons.schedule_rounded, text: 'Giờ làm'),
          _PickerTile(
              text: _time(state),
              onTap: () async {
                final value = await showTaskTimeDialog(context, state);
                if (value != null) {
                  vm.setTime(hour: value.$1, minute: value.$2, isAm: value.$3);
                }
              }),
          if (state.showValidation && state.isTimeInPastToday) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Bác chọn giờ sau thời điểm hiện tại nhé.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(icon: Icons.repeat_rounded, text: 'Lặp lại'),
          ChoiceGroup<RepeatRule>(
              options: const [
                ChoiceOption(value: RepeatRule.daily, label: 'Mỗi ngày'),
                ChoiceOption(value: RepeatRule.someDays, label: 'Vài ngày'),
                ChoiceOption(value: RepeatRule.once, label: 'Một lần')
              ],
              value: state.repeat,
              onChanged: (value) async {
                if (value == RepeatRule.someDays) {
                  final result = await context.push<Set<int>>('/task/repeat');
                  if (result != null) {
                    vm.setRepeat(value);
                    vm.setWeekdays(result);
                  }
                } else {
                  vm.setRepeat(value);
                }
              }),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(
              icon: Icons.calendar_month_rounded, text: 'Ngày làm'),
          _PickerTile(
              text: state.date == null
                  ? 'Chọn ngày'
                  : '${state.date!.day}/${state.date!.month}/${state.date!.year}',
              onTap: state.mode == TaskFormMode.edit
                  ? null
                  : () async {
                      final value = await context.push<DateTime>('/task/date');
                      if (value != null) vm.setDate(value);
                    }),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile.adaptive(
              value: state.remind,
              onChanged: vm.setRemind,
              title: const FieldLabel('Nhắc nhở',
                  icon: Icons.notifications_none_rounded),
              subtitle: Text(state.remind ? 'Bật' : 'Tắt')),
          if (edit) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
                label: 'Xóa việc',
                icon: Icons.delete_outline_rounded,
                kind: AppButtonKind.dangerOutline,
                onPressed: () => _confirmDelete(context, state, vm))
          ],
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, TaskFormState state, TaskFormViewModel vm) async {
    ChangeScope? scope = ChangeScope.once;
    if (state.repeat != RepeatRule.once) {
      scope = await showScopeDialog(context, state.title);
    }
    if (scope == null || !context.mounted) return;
    final confirmed = await showConfirmDialog<bool>(context,
        icon: Icons.delete_outline_rounded,
        title: 'Xóa việc “${state.title}”?',
        message: scope == ChangeScope.once
            ? 'Chỉ xóa lần này. Ngày khác vẫn giữ.'
            : 'Xóa lần này và các lần sau.',
        danger: true,
        options: const [
          ConfirmOption(
              label: 'Không xóa, giữ lại',
              icon: Icons.close_rounded,
              value: false,
              kind: AppButtonKind.primary),
          ConfirmOption(
              label: 'Xóa khỏi lịch',
              icon: Icons.delete_outline_rounded,
              value: true,
              kind: AppButtonKind.dangerOutline),
        ]);
    if (confirmed != true || !context.mounted) return;
    if (await vm.delete(scope) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã xóa ${state.title} khỏi lịch.'),
          action: SnackBarAction(
              label: 'Hoàn tác', onPressed: vm.undoLastMutation)));
      context.go('/calendar');
    }
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.activity});
  final _Activity activity;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(children: [
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: HabitPalette.of(activity.key).bg,
                    borderRadius: AppRadius.mdAll),
                child: Icon(activity.icon,
                    color: HabitPalette.of(activity.key).fg,
                    size: AppSizes.icon)),
            const SizedBox(width: AppSpacing.base),
            Expanded(
                child: Text(activity.name,
                    style: Theme.of(context).textTheme.titleLarge))
          ])));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FieldLabel(text, icon: icon));
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.text, required this.onTap});
  final String text;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
      onPressed: onTap,
      child: Row(children: [
        Expanded(child: Text(text)),
        const Icon(Icons.keyboard_arrow_down_rounded)
      ]));
}

class TaskDateScreen extends StatefulWidget {
  const TaskDateScreen({super.key});
  @override
  State<TaskDateScreen> createState() => _TaskDateScreenState();
}

class _TaskDateScreenState extends State<TaskDateScreen> {
  DateTime selected = DateTime.now();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar:
          AppBackBar.adaptive(context, step: 'Thêm việc', onBack: context.pop),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AppButton(
                    label: 'Xong',
                    icon: Icons.check_rounded,
                    onPressed: () => context.pop(selected)),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                    label: 'Hủy',
                    icon: Icons.close_rounded,
                    kind: AppButtonKind.secondary,
                    onPressed: context.pop)
              ]))),
      body: ListView(padding: AppSpacing.screenPadding, children: [
        const CalmPageHeader(title: 'Chọn ngày', actions: false),
        const SizedBox(height: AppSpacing.base),
        Text('Chọn ngày, rồi bấm Xong để xác nhận.',
            style: Theme.of(context).textTheme.bodyLarge),
        CalendarDatePicker(
            initialDate: selected,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            onDateChanged: (value) => setState(() => selected = value)),
        Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Text(
                    'Đã chọn · ${selected.day}/${selected.month}/${selected.year}',
                    style: Theme.of(context).textTheme.titleMedium)))
      ]));
}

class TaskRepeatScreen extends ConsumerStatefulWidget {
  const TaskRepeatScreen({super.key});
  @override
  ConsumerState<TaskRepeatScreen> createState() => _TaskRepeatScreenState();
}

class _TaskRepeatScreenState extends ConsumerState<TaskRepeatScreen> {
  late Set<int> selected;
  @override
  void initState() {
    super.initState();
    selected = {...ref.read(taskFormViewModelProvider).weekdays};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar:
          AppBackBar.adaptive(context, step: 'Thêm việc', onBack: context.pop),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AppButton(
                    label: 'Lưu các ngày đã chọn',
                    icon: Icons.save_rounded,
                    onPressed:
                        selected.isEmpty ? null : () => context.pop(selected)),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                    label: 'Hủy',
                    icon: Icons.close_rounded,
                    kind: AppButtonKind.secondary,
                    onPressed: context.pop)
              ]))),
      body: ListView(padding: AppSpacing.screenPadding, children: [
        const CalmPageHeader(
            title: 'Chọn ngày trong tuần',
            subtitle: 'Chọn những ngày Bác muốn làm việc này.',
            actions: false),
        const SizedBox(height: AppSpacing.lg),
        const SizedBox(height: AppSpacing.sm),
        for (final day in const [
          (DateTime.monday, 'Thứ Hai'),
          (DateTime.tuesday, 'Thứ Ba'),
          (DateTime.wednesday, 'Thứ Tư'),
          (DateTime.thursday, 'Thứ Năm'),
          (DateTime.friday, 'Thứ Sáu'),
          (DateTime.saturday, 'Thứ Bảy'),
          (DateTime.sunday, 'Chủ Nhật')
        ]) ...[
          CheckboxListTile(
              shape:
                  const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
              tileColor: selected.contains(day.$1)
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              value: selected.contains(day.$1),
              onChanged: (checked) => setState(() => checked == true
                  ? selected.add(day.$1)
                  : selected.remove(day.$1)),
              title: Text(day.$2),
              controlAffinity: ListTileControlAffinity.leading),
          const SizedBox(height: AppSpacing.sm)
        ]
      ]));
}

/// Route có thể mở trực tiếp trong test/deep-link; luồng sửa bình thường dùng dialog cùng nội dung.
class TaskScopeRoute extends StatelessWidget {
  const TaskScopeRoute({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBackBar.adaptive(context),
      body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
            const BotanicalScene(height: 128, branch: false),
            const SizedBox(height: AppSpacing.lg),
            const CalmPageHeader(
                title: 'Thay đổi lần nào?',
                subtitle: 'Lịch sử được giữ lại',
                actions: false),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
                label: 'Chỉ lần này',
                icon: Icons.calendar_today_rounded,
                onPressed: () => context.pop(ChangeScope.once)),
            const SizedBox(height: AppSpacing.base),
            AppButton(
                label: 'Lần này và các lần sau',
                icon: Icons.date_range_rounded,
                kind: AppButtonKind.secondary,
                onPressed: () => context.pop(ChangeScope.thisAndFollowing)),
            const SizedBox(height: AppSpacing.base),
            AppButton(
                label: 'Giữ nguyên',
                icon: Icons.close_rounded,
                kind: AppButtonKind.text,
                onPressed: context.pop),
          ])));
}

class TaskSaveStatusScreen extends ConsumerWidget {
  const TaskSaveStatusScreen({super.key, required this.onBackToForm});
  final VoidCallback onBackToForm;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskFormViewModelProvider);
    final offline = state.saveState == TaskSaveState.offline;
    final error = state.saveState == TaskSaveState.error;
    if (!offline && !error) {
      return const Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(strokeWidth: AppSizes.spinnerStrokeLarge),
        SizedBox(height: AppSpacing.lg),
        Text('Đang lưu việc...'),
        SizedBox(height: AppSpacing.sm),
        Text('Không cần bấm gì thêm')
      ])));
    }
    return Scaffold(
        appBar: AppBackBar.adaptive(context, onBack: onBackToForm),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              Center(
                  child: IconCircle(
                      icon: error
                          ? Icons.error_outline_rounded
                          : Icons.sync_rounded,
                      danger: error)),
              const SizedBox(height: AppSpacing.lg),
              Text(error ? 'Chưa lưu được' : 'Đang lưu việc...',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(
                  error
                      ? 'Chưa thể lưu trên điện thoại.\nNội dung đang nhập vẫn được giữ lại.'
                      : 'Lưu trên điện thoại, không cần mạng\nĐang không có mạng',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              if (error) ...[
                AppButton(
                    label: 'Thử lại',
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.read(taskFormViewModelProvider.notifier).save()),
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label: 'Quay lại sửa',
                    icon: Icons.edit_rounded,
                    kind: AppButtonKind.secondary,
                    onPressed: onBackToForm),
              ] else
                AppButton(
                    label: 'Về trang chủ',
                    icon: Icons.home_rounded,
                    onPressed: () => context.go('/calendar')),
            ])));
  }
}

class TaskSavedScreen extends ConsumerWidget {
  const TaskSavedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskFormViewModelProvider);
    final activity =
        _activities.where((item) => item.key == state.activity).firstOrNull ??
            _activities.first;
    return Scaffold(
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AppButton(
                      label: 'Về trang chủ',
                      icon: Icons.home_rounded,
                      onPressed: () => context.go('/calendar')),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                      label: 'Thêm việc khác',
                      icon: Icons.add_rounded,
                      kind: AppButtonKind.secondary,
                      onPressed: () {
                        ref
                            .read(taskFormViewModelProvider.notifier)
                            .startCreate();
                        context.go('/today/add');
                      })
                ]))),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const IconCircle(icon: Icons.check_rounded),
                              const SizedBox(height: AppSpacing.lg),
                              Text('Đã lưu xong!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: AppSpacing.xl),
                              _ActivitySummary(activity: activity),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                  '${_time(state)}\n${_repeatText(state)}${state.remind ? '\nNhắc trước 10 phút' : ''}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center)
                            ]))))));
  }
}

Future<(int, int, bool)?> showTaskTimeDialog(
    BuildContext context, TaskFormState initial) async {
  // Hiển thị theo 12 giờ: 0:xx là 12:xx sáng, 12:xx là 12:xx chiều.
  var hour = initial.hour % 12;
  if (hour == 0) hour = 12;
  var minute = initial.minute;
  var am = initial.isAm;
  return showDialog<(int, int, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
            final value = hour == 12 ? (am ? 0 : 12) : (am ? hour : hour + 12);
            final now = DateTime.now();
            final selectedDate = initial.date;
            final isToday = selectedDate != null &&
                selectedDate.year == now.year &&
                selectedDate.month == now.month &&
                selectedDate.day == now.day;
            final isPast = isToday &&
                DateTime(now.year, now.month, now.day, value, minute)
                    .isBefore(now);
            return AlertDialog(
                title: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule_rounded),
                  SizedBox(width: AppSpacing.sm),
                  Text('Giờ làm')
                ]),
                content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chạm vào số Bác muốn'),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Giờ'),
                        Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: List.generate(12, (i) {
                              final n = i + 1;
                              return ChoiceChip(
                                  label: Text('$n'),
                                  selected: hour == n,
                                  onSelected: (_) => setState(() => hour = n));
                            })),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Phút'),
                        Wrap(
                            spacing: AppSpacing.sm,
                            children: [0, 15, 30, 45]
                                .map((n) => ChoiceChip(
                                    label: Text(n.toString().padLeft(2, '0')),
                                    selected: minute == n,
                                    onSelected: (_) =>
                                        setState(() => minute = n)))
                                .toList()),
                        const SizedBox(height: AppSpacing.md),
                        Row(children: [
                          Expanded(
                              child: ChoiceChip(
                                  label: const Text('Sáng'),
                                  selected: am,
                                  onSelected: (_) =>
                                      setState(() => am = true))),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: ChoiceChip(
                                  label: const Text('Chiều'),
                                  selected: !am,
                                  onSelected: (_) =>
                                      setState(() => am = false)))
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                            isPast
                                ? 'Bác chọn giờ sau thời điểm hiện tại nhé.'
                                : 'Bác chọn: $hour:${minute.toString().padLeft(2, '0')} ${am ? 'sáng' : 'chiều'}',
                            style: isPast
                                ? TextStyle(
                                    color: Theme.of(context).colorScheme.error)
                                : null)
                      ]),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: isPast
                          ? null
                          : () => Navigator.pop(context, (value, minute, am)),
                      child: const Text('Lưu giờ'))
                ]);
          }));
}

Future<ChangeScope?> showScopeDialog(BuildContext context, String title) =>
    showConfirmDialog<ChangeScope?>(context,
        icon: Icons.repeat_rounded,
        title: 'Thay đổi lần nào?',
        message: '$title, lặp lại',
        details: const [
          ConfirmDetail(
              icon: Icons.info_outline_rounded, text: 'Lịch sử được giữ lại')
        ],
        options: const [
          ConfirmOption(
              label: 'Chỉ lần này',
              icon: Icons.calendar_today_rounded,
              value: ChangeScope.once,
              kind: AppButtonKind.primary),
          ConfirmOption(
              label: 'Lần này và các lần sau',
              icon: Icons.date_range_rounded,
              value: ChangeScope.thisAndFollowing),
          ConfirmOption(
              label: 'Giữ nguyên', icon: Icons.close_rounded, value: null)
        ]);
