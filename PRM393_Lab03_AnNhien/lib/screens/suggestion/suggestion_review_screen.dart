import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/suggestion.dart';
import '../../models/task_item.dart' show TaskStatus, dateKey;
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/suggestion_review_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/velora_parts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/read_aloud_button.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/time_field.dart';

/// F12 – chủ: Sanh. Route `/today/suggestions/:id?from=popup|card|push|family` (trong shell của Bác).
/// Một màn, vẽ theo `SuggestionReview.step`:
/// G03 `56:107` / G03b `56:201` xem gợi ý · G04 `57:2` đổi giờ (toàn trang) · G05 `57:128` / G05b `58:2` đã nhận ·
/// G06 `58:117` chọn từng việc · G07 `61:2` / G07b `61:118` đã nhận một phần · G09 `66:2` đã bỏ qua.
/// Lệch Figma đã được người dùng đồng ý: DT-31, DT-32.
class SuggestionReviewScreen extends ConsumerWidget {
  const SuggestionReviewScreen(
      {super.key, required this.id, this.entry = SuggestionEntry.direct});

  final String id;
  final SuggestionEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = suggestionReviewViewModelProvider((id: id, entry: entry));
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final fromFamily = entry == SuggestionEntry.family;

    /// Mở từ Gia đình → về Gia đình (chữ Figma); nơi khác → về Hôm nay (DT-31).
    void leave() => context.go(fromFamily ? '/family' : '/today');

    // Màn kết quả (G05 / G07 / G09) ghi "Quay lại Gia đình", màn xem / chọn ghi "Gia đình".
    final result = switch (state) {
      UiData(:final data) => const {
          SuggestionReviewStep.accepted,
          SuggestionReviewStep.acceptedPartial,
          SuggestionReviewStep.dismissed,
        }.contains(data.step),
      _ => false,
    };
    final backLabel =
        fromFamily ? (result ? 'Quay lại Gia đình' : 'Gia đình') : 'Quay lại';

    return Scaffold(
      appBar: AppBackBar.adaptive(context, backLabel: backLabel, onBack: leave),
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang mở gợi ý…'),
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          UiEmpty() => EmptyView(
              icon: AppIcons.suggestion,
              title: 'Gợi ý này không còn',
              message: 'Có thể Bác đã nhận rồi, hoặc gợi ý đã bị xoá.',
              action: AppButton(
                  label: 'Về Hôm nay',
                  icon: AppIcons.tabToday,
                  onPressed: () => context.go('/today')),
            ),
          UiData(:final data) => switch (data.step) {
              SuggestionReviewStep.changingTime =>
                _ChangeTime(data: data, vm: vm),
              SuggestionReviewStep.accepted ||
              SuggestionReviewStep.acceptedPartial =>
                _Accepted(
                  data: data,
                  fromFamily: fromFamily,
                  onViewDay: () => context
                      .go('/week/${dateKey(data.suggestion.items.first.date)}'),
                  onHome: leave,
                ),
              SuggestionReviewStep.choosing => _Choose(data: data, vm: vm),
              SuggestionReviewStep.dismissed => _Dismissed(
                  data: data, vm: vm, fromFamily: fromFamily, onHome: leave),
              SuggestionReviewStep.reviewing => _Review(data: data, vm: vm),
            },
        },
      ),
    );
  }
}

/// Nội dung, lỗi và hành động phụ cuộn cùng nhau; chỉ ghim CTA chính để
/// chữ lớn vẫn còn không gian đọc và thao tác. Bottom nav do shell vẽ.
class _Layout extends StatelessWidget {
  const _Layout(
      {required this.body,
      required this.primary,
      this.secondary = const [],
      this.error,
      this.errorHint});

  final List<Widget> body;
  final Widget primary;
  final List<Widget> secondary;
  final String? error;

  /// Câu "Ví dụ: …" dưới câu lỗi (G06 chưa chọn việc).
  final String? errorHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Expanded(
        child: VeloraDetailBody(children: [
          for (final (i, child) in [...body, ...secondary].indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.betweenTargets),
            child,
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.error(error!),
            if (errorHint != null) FieldMessage.hint(errorHint!),
          ],
        ]),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen, vertical: AppSpacing.md),
          child: primary,
        ),
      ),
    ]);
  }
}

