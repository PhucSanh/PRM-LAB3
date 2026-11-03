import 'dart:async';

import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/display_settings_sync.dart';
import 'package:an_nhien/viewmodels/settings_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

/// F8 bước 01: SettingsViewModel (S10) + nạp cài đặt khi mở app.
Future<void> settled<T>(
    ProviderContainer c, ProviderListenable<UiState<T>> provider) async {
  final ready = Completer<void>();
  final sub = c.listen(provider, (_, next) {
    if (next is! UiLoading<T> && !ready.isCompleted) ready.complete();
  }, fireImmediately: true);
  try {
    await ready.future.timeout(const Duration(seconds: 5));
  } finally {
    sub.close();
  }
}

/// `watch()` lỗi cho tới khi tắt cờ [broken].
class BrokenSettingsService extends FakeSettingsService {
  BrokenSettingsService() : super(delay: Duration.zero);
  bool broken = true;

  @override
  Stream<AppSettings> watch() => broken
      ? Stream.error(const AppException('Chưa tải được cài đặt.'))
      : super.watch();
}

/// Ghi lại cả tham số event (FakeAnalyticsService chỉ ghi tên).
class RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async =>
      events.add((name, params));

  @override
  Future<void> setUserId(String? uid) async {}

  List<Map<String, Object>?> paramsOf(String name) => [
        for (final (n, p) in events)
          if (n == name) p
      ];
}

/// Ghi lại các lỗi non-fatal.
class RecordingCrash extends FakeCrashService {
  final reasons = <String?>[];

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason}) async {
    reasons.add(reason);
  }
}

