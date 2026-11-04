import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/account_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/state_views.dart';
import '../../widgets/section_card.dart';
import '../../theme/app_icons.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final action = ref.watch(signOutViewModelProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBackBar(onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(profile.value?.role == UserRole.caregiver
              ? '/caregiver/schedule'
              : '/today');
        }
      }),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
              icon: AppIcons.user,
              title: 'Tài khoản',
              child: profile.when(
                loading: () => const LoadingView(),
                error: (_, __) => ErrorView(
                    message: 'Chưa tải được thông tin.',
                    onRetry: () => ref.invalidate(profileProvider)),
                data: (value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              )),
          if (action.message != null) ...[
            const SizedBox(height: AppSpacing.base),
            Semantics(
                liveRegion: true,
                child: Text(action.message!, style: text.bodyLarge)),
          ],
          const SizedBox(height: AppSpacing.base),
          AppButton(
              label: profile.value?.role == UserRole.caregiver
                  ? 'Xem lịch của mẹ'
                  : 'Về Hôm nay',
              wrapLabel: true,
              icon: Icons.arrow_forward,
              onPressed: action.busy
                  ? null
                  : () => context.go(profile.value?.role == null
                      ? '/session'
                      : profile.value?.role == UserRole.caregiver
                          ? '/caregiver/schedule'
                          : '/today')),
          const SizedBox(height: AppSpacing.betweenTargets),
          AppButton(
              label: 'Mã ghép nối của Bác',
              icon: Icons.phonelink_setup,
              kind: AppButtonKind.secondary,
              wrapLabel: true,
              onPressed: () => context.push('/pairing/code')),
          const SizedBox(height: AppSpacing.betweenTargets),
          AppButton(
              label: 'Ghép nối và lịch của mẹ',
              icon: Icons.calendar_month,
              kind: AppButtonKind.secondary,
              wrapLabel: true,
              onPressed: () => context.push('/caregiver/schedule')),
          const SizedBox(height: AppSpacing.xl),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Công cụ thử nghiệm', style: text.titleSmall),
            leading: const Icon(Icons.science_rounded),
            children: [
              AppButton(
                  label: 'Nhận lịch gợi ý (khu thử)',
                  icon: Icons.inbox,
                  kind: AppButtonKind.secondary,
                  wrapLabel: true,
                  onPressed: () =>
                      context.push('/settings/firebase-demo/suggestions')),
              const SizedBox(height: AppSpacing.betweenTargets),
              AppButton(
                  label: 'Khu thử tính năng',
                  wrapLabel: true,
                  icon: Icons.science_outlined,
                  kind: AppButtonKind.secondary,
                  onPressed: action.busy
                      ? null
                      : () => context.push('/settings/firebase-demo')),
              const SizedBox(height: AppSpacing.betweenTargets),
            ],
          ),
          const SizedBox(height: AppSpacing.betweenTargets),
          AppButton(
              label: 'Đăng xuất',
              icon: Icons.logout,
              kind: AppButtonKind.dangerOutline,
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
                  if (context.mounted &&
                      ref.read(signOutViewModelProvider).message == null) {
                    context.go('/sign-in');
                  }
                }
              }),
        ]),
      )),
    );
  }
}
