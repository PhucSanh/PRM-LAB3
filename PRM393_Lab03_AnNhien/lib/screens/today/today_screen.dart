import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_item.dart';
import '../../services/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/assistant_bubble.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/time_field.dart';
import 'task_detail_screen.dart';

/// S03 Hôm nay – danh sách chính và chế độ xem từng việc dạng flashcard.
/// Dữ liệu và các thao tác lưu thuộc [TodayViewModel].
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key, this.forceMainView = false});

  /// Khi một flow con hoàn tất, router truyền cờ này để bỏ trạng thái
  /// flashcard còn giữ trong StatefulShell và hiển thị S03 chính.
  final bool forceMainView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayViewModelProvider);
    final vm = ref.read(todayViewModelProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải việc hôm nay…'),
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          UiEmpty() => _TodayEmpty(
              onAddTask: () => context.push('/today/add'),
              onOpenSettings: () => context.push('/settings'),
              onOpenInbox: () => context.push('/inbox'),
            ),
          UiData(:final data) => _TodayContent(
              key: ValueKey(forceMainView ? 'today-main' : 'today-default'),
              data: data),
        },
      ),
    );
  }
}

/// S03 trống vẫn cần lối vào Cài đặt và Hộp thông báo như S03 danh sách cũ.
/// Đây là thao tác phụ, còn “Thêm việc đầu tiên” vẫn là hành động chính.
class _TodayEmpty extends StatelessWidget {
  const _TodayEmpty({
    required this.onAddTask,
    required this.onOpenSettings,
    required this.onOpenInbox,
  });

  final VoidCallback onAddTask;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: AppSpacing.sm, children: [
                TextButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(AppIcons.settings),
                  label: const Text('Cài đặt'),
                ),
                TextButton.icon(
                  onPressed: onOpenInbox,
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: const Text('Thông báo'),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            EmptyView(
              icon: Icons.event_available_outlined,
              title: 'Hôm nay chưa có việc',
              message: 'Bắt đầu nhẹ nhàng với một việc nhỏ.',
              action: AppButton(
                label: 'Thêm việc đầu tiên',
                icon: Icons.add,
                onPressed: onAddTask,
              ),
            ),
          ],
        ),
      );
}

class _TodayContent extends ConsumerStatefulWidget {
  const _TodayContent({super.key, required this.data});
  final TodayData data;

  @override
  ConsumerState<_TodayContent> createState() => _TodayContentState();
}

class _TodayContentState extends ConsumerState<_TodayContent> {
  bool _showFlashcards = false;
  int _flashIndex = 0;

  /// 1 = thẻ mới đi vào từ phải; -1 = đi vào từ trái.
  int _flashDirection = 1;

