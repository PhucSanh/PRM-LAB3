import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../viewmodels/sign_in_view_model.dart';
import '../../widgets/app_button.dart';

/// A01 (đã đổi theo đề Lab 3: đăng nhập Google) – chủ: B – Hiếu.
/// Ghi thay đổi này vào docs/design-traceability.md và sửa Figma.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInViewModelProvider);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(children: [
            const Spacer(),
            Icon(Icons.spa_outlined, size: 96, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.base),
            Text('An Nhiên', style: t.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Không cần mật khẩu.', style: t.bodyLarge, textAlign: TextAlign.center),
            if (state.message != null) ...[
              const SizedBox(height: AppSpacing.base),
              Text(state.message!, style: t.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
            ],
            const Spacer(),
            AppButton(
              label: 'Tiếp tục với Google',
              icon: Icons.login,
              busy: state.busy,
              onPressed: () => ref.read(signInViewModelProvider.notifier).signInWithGoogle(),
            ),
          ]),
        ),
      ),
    );
  }
}
