import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/suggestion_demo_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/caregiver_parts.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';
import '../../widgets/time_field.dart';
import '../../widgets/undo_snackbar.dart';

/// Khu demo backend F10 cho Hiếu nghiệm thu dịch vụ F12; màn G01–G12 do Sanh làm.
class SuggestionDemoScreen extends ConsumerStatefulWidget {
  const SuggestionDemoScreen({super.key});
  @override
  ConsumerState<SuggestionDemoScreen> createState() =>
      _SuggestionDemoScreenState();
}

class _SuggestionDemoScreenState extends ConsumerState<SuggestionDemoScreen> {
  final excluded = <String, Set<int>>{};
  final times = <String, Map<int, ({int hour, int minute})>>{};
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(suggestionDemoViewModelProvider),
        vm = ref.read(suggestionDemoViewModelProvider.notifier);
    return CaregiverPage(
        title: 'Lịch người thân gợi ý',
        onBack: () => context.go('/account'),
        children: [
          const Text(
              'Bác chọn việc muốn nhận. Chỉ việc Bác chọn mới được thêm vào lịch.'),
          if (s.message != null) FieldMessage.error(s.message!),
          ref.watch(pendingSuggestionsProvider).when(
                loading: () => const LoadingView(),
                error: (e, st) => ErrorView(
                    message: 'Chưa tải được gợi ý.',
                    onRetry: () => ref.invalidate(pendingSuggestionsProvider)),
                data: (list) => list.isEmpty
                    ? const EmptyView(
                        icon: Icons.event_available, title: 'Chưa có gợi ý mới')
                    : Column(children: [
                        for (final suggestion in list)
                          CaregiverInfoCard(children: [
                            if (suggestion.message.isNotEmpty)
                              Text(suggestion.message),
                            for (final (index, t)
                                in suggestion.tasks.indexed) ...[
                              CheckboxListTile(
                                  value: !(excluded[suggestion.id]
                                          ?.contains(index) ??
                                      false),
                                  title: Text(t.title),
                                  onChanged: s.busy
                                      ? null
                                      : (v) => setState(() {
                                            final set = excluded.putIfAbsent(
                                                suggestion.id, () => {});
                                            v == true
                                                ? set.remove(index)
                                                : set.add(index);
                                          })),
                              TimeField(
                                  label: 'Giờ của ${t.title}',
                                  value: TimeOfDay(
                                      hour:
                                          times[suggestion.id]?[index]?.hour ??
                                              t.hour,
                                      minute: times[suggestion.id]?[index]
                                              ?.minute ??
                                          t.minute),
                                  onChanged: (time) => setState(() =>
                                      times.putIfAbsent(
                                          suggestion.id, () => {})[index] = (
                                        hour: time.hour,
                                        minute: time.minute
                                      ))),
                            ],
                            AppButton(
                                label: 'Thêm việc đã chọn vào lịch',
                                icon: Icons.check,
                                wrapLabel: true,
                                busy: s.busy,
                                onPressed: () async {
                                  final selected = List.generate(
                                          suggestion.tasks.length, (i) => i)
                                      .where((i) => !(excluded[suggestion.id]
                                              ?.contains(i) ??
                                          false))
                                      .toList();
                                  if (selected.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Bác chọn ít nhất một việc hoặc bấm Bỏ qua nhé.')));
                                    return;
                                  }
                                  final overrides = {
                                    for (final e in (times[suggestion.id] ??
                                            <int, ({int hour, int minute})>{})
                                        .entries)
                                      if (selected.contains(e.key))
                                        e.key: e.value
                                  };
                                  final ok = await vm.resolve(
                                      suggestion.id, selected,
                                      times: overrides);
                                  if (ok && context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Đã thêm việc Bác chọn vào lịch.')));
                                }),
                            AppButton(
                                label: 'Bỏ qua',
                                icon: Icons.close,
                                kind: AppButtonKind.secondary,
                                wrapLabel: true,
                                onPressed: s.busy
                                    ? null
                                    : () async {
                                        if (await vm
                                                .resolve(suggestion.id, []) &&
                                            context.mounted)
                                          showUndoSnackbar(context,
                                              title: 'Đã bỏ qua gợi ý.',
                                              onUndo: () =>
                                                  vm.undo(suggestion.id));
                                      }),
                          ])
                      ]),
              ),
        ]);
  }
}
