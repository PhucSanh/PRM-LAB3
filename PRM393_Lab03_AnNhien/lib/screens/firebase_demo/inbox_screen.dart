import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/inbox_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxViewModelProvider);
    final vm = ref.read(inboxViewModelProvider.notifier);
    return Scaffold(
        appBar: const AppBackBar(),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              Text('Hộp thông báo',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              AppButton(
                  wrapLabel: true,
                  label: 'Bật thông báo',
                  icon: Icons.notifications_active_outlined,
                  kind: AppButtonKind.secondary,
                  onPressed: () async {
                    final message = await vm.permission();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    }
                  }),
              const SizedBox(height: AppSpacing.base),
              switch (state) {
                UiLoading() => const LoadingView(),
                UiEmpty() => const EmptyView(
                    icon: Icons.notifications_none, title: 'Chưa có thông báo'),
                UiError(:final message) =>
                  ErrorView(message: message, onRetry: vm.retry),
                UiData(:final data) => Column(
                    children: data
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.base),
                              child: Card(
                                  child: Padding(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.base),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge),
                                            Text(item.body),
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                            AppButton(
                                                wrapLabel: true,
                                                label: 'Xem thông báo',
                                                icon: Icons.open_in_new,
                                                kind: AppButtonKind.secondary,
                                                onPressed: () async {
                                                  final route =
                                                      await vm.open(item);
                                                  if (context.mounted &&
                                                      route != '/inbox') {
                                                    context.push(route);
                                                  }
                                                }),
                                          ]))),
                            ))
                        .toList()),
              },
            ])));
  }
}