void main() {
  late RecordingAnalytics analytics;
  late RecordingCrash crash;

  ProviderContainer containerWith(SettingsService settings) {
    analytics = RecordingAnalytics();
    crash = RecordingCrash();
    final c = ProviderContainer(overrides: [
      settingsServiceProvider.overrideWithValue(settings),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(crash),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('SettingsViewModel', () {
    test('Loading → Data với giá trị Fake phát ra', () async {
      final c = containerWith(FakeSettingsService(
          initial: const AppSettings(
              fontScale: AppFontScale.ratLon, readAloud: true),
          delay: Duration.zero));
      expect(c.read(settingsViewModelProvider), isA<UiLoading<AppSettings>>());
      await settled(c, settingsViewModelProvider);
      final state = c.read(settingsViewModelProvider);
      expect(state, isA<UiData<AppSettings>>());
      final data = (state as UiData<AppSettings>).data;
      expect(data.fontScale, AppFontScale.ratLon);
      expect(data.readAloud, isTrue);
    });

    test('stream lỗi → UiError có câu cho Bác; retry() → UiData', () async {
      final service = BrokenSettingsService();
      final c = containerWith(service);
      await settled(c, settingsViewModelProvider);
      final state = c.read(settingsViewModelProvider);
      expect(state, isA<UiError<AppSettings>>());
      expect((state as UiError).message, 'Chưa tải được cài đặt.');
      expect(crash.reasons, contains('load_settings'));

      service.broken = false;
      c.read(settingsViewModelProvider.notifier).retry();
      await settled(c, settingsViewModelProvider);
      expect(c.read(settingsViewModelProvider), isA<UiData<AppSettings>>());
    });

    test('setFontScale: đổi fontScaleProvider, Fake nhận, log from / to',
        () async {
      final service = FakeSettingsService(delay: Duration.zero);
      final c = containerWith(service);
      await settled(c, settingsViewModelProvider);

      final change = await c
          .read(settingsViewModelProvider.notifier)
          .setFontScale(AppFontScale.ratLon);

      expect(c.read(fontScaleProvider), AppFontScale.ratLon);
      expect(service.current.fontScale, AppFontScale.ratLon);
      expect(change, isNotNull);
      expect(change!.from, AppFontScale.lon);
      expect(change.to, AppFontScale.ratLon);
      expect(change.saveError, isNull);
      expect(analytics.paramsOf('change_font_size'), [
        {'from': 'lon', 'to': 'rat_lon'}
      ]);
      final data =
          (c.read(settingsViewModelProvider) as UiData<AppSettings>).data;
      expect(data.fontScale, AppFontScale.ratLon);
    });

    test('chọn lại đúng cỡ đang dùng: không lưu, không log', () async {
      final c = containerWith(FakeSettingsService(delay: Duration.zero));
      await settled(c, settingsViewModelProvider);
      final change = await c
          .read(settingsViewModelProvider.notifier)
          .setFontScale(AppFontScale.lon);
      expect(change, isNull);
      expect(analytics.paramsOf('change_font_size'), isEmpty);
    });

    test('setHighContrast đổi highContrastProvider ngay và lưu', () async {
      final service = FakeSettingsService(delay: Duration.zero);
      final c = containerWith(service);
      await settled(c, settingsViewModelProvider);
      await c.read(settingsViewModelProvider.notifier).setHighContrast(true);
      expect(c.read(highContrastProvider), isTrue);
      expect(service.current.highContrast, isTrue);
    });

    test('setReadAloud / setVibrate lưu qua service', () async {
      final service = FakeSettingsService(delay: Duration.zero);
      final c = containerWith(service);
      await settled(c, settingsViewModelProvider);
      final vm = c.read(settingsViewModelProvider.notifier);
      await vm.setReadAloud(true);
      await vm.setVibrate(false);
      expect(service.current.readAloud, isTrue);
      expect(service.current.vibrate, isFalse);
    });

    test('lưu lỗi: không ném, giữ giá trị trên máy, có recordError', () async {
      final c = containerWith(
          FakeSettingsService(failOnSave: true, delay: Duration.zero));
      await settled(c, settingsViewModelProvider);
      final vm = c.read(settingsViewModelProvider.notifier);

      final font = await vm.setFontScale(AppFontScale.vua);
      final contrast = await vm.setHighContrast(true);

      expect(font!.saveError, 'Chưa lưu được cài đặt. Bác thử lại nhé.');
      expect(contrast!.saveError, isNotNull);
      expect(c.read(fontScaleProvider), AppFontScale.vua);
      expect(c.read(highContrastProvider), isTrue);
      expect(crash.reasons,
          containsAll(['save_font_scale', 'save_high_contrast']));
      final data =
          (c.read(settingsViewModelProvider) as UiData<AppSettings>).data;
      expect(data.fontScale, AppFontScale.vua);
      expect(data.highContrast, isTrue);
    });

    test('undo trả lại giá trị cũ và lưu lại', () async {
      final service = FakeSettingsService(delay: Duration.zero);
      final c = containerWith(service);
      await settled(c, settingsViewModelProvider);
      final vm = c.read(settingsViewModelProvider.notifier);

      final font = await vm.setFontScale(AppFontScale.ratLon);
      final contrast = await vm.setHighContrast(true);
      final vibrate = await vm.setVibrate(false);

      expect(await vm.undo(font!), isNull);
      expect(await vm.undo(contrast!), isNull);
      expect(await vm.undo(vibrate!), isNull);

      expect(c.read(fontScaleProvider), AppFontScale.lon);
      expect(c.read(highContrastProvider), isFalse);
      expect(service.current, const AppSettings());
      expect(analytics.paramsOf('change_font_size').last,
          {'from': 'rat_lon', 'to': 'lon'});
    });
  });

  group('displaySettingsSyncProvider (mở lại app)', () {
    test('cài đặt đã lưu Rất lớn + tương phản cao được áp cho toàn app',
        () async {
      final c = containerWith(FakeSettingsService(
          initial: const AppSettings(
              fontScale: AppFontScale.ratLon, highContrast: true),
          delay: Duration.zero));
      expect(c.read(fontScaleProvider), AppFontScale.lon);
      expect(c.read(highContrastProvider), isFalse);

      final sub = c.listen(displaySettingsSyncProvider, (_, __) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(c.read(fontScaleProvider), AppFontScale.ratLon);
      expect(c.read(highContrastProvider), isTrue);
    });

    test('đổi ở nơi khác (Fake phát giá trị mới) → provider đổi theo',
        () async {
      final service = FakeSettingsService(delay: Duration.zero);
      final c = containerWith(service);
      final sub = c.listen(displaySettingsSyncProvider, (_, __) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      await service.setFontScale(AppFontScale.vua);
      await service.setHighContrast(true);

      expect(c.read(fontScaleProvider), AppFontScale.vua);
      expect(c.read(highContrastProvider), isTrue);
    });

    test('đọc lỗi: giữ mặc định, ghi Crashlytics', () async {
      final c = containerWith(BrokenSettingsService());
      final sub = c.listen(displaySettingsSyncProvider, (_, __) {});
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(c.read(fontScaleProvider), AppFontScale.lon);
      expect(c.read(highContrastProvider), isFalse);
      expect(crash.reasons, contains('load_display_settings'));
    });
  });
}