  @override
  void didUpdateWidget(covariant _TodayContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_flashIndex >= widget.data.tasks.length) _flashIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    // S03 vẫn hiển thị được trong chế độ Fake/test khi Firebase Auth chưa
    // khởi tạo; lúc đó dùng cách xưng hô mặc định thay vì làm hỏng cả màn.
    String? name;
    try {
      name = ref.watch(authServiceProvider).currentUser?.displayName;
    } catch (_) {}
    final greeting = 'Chào ${name?.trim().isNotEmpty == true ? name : 'Bác'}';
    return ListView(
      key: ValueKey(_showFlashcards ? 's03-flashcards' : 's03-main'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
          AppSpacing.screen, AssistantBubble.clearance),
      children: [
        _S03Header(
            greeting: greeting,
            doneCount: widget.data.doneCount,
            total: widget.data.total),
        const SizedBox(height: AppSpacing.xl),
        if (_showFlashcards) _flashcardView(context) else _mainView(context),
      ],
    );
  }

  Widget _mainView(BuildContext context) {
    final theme = Theme.of(context);
    final next = widget.data.next;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (next != null) ...[
        Semantics(
            header: true,
            child:
                Text('Việc tiếp theo', style: theme.textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.base),
        _nextTaskCard(context, next),
        const SizedBox(height: AppSpacing.xl),
      ] else if (widget.data.allHandled) ...[
        _AllHandledBanner(allDone: widget.data.allDone),
        const SizedBox(height: AppSpacing.xl),
      ],
      Semantics(
          header: true,
          child: Text('Việc hôm nay', style: theme.textTheme.headlineSmall)),
      const SizedBox(height: AppSpacing.base),
      for (var index = 0; index < widget.data.tasks.length; index++) ...[
        _todayTaskCard(context, widget.data.tasks[index], index),
        const SizedBox(height: AppSpacing.base),
      ],
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: 'Thêm việc',
        icon: Icons.add,
        kind: AppButtonKind.secondary,
        onPressed: () => context.push('/today/add'),
      ),
    ]);
  }

  Widget _nextTaskCard(BuildContext context, TaskItem task) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = _time(task);
    return Semantics(
      button: true,
      label: 'Việc tiếp theo: $time, ${task.title}. Bấm để xem từng việc.',
      child: Material(
        color: AppColors.warningContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: scheme.primary, width: AppSizes.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('s03-next-task'),
          onTap: () => _openFlashcards(widget.data.tasks.indexOf(task)),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: HabitPalette.of(task.habitKey).accent,
                    width: AppSizes.accentBar),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: LayoutBuilder(builder: (context, constraints) {
                final later = Theme(
                  data: Theme.of(context).copyWith(
                    outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 48),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  child: _outlinedAction(
                    context,
                    label: 'Dời lại',
                    icon: AppIcons.later,
                    onPressed: () async {
                      final saved = await runTaskAction(
                        context,
                        task,
                        postpone:
                            ref.read(todayViewModelProvider.notifier).postpone,
                        undo: ref
                            .read(todayViewModelProvider.notifier)
                            .undoLastAction,
                      );
                      if (saved && context.mounted) {
                        context.go('/today?view=main');
                      }
                    },
                  ),
                );
                final information = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      HabitBadge(habitKey: task.habitKey, size: 64),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: Text(time,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant))),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Text(task.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    _S03StatusChip(status: task.status),
                  ],
                );
                if (constraints.maxWidth < 310) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: AppSpacing.md),
                        later,
                      ]);
                }
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(width: 152, child: later),
                    ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _todayTaskCard(BuildContext context, TaskItem task, int index) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: '${_time(task)}, ${task.title}',
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardAll,
            side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('s03-view-task-${task.id}'),
          onTap: () => _openFlashcards(index),
          child: IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                  width: AppSizes.accentBar,
                  color: HabitPalette.of(task.habitKey).accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HabitBadge(habitKey: task.habitKey, size: 64),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_time(task),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(task.title,
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: AppSpacing.md),
                              _S03StatusChip(status: task.status),
                            ])),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _flashcardView(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = widget.data.tasks;
    final task = tasks[_flashIndex];
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        button: true,
        label: 'Quay lại danh sách việc hôm nay',
        child: SizedBox(
          height: AppSizes.minTarget,
          child: TextButton.icon(
            key: const Key('s03-flash-back'),
            onPressed: () => setState(() => _showFlashcards = false),
            icon: const Icon(AppIcons.chevronLeft, size: 40),
            label: const Text('Quay lại'),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        Expanded(
            child: Semantics(
                header: true,
                child: Text('Việc hôm nay',
                    style: theme.textTheme.headlineSmall))),
        Text('Việc ${_flashIndex + 1}/${tasks.length}',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Semantics(
        button: true,
        label: '${task.title}. Bấm để xem chi tiết việc.',
        // Column truyền ràng buộc ngang lỏng; không ép rộng thì Material chỉ
        // ôm nội dung và bị dồn sang trái trên khung web hẹp. Thẻ S03 phải
        // luôn chiếm toàn bộ vùng nội dung như thiết kế flashcard.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() >= 250 && tasks.length > 1) {
              _moveFlashcard(velocity < 0 ? 1 : -1);
            }
          },
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(_flashDirection.toDouble(), 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: SizedBox(
                key: ValueKey('s03-flashcard-page-${task.id}'),
                width: double.infinity,
                child: Material(
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.dialogAll,
                    side: BorderSide(
                        color: scheme.primary, width: AppSizes.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('s03-flashcard'),
                    onTap: () => context.push('/today/task/${task.id}'),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 430),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screen,
                            vertical: AppSpacing.xl),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HabitBadge(habitKey: task.habitKey, size: 128),
                              const SizedBox(height: AppSpacing.lg),
                              Text(_time(task),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          color: scheme.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.lg),
                              Text(task.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium),
                              const SizedBox(height: AppSpacing.lg),
                              _S03StatusChip(status: task.status),
                            ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Center(
          child: Text('Bấm nút để xem việc khác',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant))),
      const SizedBox(height: AppSpacing.lg),
      Row(children: [
        Expanded(
            child: _outlinedAction(context,
                label: 'Việc trước',
                icon: AppIcons.chevronLeft,
                onPressed: tasks.length > 1 ? () => _moveFlashcard(-1) : null)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: _outlinedAction(context,
                label: 'Việc sau',
                icon: AppIcons.arrowRight,
                iconAtEnd: true,
                onPressed: tasks.length > 1 ? () => _moveFlashcard(1) : null)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Semantics(
        label: 'Việc ${_flashIndex + 1} trên ${tasks.length}',
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: AppSpacing.sm,
          children: List.generate(
              tasks.length,
              (index) => Container(
                    key: Key('s03-flash-dot-$index'),
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: index == _flashIndex
                            ? scheme.primary
                            : scheme.outlineVariant,
                        shape: BoxShape.circle),
                  )),
        ),
      ),
    ]);
  }

  Widget _outlinedAction(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback? onPressed,
      bool iconAtEnd = false}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: AppSizes.border)),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!iconAtEnd) Icon(icon, size: AppSizes.icon),
              if (!iconAtEnd) const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
              if (iconAtEnd) const SizedBox(width: AppSpacing.sm),
              if (iconAtEnd) Icon(icon, size: AppSizes.icon),
            ]),
      ),
    );
  }

  void _openFlashcards(int index) => setState(() {
        _flashDirection = index >= _flashIndex ? 1 : -1;
        _flashIndex = index;
        _showFlashcards = true;
      });

  void _moveFlashcard(int delta) => setState(() {
        final length = widget.data.tasks.length;
        _flashDirection = delta >= 0 ? 1 : -1;
        _flashIndex = (_flashIndex + delta + length) % length;
      });
}

