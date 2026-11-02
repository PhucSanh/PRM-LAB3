import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../models/notification_target.dart';
import '../services/providers.dart';
import 'session_view_model.dart';
import 'account_view_model.dart';
import 'ui_state.dart';

final inboxViewModelProvider = NotifierProvider.autoDispose<InboxViewModel,
    UiState<List<AppNotification>>>(InboxViewModel.new);

class InboxViewModel extends Notifier<UiState<List<AppNotification>>> {
  @override
  UiState<List<AppNotification>> build() {
    final session = ref.watch(sessionProvider);
    if (ref.watch(signOutViewModelProvider).busy ||
        session.asData?.value == null) {
      return const UiEmpty();
    }
    Future.microtask(() async {
      if (!ref.mounted) return;
      try {
        await ref.read(analyticsServiceProvider).logEvent('view_inbox');
      } catch (_) {}
    });
    final subscription =
        ref.watch(messagingServiceProvider).inbox().listen((items) {
      if (ref.mounted) state = items.isEmpty ? const UiEmpty() : UiData(items);
    }, onError: (Object error) {
      if (ref.mounted) {
        state = const UiError('Chưa tải được thông báo. Bác thử lại nhé.');
      }
    });
    ref.onDispose(subscription.cancel);
    return const UiLoading();
  }

  void retry() => ref.invalidateSelf();
  Future<String> open(AppNotification item) async {
    try {
      await ref.read(analyticsServiceProvider).logEvent('open_notification');
    } catch (_) {}
    return notificationTarget(item.route);
  }

  Future<String> permission() async {
    try {
      final allowed =
          await ref.read(messagingServiceProvider).requestPermission();
      await ref
          .read(analyticsServiceProvider)
          .logEvent('notification_permission', {'allowed': allowed ? 1 : 0});
      return allowed
          ? 'Đã bật thông báo.'
          : 'Thông báo đang tắt. Bác có thể bật trong cài đặt máy.';
    } catch (_) {
      return 'Chưa bật được thông báo. Bác thử lại nhé.';
    }
  }
}

/// Foreground banner follows the same session gate as the inbox.
final foregroundNotificationProvider = StreamProvider<AppNotification>((ref) {
  final user = ref.watch(sessionProvider).asData?.value;
  if (user == null || ref.watch(signOutViewModelProvider).busy) {
    return const Stream.empty();
  }
  final analytics = ref.read(analyticsServiceProvider);
  return ref.watch(messagingServiceProvider).onReceived.asyncMap((item) async {
    try {
      await analytics.logEvent('receive_notification');
    } catch (_) {}
    return item;
  });
});
