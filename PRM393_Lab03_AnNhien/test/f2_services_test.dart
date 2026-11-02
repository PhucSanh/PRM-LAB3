import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

/// F2 bước 01: service Fake dùng cho onboarding.
void main() {
  group('AppSettings', () {
    test('toMap rồi fromMap giữ nguyên giá trị', () {
      const settings = AppSettings(
          fontScale: AppFontScale.ratLon,
          highContrast: true,
          readAloud: true,
          vibrate: false);
      expect(AppSettings.fromMap(settings.toMap()), settings);
      expect(settings.toMap()['fontScale'], 1.3);
    });

    test('dữ liệu thiếu / lạ → mặc định "Lớn"', () {
      expect(AppSettings.fromMap(const {}), const AppSettings());
      expect(AppSettings.fromMap(const {'fontScale': 9}).fontScale,
          AppFontScale.lon);
    });
  });

  group('FakeSettingsService', () {
    test('lưu rồi watch() phát lại đúng', () async {
      final service = FakeSettingsService(delay: Duration.zero);
      addTearDown(service.dispose);
      final seen = <AppSettings>[];
      final sub = service.watch().listen(seen.add);
      addTearDown(sub.cancel);

      await service.setFontScale(AppFontScale.ratLon);
      await service.setHighContrast(true);
      await service.setReadAloud(true);
      await service.setVibrate(false);
      await pumpEventQueue();

      expect(seen.first, const AppSettings());
      expect(
          seen.last,
          const AppSettings(
              fontScale: AppFontScale.ratLon,
              highContrast: true,
              readAloud: true,
              vibrate: false));
      expect(await service.watch().first, seen.last);
    });

    test('failOnSave → ném AppException, không đổi giá trị', () async {
      final service =
          FakeSettingsService(failOnSave: true, delay: Duration.zero);
      addTearDown(service.dispose);
      await expectLater(
          service.setFontScale(AppFontScale.vua), throwsA(isA<AppException>()));
      expect(service.current.fontScale, AppFontScale.lon);
    });
  });

  group('FakeReminderService', () {
    const task = TaskItem(
        id: 't1', title: 'Đi bộ', habitKey: 'move', hour: 9, minute: 0);

    test('chưa hỏi → chưa có quyền; cho phép → có quyền, nhắc được', () async {
      final service = FakeReminderService(delay: Duration.zero);
      expect(await service.hasPermission(), isFalse);
      expect(await service.requestPermission(), isTrue);
      expect(await service.hasPermission(), isTrue);

      await service.schedule(task);
      await service.snooze('t1', 10);
      await service.showTest();
      expect(service.scheduled.keys, ['t1']);
      expect(service.snoozed['t1'], 10);
      expect(service.testShownCount, 1);

      await service.cancel('t1');
      expect(service.scheduled, isEmpty);
    });

    test('Bác từ chối → không có quyền, gửi thử ném AppException', () async {
      final service =
          FakeReminderService(permissionGranted: false, delay: Duration.zero);
      expect(await service.requestPermission(), isFalse);
      expect(service.requestCount, 1);
      await expectLater(service.schedule(task), throwsA(isA<AppException>()));
      await expectLater(service.showTest(), throwsA(isA<AppException>()));
    });

    test('đã có quyền từ trước', () async {
      final service = FakeReminderService(alreadyGranted: true);
      expect(await service.hasPermission(), isTrue);
    });

    test('failOnShowTest → ném AppException có câu cho Bác', () async {
      final service = FakeReminderService(
          alreadyGranted: true, failOnShowTest: true, delay: Duration.zero);
      await expectLater(
          service.showTest(),
          throwsA(isA<AppException>()
              .having((e) => e.userMessage, 'userMessage', contains('Bác'))));
      expect(service.testShownCount, 0);
    });
  });

  group('FakeProfileService (F1, F2 dùng lại)', () {
    test('markOnboarded → watch() phát onboarded = true', () async {
      final service = FakeProfileService();
      addTearDown(service.dispose);
      await service.ensureProfile(const AppUser(uid: 'u1'));
      await service.setRole('u1', UserRole.elder);
      await service.markOnboarded('u1');
      expect((await service.watch('u1').first).onboarded, isTrue);
    });

    test('chưa chọn vai trò Bác → markOnboarded ném AppException', () async {
      final service = FakeProfileService();
      addTearDown(service.dispose);
      await service.ensureProfile(const AppUser(uid: 'u1'));
      await expectLater(
          service.markOnboarded('u1'), throwsA(isA<AppException>()));
    });
  });
}