TimeOfDay _tod(SuggestionTime t) => TimeOfDay(hour: t.hour, minute: t.minute);

/// "đi bộ nhẹ nhàng" – tên việc viết thường để ghép vào câu ("Đổi giờ đi bộ nhẹ nhàng").
String _lower(String title) =>
    title.isEmpty ? title : title[0].toLowerCase() + title.substring(1);

/// Thẻ trích dẫn (Figma quote-card): tên người gửi + quan hệ + lời nhắn nghiêng.
/// Ghép từ F0 (`FieldLabel`), không có avatar chữ cái (DT-31).
class _Quote extends StatelessWidget {
  const _Quote(this.s);
  final Suggestion s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.cardAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FieldLabel(s.fromName, icon: AppIcons.user),
          if (s.fromRelation != null)
            Text(s.fromRelation!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          if (s.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(s.message,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ]),
      ),
    );
  }
}

/// Phần đầu chung của G03 / G03b / G04: tiêu đề, trích dẫn, "Đọc to", "N việc gợi ý".
List<Widget> _head(BuildContext context, SuggestionReview data, String title) {
  final theme = Theme.of(context);
  return [
    Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.headlineMedium)),
    _Quote(data.suggestion),
    // TODO(F5 – Khang): nối SpeechService để đọc to; chưa có TTS nên nút tạm tắt (DT-31).
    const ReadAloudButton(onPressed: null),
    Text('${data.remaining.length} việc gợi ý',
        style: theme.textTheme.titleMedium),
  ];
}

/// Thẻ một việc gợi ý (G03 / G04): `TaskRow` với giờ Bác đã chọn, chip "Chưa làm", dòng "20 phút".
Widget _itemRow(SuggestionReview data, int i) {
  final item = data.suggestion.items[i];
  return TaskRow(
    time: _tod(data.times[i]),
    title: item.title,
    habitKey: item.habitKey,
    note: item.durationMin == null ? null : '${item.durationMin} phút',
  );
}

/// G03 / G03b.
class _Review extends StatelessWidget {
  const _Review({required this.data, required this.vm});
  final SuggestionReview data;
  final SuggestionReviewViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = data.suggestion;
    final changed = data.changedIndex;
    final changeable = data.changeableIndex;
    return _Layout(
      body: [
        ..._head(context, data, '${s.fromName} gửi lịch cho Bác'),
        for (final i in data.remaining) _itemRow(data, i),
        FieldMessage.hint(changed == null
            ? 'Chưa thêm vào lịch. Bác tự chọn.'
            : 'Bác đã chọn giờ ${_lower(s.items[changed].title)}. Chưa thêm vào lịch.'),
      ],
      error: data.actionError,
      primary: AppButton(
        label: data.actionError == null ? 'Thêm vào lịch' : 'Thử lại',
        icon: data.actionError == null ? AppIcons.check : AppIcons.retry,
        busy: data.busy,
        onPressed: data.busy ? null : () => vm.acceptAll(),
      ),
      secondary: [
        if (changeable != null)
          AppButton(
            label: 'Đổi giờ ${_lower(s.items[changeable].title)}',
            icon: AppIcons.later,
            kind: AppButtonKind.secondary,
            wrapLabel: true,
            onPressed: data.busy ? null : () => vm.startChangeTime(changeable),
          ),
        AppButton(
          label: 'Chọn từng việc',
          icon: AppIcons.square,
          kind: AppButtonKind.secondary,
          onPressed: data.busy ? null : vm.startChoosing,
        ),
        AppButton(
          label: 'Bỏ qua gợi ý',
          icon: AppIcons.skipToday,
          kind: AppButtonKind.text,
          onPressed: data.busy ? null : () => vm.dismiss(),
        ),
      ],
    );
  }
}

