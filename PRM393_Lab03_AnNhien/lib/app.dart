import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/display_settings.dart';
import 'viewmodels/display_settings_sync.dart';
import 'viewmodels/inbox_view_model.dart';

class AnNhienApp extends ConsumerStatefulWidget {
  const AnNhienApp({super.key});

  @override
  ConsumerState<AnNhienApp> createState() => _AnNhienAppState();
}

class _AnNhienAppState extends ConsumerState<AnNhienApp> {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  Widget build(BuildContext context) {
    ref.watch(displaySettingsSyncProvider); // F8: áp cài đặt đã lưu khi mở app.
    final fontScale = ref.watch(fontScaleProvider);
    final highContrast = ref.watch(highContrastProvider);
    ref.listen(foregroundNotificationProvider, (_, next) {
      next.whenData((item) {
        messenger.currentState?.showSnackBar(SnackBar(
          content: const Text('Bác có thông báo mới.'),
          action: SnackBarAction(
              label: 'Xem',
              onPressed: () async {
                final target =
                    await ref.read(inboxViewModelProvider.notifier).open(item);
                if (mounted) ref.read(routerProvider).push(target);
              }),
        ));
      });
    });
    return MaterialApp.router(
      title: 'An Nhiên',
      scaffoldMessengerKey: messenger,
      debugShowCheckedModeBanner: false,
      theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      // Cỡ chữ Bác chọn nhân với cỡ chữ hệ thống, trần 2.0 (architecture.md mục 12).
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1) * fontScale.factor).clamp(1.0, maxTextScale);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}
