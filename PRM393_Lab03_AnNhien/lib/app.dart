import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/display_settings.dart';

class AnNhienApp extends ConsumerWidget {
  const AnNhienApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider);
    final highContrast = ref.watch(highContrastProvider);
    return MaterialApp.router(
      title: 'An Nhiên',
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