/// G04 – đổi giờ một việc, state toàn trang (không phải hộp thoại).
class _ChangeTime extends StatelessWidget {
  const _ChangeTime({required this.data, required this.vm});
  final SuggestionReview data;
  final SuggestionReviewViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final edit = data.editIndex!;
    final item = data.suggestion.items[edit];
    final name = _lower(item.title);
    return _Layout(
      body: [
        ..._head(context, data, 'Đổi giờ $name'),
        for (final i in data.remaining) ...[
          _itemRow(data, i),
          if (i == edit) ...[
            Text('Chọn giờ $name:', style: theme.textTheme.titleSmall),
            ChoiceGroup<SuggestionTime>(
              options: [
                for (final t in item.timeOptions)
                  ChoiceOption(value: t, label: formatTimeOfDay(_tod(t))),
              ],
              value: data.pendingTime,
              onChanged: vm.pickTime,
            ),
          ],
        ],
        const FieldMessage.hint(
            'Chưa đổi trên máy của Bác. Lịch chỉ thay đổi khi Bác bấm Lưu giờ mới.'),
      ],
      primary: AppButton(
          label: 'Lưu giờ mới', icon: AppIcons.save, onPressed: vm.saveNewTime),
      secondary: [
        AppButton(
          label: 'Quay lại',
          icon: AppIcons.chevronLeft,
          kind: AppButtonKind.secondary,
          onPressed: vm.cancelChangeTime,
        ),
      ],
    );
  }
}

/// G05 / G05b – đã thêm vào lịch hết; G07 / G07b – đã nhận một phần (việc còn lại ghi "Gợi ý của …").
class _Accepted extends StatelessWidget {
  const _Accepted(
      {required this.data,
      required this.fromFamily,
      required this.onViewDay,
      required this.onHome});

  final SuggestionReview data;
  final bool fromFamily;
  final VoidCallback onViewDay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = data.suggestion;
    final n = data.acceptedNow.length;
    return _Layout(
      body: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text('Đã thêm vào lịch',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium),
        ),
        Text('$n việc của ${s.fromName} đã vào lịch ${data.dayLabel}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant)),
        // TODO(F5 – Khang): nối SpeechService (DT-31).
        const ReadAloudButton(onPressed: null),
        Text('$n việc đã nhận', style: theme.textTheme.titleMedium),
        for (final i in data.acceptedNow)
          TaskRow(
            time: _tod(data.times[i]),
            title: s.items[i].title,
            habitKey: s.items[i].habitKey,
            note: [
              HabitStyle.nameOf(s.items[i].habitKey),
              if (s.items[i].durationMin case final min?) '$min phút',
            ].join(' · '),
          ),
        // G07 / G07b: việc chưa nhận, nhận tiếp từ Gia đình (DT-32).
        for (final i in data.remaining)
          _SuggestedRow(
            item: s.items[i],
            time: data.times[i],
            fromName: s.fromName,
          ),
        if (data.remaining.isNotEmpty)
          const FieldMessage.hint(
              'Chưa thêm vào lịch. Bác có thể thêm sau trong Gia đình.'),
        if (data.acceptedWithChangedTime || data.remaining.isNotEmpty)
          const FieldMessage.hint('Bác có thể đổi giờ hoặc ngưng nhắc.'),
      ],
      primary: AppButton(
        label: 'Xem lịch ${data.dayLabel}',
        icon: AppIcons.tabWeek,
        wrapLabel: true,
        onPressed: onViewDay,
      ),
      secondary: [
        AppButton(
          label: fromFamily ? 'Về Gia đình' : 'Về Hôm nay',
          icon: fromFamily ? AppIcons.tabFamily : AppIcons.tabToday,
          kind: AppButtonKind.secondary,
          onPressed: onHome,
        ),
      ],
    );
  }
}

/// "8:00 sáng · 20 phút".
String _timeLine(SuggestionItem item, SuggestionTime time) => [
      formatTimeOfDay(_tod(time)),
      if (item.durationMin case final min?) '$min phút',
    ].join(' · ');

/// G07 / G07b: việc chưa nhận – thẻ vạch màu + ô icon + tên + "Gợi ý của Mai · 9:00 sáng · 15 phút".
/// Không có chip "Gợi ý của Mai" / viền nét đứt trong F0 (DT-32).
class _SuggestedRow extends StatelessWidget {
  const _SuggestedRow(
      {required this.item, required this.time, required this.fromName});