class _S03Header extends StatelessWidget {
  const _S03Header(
      {required this.greeting, required this.doneCount, required this.total});
  final String greeting;
  final int doneCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(AppIcons.tabToday, size: 48, color: AppColors.warningStrong),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(greeting, style: theme.textTheme.headlineMedium)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          _TodayHeaderDetail(
            icon: AppIcons.tabWeek,
            label: _todayLabel(),
            color: scheme.onSurfaceVariant,
          ),
          _TodayHeaderDetail(
            icon: AppIcons.checkCircle,
            label: '$doneCount/$total việc',
            color: scheme.primary,
          ),
        ],
      ),
    ]);
  }
}

class _TodayHeaderDetail extends StatelessWidget {
  const _TodayHeaderDetail({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: AppSizes.icon, color: color),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Text(label,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
    ]);
  }
}

class _S03StatusChip extends StatelessWidget {
  const _S03StatusChip({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    if (status != TaskStatus.pending) return TaskStatusChip(status: status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        border:
            Border.all(color: AppColors.warningStrong, width: AppSizes.border),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(AppIcons.radioOff,
            color: AppColors.warningStrong, size: AppSizes.iconInChip),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text('Đang chờ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onWarningContainer,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _AllHandledBanner extends StatelessWidget {
  const _AllHandledBanner({required this.allDone});
  final bool allDone;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: AppRadius.cardAll),
          child: Row(children: [
            Icon(AppIcons.checkCircle,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(
                    allDone
                        ? 'Bác đã xong tất cả việc hôm nay!'
                        : 'Bác đã xử lý hết việc hôm nay.',
                    style: Theme.of(context).textTheme.titleMedium)),
          ]),
        ),
      );
}

String _time(TaskItem task) =>
    formatTimeOfDay(TimeOfDay(hour: task.hour, minute: task.minute),
        wholeHourInWords: true);

String _todayLabel() {
  const weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ nhật'
  ];
  final now = DateTime.now();
  return '${weekdays[now.weekday - 1]}, ${now.day}/${now.month}';
}
