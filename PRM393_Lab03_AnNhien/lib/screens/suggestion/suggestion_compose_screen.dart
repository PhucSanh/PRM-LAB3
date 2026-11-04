import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/suggestion.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/suggestion_compose_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/icon_circle.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/time_field.dart';

/// F12 – chủ: Sanh. Route `/caregiver/suggest` (máy con cháu, ngoài shell của Bác).
/// Một màn, vẽ theo `SuggestionCompose.step`:
/// G01 `52:161` soạn gợi ý · G01b `52:230` hỏi lại trước khi gửi · G02 `56:2` đã gửi.
/// Chưa ghép nối (Figma không vẽ) → `EmptyView` + "Ghép nối máy" (DT-30).
/// Lệch Figma đã được người dùng đồng ý: DT-29 (G01 / G01b), DT-30 (G02, chưa ghép nối).
class SuggestionComposeScreen extends ConsumerStatefulWidget {
  const SuggestionComposeScreen({super.key});

  @override
  ConsumerState<SuggestionComposeScreen> createState() =>
      _SuggestionComposeScreenState();
}

class _SuggestionComposeScreenState
    extends ConsumerState<SuggestionComposeScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Chế độ Con cháu: về màn trước, không có thì về Lịch của mẹ (DT-29).
  void _leave() =>
      context.canPop() ? context.pop() : context.go('/caregiver/schedule');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionComposeViewModelProvider);
    final vm = ref.read(suggestionComposeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBackBar(onBack: _leave),
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang mở gợi ý…'),
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          UiEmpty() =>
            ErrorView(message: 'Chưa mở được gợi ý.', onRetry: vm.load),
          UiData(:final data) => switch (data.step) {
              SuggestionComposeStep.needsPairing => EmptyView(
                  icon: AppIcons.lock,
                  title: 'Chưa ghép nối với máy của mẹ',
                  message: 'Ghép nối trước, rồi mới gửi gợi ý cho mẹ được.',
                  action: AppButton(
                    label: 'Ghép nối máy',
                    icon: AppIcons.arrowRight,
                    onPressed: () => context.go('/caregiver/pair'),
                  ),
                ),
              SuggestionComposeStep.compose ||
              SuggestionComposeStep.confirm =>
                _Compose(
                  data: data,
                  message: _message,
                  onTime: vm.selectTime,
                  onMessage: vm.setMessage,
                  onRequestSend: vm.requestSend,
                  onSend: vm.send,
                  onEdit: vm.editAgain,
                ),
              SuggestionComposeStep.sent => _Sent(
                  data: data,
                  onDone: () => context.go('/caregiver/schedule'),
                ),
            },
        },
      ),
    );
  }
}

/// Nội dung cuộn + thanh đáy ghim. Thanh đáy = phần chữ ([footerInfo], vd. câu hỏi G01b + lỗi)
/// tự cuộn khi chữ lớn + các nút ([actions]) luôn thấy (chữ ×2.0, 360 dp).
class _PinnedFooterLayout extends StatelessWidget {
  const _PinnedFooterLayout(
      {required this.body, required this.actions, this.footerInfo = const []});

  final List<Widget> body;
  final List<Widget> footerInfo;
  final List<Widget> actions;

