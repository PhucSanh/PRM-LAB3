import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_back_bar.dart';

/// Màn tạm cho route chưa làm. Người phụ trách thay bằng màn thật rồi xoá lệnh dùng widget này.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({super.key, required this.code, required this.title, required this.owner, this.showBack = true});

  final String code; // vd. "S07 · F7"
  final String title;
  final String owner;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBack ? const AppBackBar() : null,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.lg),
            Text(code, style: t.labelMedium),
            Text(title, style: t.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Đang làm – $owner', style: t.bodyMedium),
          ]),
        ),
      ),
    );
  }
}
