import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/suggestion.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/suggestion_inbox_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/time_field.dart';

/// F12 – chủ: Sanh. Bọc nội dung `AppShell`: khi [active] (đang ở tab Hôm nay) và có gợi ý `pending`
/// chưa hiện popup → mở popup G10 `66:119` / G11 `71:2` **một lần** (đánh dấu `popupShown` ngay khi
/// hiện). Popup không tự đóng: chạm ra ngoài / Back không đóng, chỉ "Xem gợi ý" hoặc "Để sau".
/// "Xem gợi ý" → `/today/suggestions/<id>?from=popup` (M6: tính 1 chạm); "Để sau" → thẻ G12 trên S03.
class SuggestionPopupListener extends ConsumerStatefulWidget {
  const SuggestionPopupListener(
      {super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  ConsumerState<SuggestionPopupListener> createState() =>
      _SuggestionPopupListenerState();
}

class _SuggestionPopupListenerState
    extends ConsumerState<SuggestionPopupListener> {
  /// Gợi ý đã hiện popup trong phiên này (chặn hiện lại khi dữ liệu chưa kịp cập nhật).
  final _shown = <String>{};
  bool _open = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
        suggestionInboxViewModelProvider, (_, next) => _maybeShow(next),
        fireImmediately: true);
  }

  @override
  void didUpdateWidget(SuggestionPopupListener old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _maybeShow(ref.read(suggestionInboxViewModelProvider));
    }
  }

  void _maybeShow(UiState<SuggestionInbox> state) {
    if (!widget.active || _open) return;
    final inbox = switch (state) { UiData(:final data) => data, _ => null };
    final s = inbox?.popupToShow;
    if (inbox == null || s == null || _shown.contains(s.id)) return;
    _shown.add(s.id);
    _open = true;
    // Mở sau khung hình hiện tại (có thể đang trong lúc build / listen).
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(inbox, s));
  }

  Future<void> _show(SuggestionInbox inbox, Suggestion s) async {
    if (!mounted) return;
    final vm = ref.read(suggestionInboxViewModelProvider.notifier);
    // Hiện là đánh dấu ngay: mở lại app không hiện lại.
    vm.markPopupShown(s.id);
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
          canPop: false, child: SuggestionPopup(inbox: inbox, suggestion: s)),
    );
    _open = false;
    if (!mounted) return;
    if (open == true) {
      context.push('/today/suggestions/${s.id}?from=popup');
    } else {
      await vm.later(s.id);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Nội dung popup G10 / G11, ghép từ `ConfirmDialog` (F0): vòng icon thư, "Mai gửi lịch cho Bác",
/// ["Mai vừa gửi lúc 4:20 chiều" – chỉ khi gửi hôm nay], "2 việc cho ngày mai", bong bóng lời nhắn,
/// "Chưa thêm vào lịch. Bác tự chọn.", nút "Xem gợi ý" (chính) + "Để sau" (viền) xếp dọc. DT-33.
class SuggestionPopup extends StatelessWidget {
  const SuggestionPopup(
      {super.key, required this.inbox, required this.suggestion});

  final SuggestionInbox inbox;
  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = suggestion;
    final sub =
        theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant);
    Widget line(String text, TextStyle? style) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(text, style: style, textAlign: TextAlign.center),
        );
    return ConfirmDialog<bool>(
      icon: AppIcons.suggestion,
      title: '${s.fromName} gửi lịch cho Bác',
      details: [
        if (inbox.sentToday(s))
          line(
              '${s.fromName} vừa gửi lúc '
              '${formatTimeOfDay(TimeOfDay(hour: s.createdAt.hour, minute: s.createdAt.minute))}',
              sub),
        line('${s.items.length} việc cho ${inbox.dayLabel(s)}',
            theme.textTheme.bodyLarge),
        if (s.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: AppRadius.cardAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Text(s.message,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        line(
            'Chưa thêm vào lịch. Bác tự chọn.',
            theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
      options: const [
        ConfirmOption(
            label: 'Xem gợi ý',
            icon: AppIcons.view,
            value: true,
            kind: AppButtonKind.primary),
        ConfirmOption(label: 'Để sau', icon: AppIcons.later, value: false),
      ],
    );
  }
}