  final SuggestionItem item;
  final SuggestionTime time;
  final String fromName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = 'Gợi ý của $fromName · ${_timeLine(item, time)}';
    return Semantics(
      container: true,
      label: '${item.title}. $note. Chưa thêm vào lịch.',
      excludeSemantics: true,
      child: HabitAccentCard(
        habitKey: item.habitKey,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HabitBadge(habitKey: item.habitKey),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: theme.textTheme.titleMedium),
              Text(note,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// G06 – chọn từng việc (chọn nhiều, mặc định chọn hết). Mỗi thẻ là `HabitTile` có dấu chọn +
/// chữ "Đã chọn" / "Chọn" (không chỉ dựa vào màu), cao ≥ 72.
class _Choose extends StatelessWidget {
  const _Choose({required this.data, required this.vm});
  final SuggestionReview data;
  final SuggestionReviewViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = data.suggestion;
    final first = data.remaining.isEmpty ? null : s.items[data.remaining.first];
    return _Layout(
      body: [
        Semantics(
            header: true,
            child:
                Text('Chọn từng việc', style: theme.textTheme.headlineMedium)),
        _Quote(s),
        // TODO(F5 – Khang): nối SpeechService (DT-31).
        const ReadAloudButton(onPressed: null),
        Text('Bác muốn nhận việc nào?', style: theme.textTheme.titleMedium),
        for (final i in data.remaining)
          HabitTile(
            habitKey: s.items[i].habitKey,
            name: s.items[i].title,
            description: formatTimeOfDay(_tod(data.times[i])),
            selected: data.selected.contains(i),
            onTap: data.busy ? null : () => vm.toggle(i),
          ),
        // Figma: "…sau khi Bác xác nhận ở bước tiếp theo." – không có bước đó, "Tiếp tục" lưu luôn (DT-32).
        const FieldMessage.hint(
            'Chưa thêm vào lịch của Bác. Lịch chỉ thay đổi khi Bác bấm Tiếp tục.'),
        AppButton(
          label: 'Quay lại',
          icon: AppIcons.chevronLeft,
          kind: AppButtonKind.text,
          onPressed: data.busy ? null : vm.backToReview,
        ),
      ],
      error: data.needSelection ? 'Bác chưa chọn việc nào.' : data.actionError,
      errorHint: data.needSelection && first != null
          ? 'Ví dụ: chạm vào “${first.title}” ở trên.'
          : null,
      primary: AppButton(
        label: data.actionError == null ? 'Tiếp tục' : 'Thử lại',
        icon: data.actionError == null ? AppIcons.arrowRight : AppIcons.retry,
        busy: data.busy,
        onPressed: data.busy ? null : () => vm.continueChoosing(),
      ),
    );
  }
}

/// G09 – đã bỏ qua: màn kết quả toàn trang, nút chính "Hoàn tác" (không có snackbar – DT-32).
class _Dismissed extends StatelessWidget {
  const _Dismissed(
      {required this.data,
      required this.vm,
      required this.fromFamily,
      required this.onHome});

  final SuggestionReview data;
  final SuggestionReviewViewModel vm;
  final bool fromFamily;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = data.suggestion;
    final n = data.remaining.length;
    return _Layout(
      body: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text('Đã bỏ qua gợi ý',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium),
        ),
        Text('Chưa việc nào của ${s.fromName} vào lịch ${data.dayLabel}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant)),
        // TODO(F5 – Khang): nối SpeechService (DT-31).
        const ReadAloudButton(onPressed: null),
        Text('$n việc đã bỏ qua', style: theme.textTheme.titleMedium),
        for (final i in data.remaining)
          TaskRow(
            time: _tod(data.times[i]),
            title: s.items[i].title,
            habitKey: s.items[i].habitKey,
            status: TaskStatus.skipped,
            note: s.items[i].durationMin == null
                ? null
                : '${s.items[i].durationMin} phút',
          ),
        const FieldMessage.hint(
            'Bác có thể xem lại gợi ý bất cứ lúc nào trong Gia đình.'),
      ],
      error: data.actionError,
      primary: AppButton(
        label: 'Hoàn tác',
        icon: AppIcons.retry,
        busy: data.busy,
        onPressed: data.busy ? null : () => vm.undoDismiss(),
      ),
      secondary: [
        AppButton(
          label: fromFamily ? 'Về Gia đình' : 'Về Hôm nay',
          icon: fromFamily ? AppIcons.tabFamily : AppIcons.tabToday,
          kind: AppButtonKind.secondary,
          onPressed: data.busy ? null : onHome,
        ),
      ],
    );
  }
}
