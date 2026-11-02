import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../viewmodels/sign_in_view_model.dart';
import '../../viewmodels/account_view_model.dart';
import '../../widgets/app_button.dart';

/// A01 (đã đổi theo đề Lab 3: đăng nhập Google) – chủ: B – Hiếu.
/// Ghi thay đổi này vào docs/design-traceability.md và sửa Figma.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInViewModelProvider);
    final signOut = ref.watch(signOutViewModelProvider);
    final message = state.message ?? signOut.message;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        // Cuộn được khi chữ phóng to ×2.0 ở 360 dp; đủ chỗ thì 2 Spacer giữ bố cục như cũ (F0-06, sửa giúp Hiếu).
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 2 * AppSpacing.screen),
              child: IntrinsicHeight(
                child: Column(children: [
                  const Spacer(),
                  Icon(Icons.spa_outlined, size: AppSizes.logo, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: AppSpacing.base),
                  Text('An Nhiên', style: t.displaySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Không cần mật khẩu.', style: t.bodyLarge, textAlign: TextAlign.center),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.base),
                    Text(message,
                        style: t.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center),
                  ],
                  const Spacer(),
                  AppButton(
                    label: 'Tiếp tục với Google',
                    icon: Icons.login,
                    busy: state.busy || signOut.busy,
                    onPressed: () => ref.read(signInViewModelProvider.notifier).signInWithGoogle(),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
