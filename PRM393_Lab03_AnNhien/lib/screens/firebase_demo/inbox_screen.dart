import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_notification.dart';
import '../../models/notification_target.dart';
import '../../viewmodels/inbox_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  NotificationKind? _filter;
  String? _opening;

  Future<void> _open(AppNotification item) async {
    if (_opening != null) return;
    setState(() => _opening = item.id);
    try {
      final vm = ref.read(inboxViewModelProvider.notifier);
      if (notificationTarget(item.route) == '/inbox') {
        final saved = await vm.markRead(item);
        if (!saved && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Chưa đánh dấu được. Bạn thử lại nhé.')));
        }
        return;
      }
      final route = await vm.open(item);
      if (mounted && route != '/inbox') await context.push(route);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxViewModelProvider);
    final vm = ref.read(inboxViewModelProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBackBar(onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/today');
        }
      }),
      body: SafeArea(
          child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text('Hộp thông báo', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text('Cập nhật từ gia đình và An Nhiên, cùng ở một nơi.'),
          const SizedBox(height: AppSpacing.base),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            for (final entry in const <NotificationKind?, String>{
              null: 'Tất cả',
              NotificationKind.family: 'Gia đình',
              NotificationKind.system: 'Hệ thống'
            }.entries)
              FilterChip(
                  label: Text(entry.value),
                  selected: _filter == entry.key,
                  side: BorderSide(
                      color: _filter == entry.key
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant),
                  onSelected: (_) => setState(() => _filter = entry.key)),
          ]),
          const SizedBox(height: AppSpacing.base),
          switch (state) {
            UiLoading() => const LoadingView(),
            UiEmpty() => const EmptyView(
                icon: Icons.notifications_none_rounded,
                title: 'Chưa có thông báo'),
            UiError(:final message) =>
              ErrorView(message: message, onRetry: vm.retry),
            UiData(:final data) => _list(data),
          },
          const SizedBox(height: AppSpacing.lg),
          AppButton(
              label: 'Bật thông báo',
              icon: Icons.notifications_active_rounded,
              kind: AppButtonKind.secondary,
              wrapLabel: true,
              onPressed: () async {
                final message = await vm.permission();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                }
              }),
          const SizedBox(height: AppSpacing.lg),
        ],
      )),
    );
  }

  Widget _list(List<AppNotification> data) {
    final items =
        data.where((item) => _filter == null || item.kind == _filter).toList();
    if (items.isEmpty) {
      return const EmptyView(
          icon: Icons.notifications_none_rounded,
          title: 'Nhóm này chưa có thông báo');
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.base),
          child: Card(
              child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                            item.kind == NotificationKind.family
                                ? Icons.family_restroom_rounded
                                : Icons.notifications_rounded,
                            color: scheme.primary,
                            size: AppSizes.icon),
                        Text(
                            item.kind == NotificationKind.family
                                ? 'Gia đình'
                                : item.kind == NotificationKind.reminder
                                    ? 'Lời nhắc'
                                    : 'Hệ thống',
                            style: theme.textTheme.labelMedium),
                        if (!item.isRead)
                          Text('• Chưa đọc',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: scheme.primary)),
                      ]),
                  const SizedBox(height: AppSpacing.md),
                  Text(item.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(item.body),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                      '${item.receivedAt.day}/${item.receivedAt.month}/${item.receivedAt.year} · ${item.receivedAt.hour.toString().padLeft(2, '0')}:${item.receivedAt.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.base),
                  if (notificationTarget(item.route) != '/inbox' ||
                      !item.isRead)
                    AppButton(
                        label: notificationTarget(item.route) == '/inbox'
                            ? 'Đánh dấu đã đọc'
                            : 'Xem thông báo',
                        icon: Icons.mark_email_read_rounded,
                        kind: AppButtonKind.tonal,
                        wrapLabel: true,
                        busy: _opening == item.id,
                        onPressed: _opening != null ? null : () => _open(item)),
                ]),
          )),
        ),
    ]);
  }
}
