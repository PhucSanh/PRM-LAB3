import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/account_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final action = ref.watch(signOutViewModelProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Tài khoản'), automaticallyImplyLeading: false),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          profile.when(
            loading: () => const LoadingView(),
            error: (_, __) => ErrorView(
                message: 'Chưa tải được thông tin.',
                onRetry: () => ref.invalidate(profileProvider)),
            data: (value) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value?.displayName ?? 'Tài khoản Google',
                  style: text.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              Text(
                  switch (value?.role) {
                    UserRole.elder => 'Vai trò: Bác',
                    UserRole.caregiver => 'Vai trò: Con cháu',
                    null => 'Chưa chọn vai trò',
                  },
                  style: text.bodyLarge),
            ]),
          ),
          if (action.message != null) ...[
            const SizedBox(height: AppSpacing.base),
            Semantics(
                liveRegion: true,
                child: Text(action.message!, style: text.bodyLarge)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
              label: 'Tiếp tục',
              icon: Icons.arrow_forward,
              onPressed: action.busy ? null : () => context.go('/session')),
          const SizedBox(height: AppSpacing.betweenTargets),
          AppButton(
              label: 'Đăng xuất',
              icon: Icons.logout,
              kind: AppButtonKind.danger,
              busy: action.busy,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text('Đăng xuất?'),
                          content: const Text(
                              'Dữ liệu đã đồng bộ vẫn còn trên tài khoản. Dữ liệu chưa đồng bộ trên máy sẽ bị xoá.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Ở lại')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Đăng xuất')),
                          ],
                        ));
                if (confirmed == true && context.mounted) {
                  await ref.read(signOutViewModelProvider.notifier).signOut();
                }
              }),
        ]),
      )),
    );
  }
}
