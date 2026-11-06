import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/device_access_view_model.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/form_parts.dart';
import '../../theme/app_spacing.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reminderSettingsViewModelProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderSettingsViewModelProvider);
    final vm = ref.read(reminderSettingsViewModelProvider.notifier);
    return Scaffold(
        appBar: AppBackBar.adaptive(context),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              const CalmPageHeader(
                  title: 'Lời nhắc',
                  subtitle:
                      'Kiểm tra quyền thông báo và thử lời nhắc trên điện thoại.',
                  art: true,
                  actions: false),
              const SizedBox(height: AppSpacing.lg),
              Text(
                  state.allowed == null
                      ? 'Đang kiểm tra quyền…'
                      : state.allowed!
                          ? 'Điện thoại đã cho phép thông báo'
                          : 'Điện thoại chưa cho phép thông báo',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.base),
              const Text(
                  'Bật hoặc tắt lời nhắc riêng cho từng việc ở màn Chỉnh sửa. Để tắt toàn bộ thông báo, Bác mở cài đặt điện thoại.'),
              const SizedBox(height: AppSpacing.lg),
              if (state.allowed != true)
                AppButton(
                    label: 'Cho phép thông báo',
                    icon: Icons.notifications_rounded,
                    busy: state.busy,
                    onPressed: () => vm.act('request')),
              const SizedBox(height: AppSpacing.base),
              AppButton(
                  label: 'Gửi lời nhắc thử',
                  icon: Icons.notifications_active_rounded,
                  onPressed: state.busy || state.allowed != true
                      ? null
                      : () => vm.act('test')),
              const SizedBox(height: AppSpacing.base),
              AppButton(
                  label: 'Mở cài đặt điện thoại',
                  icon: Icons.settings_rounded,
                  kind: AppButtonKind.secondary,
                  onPressed: state.busy ? null : () => vm.act('settings')),
              const SizedBox(height: AppSpacing.base),
              if (state.message != null) Text(state.message!),
              if (state.error != null) ...[
                FieldMessage.error(state.error!),
                TextButton(
                    onPressed: vm.refresh, child: const Text('Kiểm tra lại'))
              ],
            ])));
  }
}
