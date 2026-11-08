import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/guided_activity.dart';
import '../../models/task_item.dart';
import '../../viewmodels/task_form_view_model.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/read_aloud_control.dart';

/// Browse at the user's own pace; choosing a card opens the existing time form.
class ActivityFlashcardsScreen extends ConsumerStatefulWidget {
  const ActivityFlashcardsScreen({super.key});

  @override
  ConsumerState<ActivityFlashcardsScreen> createState() =>
      _ActivityFlashcardsScreenState();
}

class _ActivityFlashcardsScreenState
    extends ConsumerState<ActivityFlashcardsScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) => _controller.animateToPage(_index + delta,
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final activity = guidedActivities[_index];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBackBar.adaptive(context),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              Text('Hôm nay Bác muốn làm gì?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Vuốt trái hoặc phải để xem hoạt động.',
                  textAlign: TextAlign.center),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: guidedActivities.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = guidedActivities[index];
                return Card(
                  margin: const EdgeInsets.all(20),
                  color: theme.colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(HabitStyle.iconOf(item.habitKey),
                          size: 80,
                          color: theme.colorScheme.onSecondaryContainer),
                      const SizedBox(height: 24),
                      Text(item.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text('${item.minutes} phút · Theo nhịp của Bác',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 20),
                      Text(item.steps.first,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      ReadAloudControl(
                          text:
                              '${item.title}. ${item.minutes} phút. ${item.steps.first}'),
                      TextButton(
                        onPressed: () =>
                            context.push('/activities/guides/${item.id}'),
                        child: const Text('Xem cách làm'),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                            tooltip: 'Hoạt động trước',
                            onPressed: _index > 0 ? () => _move(-1) : null,
                            icon: const Icon(Icons.arrow_back_rounded)),
                        Semantics(
                            liveRegion: true,
                            child: Text(
                                '${_index + 1} / ${guidedActivities.length}',
                                style: theme.textTheme.titleMedium)),
                        IconButton.filledTonal(
                            tooltip: 'Hoạt động tiếp theo',
                            onPressed: _index < guidedActivities.length - 1
                                ? () => _move(1)
                                : null,
                            icon: const Icon(Icons.arrow_forward_rounded)),
                      ]),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Hôm nay Bác muốn làm'),
                    onPressed: () {
                      ref.read(taskFormViewModelProvider.notifier).startCreate(
                          day: DateUtils.dateOnly(DateTime.now()),
                          activity: activity.habitKey,
                          title: activity.title,
                          durationMinutes: activity.minutes,
                          repeat: RepeatRule.once);
                      context.push('/today/add/time');
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Chọn giờ ở bước tiếp theo để lưu vào lịch.',
                      textAlign: TextAlign.center),
                ]),
          ),
        ]),
      ),
    );
  }
}
