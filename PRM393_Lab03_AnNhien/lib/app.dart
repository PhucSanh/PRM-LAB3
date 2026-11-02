import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
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
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
