import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/account_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

/// Giữ các màn dữ liệu riêng ở ngoài khi auth/profile đang tải hoặc lỗi.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider);
    final action = ref.watch(signOutViewModelProvider);
    final failed = session.hasError || profile.hasError;
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Expanded(
          child: failed && !action.busy
              ? SingleChildScrollView(
                  child: ErrorView(
                      message: 'Chưa tải được tài khoản. Bác thử lại nhé.',
                      onRetry: () {
                        ref.invalidate(sessionProvider);
                        ref.invalidate(profileProvider);
                      }))
              : LoadingView(
                  message:
                      action.busy ? 'Đang đăng xuất…' : 'Đang mở tài khoản…')),
      if (failed && !action.busy)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: AppButton(
              label: 'Tài khoản',
              icon: Icons.account_circle_rounded,
              kind: AppButtonKind.secondary,
              onPressed: () => context.go('/account')),
        ),
    ])));
  }
}
