import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/firebase_demo_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

/// F10 extension of N06; the F8 profile editor remains owned by Sanh.
class FirebaseDemoScreen extends ConsumerWidget {
  const FirebaseDemoScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(firebaseDemoViewModelProvider);
    final vm = ref.read(firebaseDemoViewModelProvider.notifier);
    return Scaffold(
        appBar: AppBackBar.adaptive(context),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              Text('Khu thử tính năng',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              AppButton(
                  wrapLabel: true,
                  label: 'Xem thông báo',
                  icon: Icons.notifications_rounded,
                  kind: AppButtonKind.secondary,
                  onPressed: () => context.push('/inbox')),
              const SizedBox(height: AppSpacing.base),
              switch (state) {
                UiLoading() => const LoadingView(),
                UiEmpty() => const EmptyView(
                    icon: Icons.settings_rounded, title: 'Chưa có cài đặt'),
                UiError(:final message) =>
                  ErrorView(message: message, onRetry: vm.refresh),
                UiData(:final data) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nhắc lại: ${data.snooze} phút'),
                        Text('Nhập giọng nói: ${data.voice ? 'Bật' : 'Tắt'}'),
                        Text('Số việc sắp tới: ${data.upcoming}'),
                        const SizedBox(height: AppSpacing.base),
                        AppButton(
                            wrapLabel: true,
                            label: 'Tải lại cài đặt',
                            icon: Icons.refresh_rounded,
                            kind: AppButtonKind.secondary,
                            onPressed: data.busy ? null : vm.refresh),
                        const SizedBox(height: AppSpacing.betweenTargets),
                        AppButton(
                            wrapLabel: true,
                            label: 'Tạo tệp thử',
                            icon: Icons.upload_file_rounded,
                            busy: data.busy,
                            onPressed: vm.export),
                        if (data.progress != null) ...[
                          const SizedBox(height: AppSpacing.base),
                          LinearProgressIndicator(
                              value: data.progress,
                              semanticsLabel: 'Tiến độ tải tệp'),
                        ],
                        if (data.message != null) ...[
                          const SizedBox(height: AppSpacing.base),
                          Semantics(
                              liveRegion: true, child: Text(data.message!)),
                        ],
                        if (data.url != null) ...[
                          const SizedBox(height: AppSpacing.base),
                          const Text('Đường dẫn tải tệp'),
                          SelectableText(data.url!),
                        ],
                        const SizedBox(height: AppSpacing.betweenTargets),
                        AppButton(
                            wrapLabel: true,
                            label: 'Thử lỗi ứng dụng',
                            icon: Icons.bug_report_rounded,
                            kind: AppButtonKind.danger,
                            onPressed: data.busy
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Thử đóng ứng dụng?'),
                                                content: const Text(
                                                    'An Nhiên sẽ đóng. Bác mở lại để gửi báo lỗi.'),
                                                actions: [
                                                  TextButton.icon(
                                                      icon: const Icon(
                                                          Icons.close_rounded),
                                                      label:
                                                          const Text('Ở lại'),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false)),
                                                  TextButton.icon(
                                                      icon: const Icon(Icons
                                                          .bug_report_outlined),
                                                      label: const Text(
                                                          'Thử đóng ứng dụng'),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true)),
                                                ]));
                                    if (confirmed == true && context.mounted) {
                                      await vm.testCrash();
                                    }
                                  }),
                      ]),
              },
            ])));
  }
}
