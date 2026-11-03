import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers.dart';
import '../theme/display_settings.dart';

/// F8 – Sanh. Áp cài đặt hiển thị đã lưu (cỡ chữ, tương phản cao) cho toàn
/// app, kể cả khi mở lại app mà không đi qua S01.
///
/// Lắng `SettingsService.watch()` và đẩy giá trị vào `fontScaleProvider` /
/// `highContrastProvider` (hai provider này `app.dart` dùng để dựng theme và
/// `textScaler`). Kích hoạt: `ref.watch(displaySettingsSyncProvider)` trong
/// `AnNhienApp.build()` – sống suốt vòng đời app.
///
/// Đọc lỗi thì giữ giá trị đang dùng trên máy (mặc định "Lớn", tương phản tắt)
/// và ghi Crashlytics non-fatal; không chặn Bác dùng app.
final displaySettingsSyncProvider = Provider<void>((ref) {
  final service = ref.watch(settingsServiceProvider);
  final subscription = service.watch().listen(
    (settings) {
      ref.read(fontScaleProvider.notifier).set(settings.fontScale);
      ref.read(highContrastProvider.notifier).set(settings.highContrast);
    },
    onError: (Object error, StackTrace stack) {
      unawaited(ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: 'load_display_settings')
          .catchError((_) {}));
    },
  );
  ref.onDispose(subscription.cancel);
});
