import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guided_activity.dart';
import '../models/habit_guide.dart';
import 'habit_widgets.dart';
import 'read_aloud_region.dart';

class _ActivityChoices extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};
  void choose(String id, bool liked) => state = {...state, id: liked};
  void undo(String id) => state = {...state}..remove(id);
  void reset() => state = {};
}

final activityChoicesProvider =
    NotifierProvider<_ActivityChoices, Map<String, bool>>(_ActivityChoices.new);

/// Likes stay available across tab navigation; only an explicit schedule action
/// on the activity detail screen creates a task.
class ActivityDiscoveryDeck extends ConsumerStatefulWidget {
  const ActivityDiscoveryDeck({super.key, required this.onOpen});
  final ValueChanged<GuidedActivity> onOpen;
  @override
  ConsumerState<ActivityDiscoveryDeck> createState() =>
      _ActivityDiscoveryDeckState();
}

class _ActivityDiscoveryDeckState extends ConsumerState<ActivityDiscoveryDeck> {
  double _drag = 0;

  void _choose(GuidedActivity activity, bool liked) {
    ref.read(activityChoicesProvider.notifier).choose(activity.id, liked);
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final choices = ref.watch(activityChoicesProvider);
    final remaining =
        guidedActivities.where((a) => !choices.containsKey(a.id)).toList();
    final liked = guidedActivities.where((a) => choices[a.id] == true).toList();
    final theme = Theme.of(context), colors = theme.colorScheme;
    final activity = remaining.firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Hôm nay, bạn thích làm gì?', style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('Trái: bỏ qua · Phải: thích', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      if (activity != null) ...[
        Text(
            '${choices.length + 1} / ${guidedActivities.length} hoạt động · Đã thích ${liked.length}',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 16),
        Stack(children: [
          Positioned.fill(
            top: 12,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              key: const Key('activity-swipe-card'),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _drag += d.delta.dx),
              onHorizontalDragCancel: () => setState(() => _drag = 0),
              onHorizontalDragEnd: (d) {
                final velocity = d.primaryVelocity ?? 0;
                if (_drag.abs() > 72 || velocity.abs() > 600) {
                  _choose(
                      activity, _drag.abs() > 72 ? _drag > 0 : velocity > 0);
                } else {
                  setState(() => _drag = 0);
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: _drag == 0 ? 180 : 0),
                transformAlignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translateByDouble(_drag.clamp(-140, 140), 0, 0, 1)
                  ..rotateZ(_drag.clamp(-140, 140) / 1600),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: _drag.abs() > 30
                          ? (_drag > 0 ? colors.primary : colors.error)
                          : colors.outlineVariant),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                          height: 120,
                          child: Stack(fit: StackFit.expand, children: [
                            Image.asset(habitPhotosOf(activity.habitKey).first,
                                fit: BoxFit.cover,
                                excludeFromSemantics: true,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                    color: colors.primaryContainer,
                                    child: Icon(
                                        HabitStyle.iconOf(activity.habitKey),
                                        size: 64,
                                        color: colors.primary))),
                            if (_drag.abs() > 30)
                              Center(
                                  child: Chip(
                                      label: Text(
                                          _drag > 0 ? 'THÍCH ♥' : 'BỎ QUA'))),
                          ])),
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${HabitStyle.nameOf(activity.habitKey)} · ${activity.minutes} phút',
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: 8),
                                ReadAloudRegion(
                                  key: ValueKey(activity.id),
                                  inline: true,
                                  text:
                                      '${activity.title}. ${activity.minutes} phút. ${activity.steps.join('. ')}',
                                  child: Text(activity.title,
                                      style: theme.textTheme.titleLarge),
                                ),
                                TextButton(
                                    onPressed: () => widget.onOpen(activity),
                                    child: const Text('Xem cách làm →')),
                              ])),
                    ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => _choose(activity, false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Bỏ qua'))),
          const SizedBox(width: 12),
          Expanded(
              child: FilledButton.icon(
                  onPressed: () => _choose(activity, true),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Thích'))),
        ]),
      ] else ...[
        const Icon(Icons.check_circle_outline_rounded, size: 48),
        const SizedBox(height: 12),
        Text('Đã xem hết gợi ý', style: theme.textTheme.titleLarge),
        Text(
            'Bạn đã thích ${liked.length} hoạt động. Chọn bên dưới để xem cách làm hoặc thêm vào lịch.'),
        TextButton(
            onPressed: () => ref.read(activityChoicesProvider.notifier).reset(),
            child: const Text('Khám phá lại')),
      ],
      if (choices.isNotEmpty)
        TextButton.icon(
            onPressed: () {
              ref
                  .read(activityChoicesProvider.notifier)
                  .undo(choices.keys.last);
              setState(() => _drag = 0);
            },
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Hoàn tác')),
      if (liked.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Hoạt động đã thích (${liked.length})',
            style: theme.textTheme.titleMedium),
        for (final item in liked)
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.title),
              subtitle: Text('${item.minutes} phút · Xem và thêm vào lịch'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => widget.onOpen(item)),
      ],
    ]);
  }
}
