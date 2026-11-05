import 'package:flutter/material.dart';
import '../models/task_item.dart';
import 'habit_widgets.dart';

/// Swipes only stage choices; the parent owns the final server submission.
class SuggestionSwipeDeck extends StatefulWidget {
  const SuggestionSwipeDeck(
      {super.key,
      required this.tasks,
      required this.onChoice,
      required this.onReview,
      this.busy = false});
  final List<TaskItem> tasks;
  final void Function(int index, bool accepted) onChoice;
  final VoidCallback onReview;
  final bool busy;
  @override
  State<SuggestionSwipeDeck> createState() => _SuggestionSwipeDeckState();
}

class _SuggestionSwipeDeckState extends State<SuggestionSwipeDeck> {
  final choices = <bool>[];
  double drag = 0;
  void choose(bool accepted) {
    if (widget.busy || choices.length >= widget.tasks.length) return;
    widget.onChoice(choices.length, accepted);
    setState(() {
      choices.add(accepted);
      drag = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = choices.length == widget.tasks.length;
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          done
              ? 'Đã chọn ${choices.where((v) => v).length} việc'
              : 'Gợi ý ${choices.length + 1}/${widget.tasks.length}',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      LinearProgressIndicator(
          value:
              widget.tasks.isEmpty ? 1 : choices.length / widget.tasks.length,
          borderRadius: BorderRadius.circular(8),
          minHeight: 6),
      const SizedBox(height: 20),
      if (!done) ...[
        const Text('← Bỏ qua     •     Muốn làm →',
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        GestureDetector(
            onHorizontalDragUpdate:
                widget.busy ? null : (d) => setState(() => drag += d.delta.dx),
            onHorizontalDragCancel: () => setState(() => drag = 0),
            onHorizontalDragEnd: widget.busy
                ? null
                : (d) {
                    if (drag.abs() >= 80) {
                      choose(drag > 0);
                    } else {
                      setState(() => drag = 0);
                    }
                  },
            child: Transform.translate(
                offset: Offset(drag.clamp(-100, 100), 0),
                child: Transform.rotate(
                    angle: drag.clamp(-100, 100) / 1800,
                    child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: drag.abs() > 30
                              ? (drag > 0
                                  ? colors.primaryContainer
                                  : colors.errorContainer)
                              : colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(children: [
                          HabitBadge(
                              habitKey: widget.tasks[choices.length].habitKey),
                          const SizedBox(height: 20),
                          Text(widget.tasks[choices.length].title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          Text(
                              '${widget.tasks[choices.length].hour.toString().padLeft(2, '0')}:${widget.tasks[choices.length].minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.titleLarge),
                          if (drag.abs() > 30)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(drag > 0 ? 'Muốn làm' : 'Bỏ qua')),
                        ]))))),
        const SizedBox(height: 20),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                  onPressed: widget.busy ? null : () => choose(false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Bỏ qua việc này')),
              FilledButton.icon(
                  onPressed: widget.busy ? null : () => choose(true),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Muốn làm')),
            ]),
      ],
      if (choices.isNotEmpty)
        TextButton.icon(
            onPressed: widget.busy
                ? null
                : () {
                    widget.onChoice(choices.length - 1, true);
                    setState(() {
                      choices.removeLast();
                      drag = 0;
                    });
                  },
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Hoàn tác lựa chọn')),
      TextButton(
          onPressed: widget.busy ? null : widget.onReview,
          child: const Text('Xem lại lựa chọn')),
    ]);
  }
}
