import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/reminder_settings_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/switch_row.dart';

/// N07 – cài đặt lời nhắc. Các thay đổi lưu ngay qua SettingsService.
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderSettingsViewModelProvider);
    final vm = ref.read(reminderSettingsViewModelProvider.notifier);
    return Scaffold(
      appBar: const AppBackBar(),
      body: SafeArea(
        top: false,
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải cài đặt nhắc việc…'),
          UiEmpty() => const SizedBox.shrink(),
          UiError(:final message) => ErrorView(message: message, onRetry: vm.load),
          UiData(:final data) => _ReminderSettingsBody(data: data),
        },
      ),
    );
  }
}

class _ReminderSettingsBody extends ConsumerWidget {
  const _ReminderSettingsBody({required this.data});
  final ReminderSettingsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(reminderSettingsViewModelProvider.notifier);
    final theme = Theme.of(context);
    Future<void> save(Future<String?> Function() action) async {
      final error = await action();
      if (context.mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: Text('Cài đặt nhắc việc', style: theme.textTheme.headlineMedium)),
        const SizedBox(height: AppSpacing.sm),
        Text('Bác chọn cách chuông và điện thoại báo việc mỗi ngày.',
            style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.base),
        SectionCard(
          child: Column(children: [
            SwitchRow(
              icon: AppIcons.bell,
              title: 'Thông báo',
              subtitle: 'Nhắc khi đến giờ',
              value: data.notificationsEnabled,
              onChanged: data.notificationsEnabled
                  ? null
                  : (_) => save(vm.enableNotifications),
            ),
            Divider(height: AppSpacing.xl, color: theme.colorScheme.outlineVariant),
            SwitchRow(
              icon: AppIcons.vibrate,
              title: 'Chuông và rung',
              subtitle: 'Chuông nhẹ, rung',
              value: data.settings.vibrate,
              onChanged: (value) => save(() => vm.setVibrate(value)),
            ),
            Divider(height: AppSpacing.xl, color: theme.colorScheme.outlineVariant),
            SwitchRow(
              icon: AppIcons.volume,
              title: 'Đọc nội dung lời nhắc',
              subtitle: 'Đọc tên việc',
              value: data.settings.readAloud,
              onChanged: (value) => save(() => vm.setReadAloud(value)),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.base),
        SectionCard(
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: AppSizes.minTarget,
              leading: const Icon(AppIcons.settings, size: AppSizes.icon),
              title: const Text('Mở cài đặt điện thoại'),
              subtitle: const Text('Cấp quyền thông báo trên máy'),
              trailing: const Icon(AppIcons.chevronRight, size: AppSizes.icon),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Bác mở phần Thông báo trong Cài đặt điện thoại nhé.'))),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: AppRadius.cardAll,
          ),
          child: const Row(children: [
            Icon(AppIcons.info),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Chế độ im lặng có thể tắt chuông.')),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Thử lời nhắc',
          icon: AppIcons.bellRing,
          onPressed: () => context.push('/reminder/preview?preview=true'),
        ),
        const SizedBox(height: AppSpacing.betweenTargets),
        AppButton(
          label: 'Lưu cài đặt',
          icon: AppIcons.save,
          kind: AppButtonKind.secondary,
          onPressed: () => context.pop(),
        ),
      ]),
    );
  }
}
