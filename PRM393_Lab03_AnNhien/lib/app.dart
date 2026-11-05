import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/display_settings.dart';
import 'viewmodels/display_settings_sync.dart';
import 'viewmodels/inbox_view_model.dart';
import 'viewmodels/session_view_model.dart';
import 'models/app_notification.dart';
import 'models/user_profile.dart';
import 'viewmodels/account_view_model.dart';

class AnNhienApp extends ConsumerStatefulWidget {
  const AnNhienApp({super.key});

  @override
  ConsumerState<AnNhienApp> createState() => _AnNhienAppState();
}

class _AnNhienAppState extends ConsumerState<AnNhienApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.registerFontLicenses();
  }

  String? _uid;
  final _seen = <String>{};
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  Widget build(BuildContext context) {
    ref.watch(displaySettingsSyncProvider); // F8: áp cài đặt đã lưu khi mở app.
    final fontScale = ref.watch(fontScaleProvider);
    final highContrast = ref.watch(highContrastProvider);
    // Resolved session profile, never a route-name guess. Unknown role stays elderly.
    final caregiver =
        ref.watch(profileProvider).asData?.value?.role == UserRole.caregiver;
    ref.listen(sessionProvider, (_, next) {
      final uid = next.asData?.value?.uid;
      if (uid != _uid) {
        _uid = uid;
        _seen.clear();
        messenger.currentState?.clearSnackBars();
      }
    });
    ref.listen(foregroundNotificationProvider, (_, next) {
      next.whenData((item) {
        if (!_seen.add(item.id)) return;
        if (_seen.length > 200) _seen.remove(_seen.first);
        final uid = ref.read(sessionProvider).asData?.value?.uid;
        messenger.currentState?.showSnackBar(SnackBar(
          content: Text(item.kind == NotificationKind.family
              ? 'Có thông báo mới từ gia đình.'
              : 'Có thông báo mới từ An Nhiên.'),
          action: SnackBarAction(
              label: 'Xem',
              onPressed: () async {
                if (uid != ref.read(sessionProvider).asData?.value?.uid) return;
                final target =
                    await ref.read(inboxViewModelProvider.notifier).open(item);
                if (mounted &&
                    uid == ref.read(sessionProvider).asData?.value?.uid) {
                  ref.read(routerProvider).push(target);
                }
              }),
        ));
      });
    });
    return MaterialApp.router(
      title: 'An Nhiên',
      scaffoldMessengerKey: messenger,
      debugShowCheckedModeBanner: false,
      theme: highContrast
          ? AppTheme.highContrast(caregiver: caregiver)
          : AppTheme.light(caregiver: caregiver),
      routerConfig: ref.watch(routerProvider),
      // Cỡ chữ Bác chọn nhân với cỡ chữ hệ thống, trần 2.0 (architecture.md mục 12).
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1) * fontScale.factor)
            .clamp(1.0, maxTextScale);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}
