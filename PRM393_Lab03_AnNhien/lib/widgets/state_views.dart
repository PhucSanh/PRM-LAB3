import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Loading / Empty / Error dùng chung cho mọi màn tải dữ liệu.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Đang tải…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(strokeWidth: 6),
          const SizedBox(height: AppSpacing.base),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ]),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final AppButton? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.base),
          Text(title, style: t.headlineMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(message!, style: t.bodyLarge, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 64, color: scheme.error),
          const SizedBox(height: AppSpacing.base),
          Text(message, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Thử lại', icon: Icons.refresh, onPressed: onRetry),
        ]),
      ),
    );
  }
}
