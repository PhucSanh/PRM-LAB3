import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_back_bar.dart';
import 'botanical_scene.dart';
import 'app_button.dart';
import 'package:go_router/go_router.dart';

/// Màn tạm cho route chưa làm. Người phụ trách thay bằng màn thật rồi xoá lệnh dùng widget này.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder(
      {super.key,
      required this.code,
      required this.title,
      required this.owner,
      this.showBack = true,
      this.onAccount});

  final String code; // vd. "S07 · F7"
  final String title;
  final String owner;
  final bool showBack;
  final VoidCallback? onAccount;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBack ? AppBackBar.adaptive(context) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.lg),
            const BotanicalScene(height: 180, round: true),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: t.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'Tính năng này chưa khả dụng trong phiên bản hiện tại. Bạn vẫn có thể dùng các hoạt động đã có trong Lịch.',
                style: t.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
                label: 'Về Lịch',
                icon: Icons.calendar_month_rounded,
                onPressed: () => context.go('/calendar')),
            if (onAccount != null)
              TextButton.icon(
                  onPressed: onAccount,
                  icon: const Icon(Icons.account_circle_rounded),
                  label: const Text('Tài khoản')),
          ]),
        ),
      ),
    );
  }
}