  static List<Widget> _spaced(List<Widget> children, double gap) => [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          child,
        ],
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spaced(body, AppSpacing.base),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: constraints.maxHeight * 0.75),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.md, AppSpacing.screen, AppSpacing.screen),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (footerInfo.isNotEmpty) ...[
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _spaced(footerInfo, AppSpacing.sm),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ..._spaced(actions, AppSpacing.betweenTargets),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// "Vận động tự nhiên · 20 phút" (thiếu tên thói quen thì chỉ thời lượng).
String _subline(SuggestionCompose data, SuggestionItem item) => [
      if (data.habitNames[item.habitKey] case final name?) name,
      if (item.durationMin case final min?) '$min phút',
    ].join(' · ');

TimeOfDay _tod(SuggestionTime t) => TimeOfDay(hour: t.hour, minute: t.minute);

/// G01 soạn + G01b hỏi lại (cùng phần thân, khác thanh đáy).
class _Compose extends StatelessWidget {
  const _Compose({
    required this.data,
    required this.message,
    required this.onTime,
    required this.onMessage,
    required this.onRequestSend,
    required this.onSend,
    required this.onEdit,
  });

  final SuggestionCompose data;
  final TextEditingController message;
  final void Function(int index, SuggestionTime time) onTime;
  final ValueChanged<String> onMessage;
  final VoidCallback onRequestSend;
  final Future<bool> Function() onSend;
  final VoidCallback onEdit;

  bool get _confirm => data.step == SuggestionComposeStep.confirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _PinnedFooterLayout(
      body: [
        Semantics(
            header: true,
            child: Text('Gợi ý lịch cho mẹ',
                style: theme.textTheme.headlineMedium)),
        Text('Mẹ sẽ tự chọn nhận, đổi giờ hoặc bỏ qua.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        for (final (i, item) in data.items.indexed)
          _ItemCard(
            item: item,
            subline: _subline(data, item),
            // Đang hỏi lại / đang gửi: giữ nguyên lựa chọn, bấm "Sửa lại" mới đổi.
            onTime: _confirm ? null : (t) => onTime(i, t),
          ),
        AppTextField(
          label: 'Lời nhắn gửi kèm (không bắt buộc)',
          hint: 'Mẹ ơi, mai mình đi bộ nhé?',
          controller: message,
          onChanged: onMessage,
          textInputAction: TextInputAction.done,
        ),
        const FieldMessage.hint('Lịch của mẹ chỉ thay đổi khi mẹ bấm nhận.'),
      ],
      footerInfo: _confirm
          ? [
              Semantics(
                header: true,
                child: Text('Gửi gợi ý cho mẹ?',
                    style: theme.textTheme.titleMedium),
              ),
              Text('Lịch của mẹ chỉ cập nhật khi mẹ bấm nhận.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              if (data.sendError != null) FieldMessage.error(data.sendError!),
            ]
          : const [],
      actions: _confirm
          ? [
              AppButton(
                label: data.sendError == null ? 'Gửi gợi ý' : 'Thử lại',
                icon: data.sendError == null
                    ? AppIcons.arrowRight
                    : AppIcons.retry,
                busy: data.sending,
                onPressed: data.sending ? null : () => onSend(),
              ),
              AppButton(
                label: 'Sửa lại',
                icon: AppIcons.pencil,
                kind: AppButtonKind.secondary,
                onPressed: data.sending ? null : onEdit,
              ),
            ]
          : [
              AppButton(
                  label: 'Gửi gợi ý cho mẹ',
                  icon: AppIcons.arrowRight,
                  onPressed: onRequestSend),
            ],
    );
  }
}

/// Thẻ một việc gợi ý: ô icon thói quen + tên việc + "thói quen · phút", rồi các nút giờ
/// (chọn một, xếp dọc – DT-29). [onTime] `null` = chỉ xem (G01b).
class _ItemCard extends StatelessWidget {
  const _ItemCard(
      {required this.item, required this.subline, required this.onTime});

  final SuggestionItem item;
  final String subline;
  final ValueChanged<SuggestionTime>? onTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = item.timeOptions.isEmpty ? [item.time] : item.timeOptions;
    return HabitAccentCard(
      habitKey: item.habitKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HabitBadge(habitKey: item.habitKey),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: theme.textTheme.titleMedium),
              if (subline.isNotEmpty)
                Text(subline,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.base),
        IgnorePointer(
          ignoring: onTime == null,
          child: ChoiceGroup<SuggestionTime>(
            options: [
              for (final t in options)
                ChoiceOption(value: t, label: formatTimeOfDay(_tod(t))),
            ],
            value: item.time,
            onChanged: onTime ?? (_) {},
          ),
        ),
      ]),
    );
  }
}

/// G02 – đã gửi. Lịch của mẹ chưa đổi; việc hiện "Chưa làm".
class _Sent extends StatelessWidget {
  const _Sent({required this.data, required this.onDone});

  final SuggestionCompose data;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final n = data.items.length;
    return _PinnedFooterLayout(
      body: [
        const Center(child: IconCircle(icon: AppIcons.check)),
        // Chip "Mai · Con gái": chưa có quan hệ trong hồ sơ → chỉ tên (DT-30).
        if (data.fromName.isNotEmpty)
          Text(data.fromName,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text('Đã gửi gợi ý cho mẹ',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium),
        ),
        Text('Mẹ sẽ tự chọn nhận, đổi giờ hoặc bỏ qua.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const FieldMessage.hint(
            'Lịch của mẹ chưa thay đổi. Việc chỉ vào lịch khi mẹ bấm nhận.'),
        Text('$n việc gợi ý cho ngày mai', style: theme.textTheme.titleMedium),
        for (final item in data.items)
          TaskRow(
            time: _tod(item.time),
            title: item.title,
            habitKey: item.habitKey,
            note: item.durationMin == null ? null : '${item.durationMin} phút',
          ),
      ],
      actions: [
        AppButton(
            label: 'Về lịch của mẹ',
            icon: AppIcons.arrowRight,
            onPressed: onDone),
      ],
    );
  }
}
