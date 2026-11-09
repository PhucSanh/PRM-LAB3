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
  const ActivityDiscoveryDeck(
      {super.key, required this.onOpen, this.showHeading = true});
  final ValueChanged<GuidedActivity> onOpen;
  final bool showHeading;
  @override
  ConsumerState<ActivityDiscoveryDeck> createState() =>
      _ActivityDiscoveryDeckState();
}

class _ActivityDiscoveryDeckState extends ConsumerState<ActivityDiscoveryDeck> {
  double _drag = 0;
  String? _interest;

  void _choose(GuidedActivity activity, bool liked) {
    ref.read(activityChoicesProvider.notifier).choose(activity.id, liked);
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final choices = ref.watch(activityChoicesProvider);
    final pool = guidedActivities
        .where((a) => _interest == null || a.interest == _interest)
        .toList();
    final remaining = pool.where((a) => !choices.containsKey(a.id)).toList();
    final interests = guidedActivities.map((a) => a.interest).toSet().toList();
    final liked = guidedActivities.where((a) => choices[a.id] == true).toList();
    final theme = Theme.of(context), colors = theme.colorScheme;
    final activity = remaining.firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.showHeading) ...[
        Text('Tìm một niềm vui hôm nay', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Chọn sở thích của Bác, rồi lưu những hoạt động muốn thử.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final interest in <String?>[null, ...interests])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(interest ?? 'Tất cả'),
                selected: _interest == interest,
                onSelected: (_) => setState(() {
                  _interest = interest;
                  _drag = 0;
                }),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      if (activity != null) ...[
        Text(
            'Gợi ý ${pool.length - remaining.length + 1}/${pool.length} · Đã yêu thích ${liked.length}',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: (pool.length - remaining.length) / pool.length,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4)),
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: _drag.abs() > 30
                          ? (_drag > 0
                              ? colors.primary
                              : colors.onSurfaceVariant)
                          : colors.outlineVariant),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                          height: 160,
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
                                      label: Text(_drag > 0
                                          ? 'YÊU THÍCH ♥'
                                          : 'ĐỂ LÚC KHÁC'))),
                          ])),
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${activity.interest} · ${activity.minutes} phút',
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: 8),
                                ReadAloudRegion(
                                  key: ValueKey(activity.id),
                                  inline: true,
                                  text:
                                      '${activity.title}. ${activity.minutes} phút. ${activity.steps.join('. ')}',
                                  child: Text(activity.title,
                                      style: theme.textTheme.headlineSmall),
                                ),
                                const SizedBox(height: 12),
                                Text(activity.steps.first,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colors.onSurfaceVariant)),
                                const SizedBox(height: 8),
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
        Text('Vuốt trái để bỏ qua · Vuốt phải để yêu thích',
            style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, box) {
          final stacked = MediaQuery.textScalerOf(context).scale(16) > 24;
          final skip = OutlinedButton.icon(
              onPressed: () => _choose(activity, false),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Để lúc khác'));
          final like = FilledButton.icon(
              onPressed: () => _choose(activity, true),
              icon: const Icon(Icons.favorite_border_rounded),
              label: const Text('Yêu thích'));
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [like, const SizedBox(height: 12), skip])
              : Row(children: [
                  Expanded(child: skip),
                  const SizedBox(width: 12),
                  Expanded(child: like)
                ]);
        }),
      ] else ...[
        const Icon(Icons.check_circle_outline_rounded, size: 48),
        const SizedBox(height: 12),
        Text('Đã xem hết nhóm này', style: theme.textTheme.titleLarge),
        Text(
            'Bác có ${liked.length} hoạt động yêu thích. Thử nhóm sở thích khác hoặc mở danh sách bên dưới.'),
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
        Text('Yêu thích của Bác (${liked.length})',
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
