import 'dart:async';

import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/habit.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/first_task_view_model.dart';
import 'package:an_nhien/viewmodels/onboarding_view_model.dart';
import 'package:an_nhien/viewmodels/try_reminder_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

/// F2 bước 01: khung 3 ViewModel chạy được bằng service Fake.
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

class BrokenSettingsService extends FakeSettingsService {
  BrokenSettingsService() : super(delay: Duration.zero);
  bool broken = true;

  @override
  Stream<AppSettings> watch() => broken
      ? Stream.error(const AppException('Chưa tải được cài đặt.'))
      : super.watch();
}

class StubHabitRepository implements HabitRepository {
  StubHabitRepository(this.habits, {this.fail = false});
  final List<Habit> habits;
  bool fail;

  @override
  Future<List<Habit>> all() async {
    if (fail) throw const AppException('Chưa có mạng. Bác thử lại sau nhé.');
    return habits;
  }

  @override
  Future<Habit?> byKey(String key) async =>
      habits.where((h) => h.key == key).firstOrNull;
}

void main() {
  ProviderContainer containerWith({
    SettingsService? settings,
    HabitRepository? habits,
    AuthService? auth,
    ProfileSetupService? profileSetup,
    ReminderService? reminder,
  }) {
    final c = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
      profileSetupServiceProvider.overrideWithValue(
          profileSetup ?? FakeProfileSetupService(delay: Duration.zero)),
      settingsServiceProvider.overrideWithValue(
          settings ?? FakeSettingsService(delay: Duration.zero)),
      reminderServiceProvider.overrideWithValue(
          reminder ?? FakeReminderService(delay: Duration.zero)),
      habitRepositoryProvider
          .overrideWithValue(habits ?? FakeHabitRepository()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('OnboardingViewModel', () {
    test('Loading → Data, mở ở S01 với cỡ chữ đã lưu', () async {
      final c = containerWith(
          settings: FakeSettingsService(
              initial: const AppSettings(fontScale: AppFontScale.ratLon),
              delay: Duration.zero));
      expect(c.read(onboardingViewModelProvider),
          isA<UiLoading<OnboardingData>>());
      await settled(c, onboardingViewModelProvider);
      final data =
          (c.read(onboardingViewModelProvider) as UiData<OnboardingData>).data;
      expect(data.step, OnboardingStep.welcome);
      expect(data.fontScale, AppFontScale.ratLon);
      expect(data.notificationsOn, isFalse);
      // Cỡ đã lưu được áp cho toàn app.
      expect(c.read(fontScaleProvider), AppFontScale.ratLon);
    });

    test('S01: chưa lưu gì → mặc định "Lớn"', () async {
      final c = containerWith();
      await settled(c, onboardingViewModelProvider);
      expect(c.read(fontScaleProvider), AppFontScale.lon);
    });

    test('S01: chọn cỡ → chữ toàn app đổi + Fake nhận đúng giá trị', () async {
      final settings = FakeSettingsService(delay: Duration.zero);
      final c = containerWith(settings: settings);
      await settled(c, onboardingViewModelProvider);

      await c
          .read(onboardingViewModelProvider.notifier)
          .selectFontScale(AppFontScale.ratLon);

      expect(c.read(fontScaleProvider), AppFontScale.ratLon);
      expect(settings.current.fontScale, AppFontScale.ratLon);
      final data =
          (c.read(onboardingViewModelProvider) as UiData<OnboardingData>).data;
      expect(data.fontScale, AppFontScale.ratLon);
    });

    test('S01: lưu lỗi → không ném ra View, vẫn giữ lựa chọn trên máy',
        () async {
      final settings =
          FakeSettingsService(failOnSave: true, delay: Duration.zero);
      final c = containerWith(settings: settings);
      await settled(c, onboardingViewModelProvider);

      await expectLater(
          c
              .read(onboardingViewModelProvider.notifier)
              .selectFontScale(AppFontScale.vua),
          completes);

      expect(c.read(fontScaleProvider), AppFontScale.vua);
      expect(settings.current.fontScale, AppFontScale.lon);
      expect(
          c.read(onboardingViewModelProvider), isA<UiData<OnboardingData>>());
    });

    test('S01: chạm chọn trước khi tải xong → không bị cỡ đã lưu ghi đè',
        () async {
      final c = containerWith(
          settings: FakeSettingsService(
              initial: const AppSettings(fontScale: AppFontScale.ratLon),
              delay: Duration.zero));
      // Chạm ngay, trước khi microtask load() chạy.
      final picking = c
          .read(onboardingViewModelProvider.notifier)
          .selectFontScale(AppFontScale.vua);
      await settled(c, onboardingViewModelProvider);
      await picking;
      expect(c.read(fontScaleProvider), AppFontScale.vua);
    });

    test('tải cài đặt lỗi → UiError có câu cho Bác', () async {
      final c = containerWith(settings: BrokenSettingsService());
      await settled(c, onboardingViewModelProvider);
      final state = c.read(onboardingViewModelProvider);
      expect(state, isA<UiError<OnboardingData>>());
      expect((state as UiError).message, 'Chưa tải được cài đặt.');
    });

    test('copyWith(clearErrors) xoá lỗi nhưng giữ dữ liệu đã nhập', () {
      const data = OnboardingData(
          name: 'Lan', nameError: 'Bác gõ tên nhé.', saveError: 'Lỗi');
      final cleared = data.copyWith(clearErrors: true);
      expect(cleared.name, 'Lan');
      expect(cleared.nameError, isNull);
      expect(cleared.saveError, isNull);
    });
  });

  group('OnboardingViewModel · S02', () {
    const lan = AppUser(uid: 'u1', displayName: '  Nguyễn  Thị Lan ');

    Future<(ProviderContainer, OnboardingViewModel)> ready(
        {AppUser? user, FakeProfileSetupService? setup}) async {
      final c = containerWith(
          auth: FakeAuthService(signedIn: user), profileSetup: setup);
      await settled(c, onboardingViewModelProvider);
      return (c, c.read(onboardingViewModelProvider.notifier));
    }

    OnboardingData dataOf(ProviderContainer c) =>
        (c.read(onboardingViewModelProvider) as UiData<OnboardingData>).data;

    test(
        'có tên Google → hỏi "Bác là …, đúng không?" (tên đã gọn khoảng trắng)',
        () async {
      final (c, _) = await ready(user: lan);
      expect(dataOf(c).profileStage, ProfileStage.confirmName);
      expect(dataOf(c).name, 'Nguyễn Thị Lan');
    });

    test('không có tên gợi ý → vào thẳng ô nhập tên', () async {
      final (c, _) = await ready(user: const AppUser(uid: 'u1'));
      expect(dataOf(c).profileStage, ProfileStage.enterName);
    });

    test('Đúng rồi → phần chi tiết; Nhập lại tên → ô nhập', () async {
      final (c, vm) = await ready(user: lan);
      vm.editName();
      expect(dataOf(c).profileStage, ProfileStage.enterName);
      vm.confirmName();
      expect(dataOf(c).profileStage, ProfileStage.details);
      // Mặc định theo Figma 1:103.
      expect(dataOf(c).honorific, Honorific.ong);
      expect(dataOf(c).wakeTime, const TimeOfDay(hour: 6, minute: 0));
    });

    test('tên trống → lỗi, ở lại ô nhập; gõ lại thì ẩn lỗi', () async {
      final (c, vm) = await ready(user: const AppUser(uid: 'u1'));
      vm.setName('   ');
      expect(vm.submitName(), isFalse);
      expect(dataOf(c).nameError, 'Bác chưa nhập tên gọi.');
      expect(dataOf(c).profileStage, ProfileStage.enterName);
      vm.setName('L');
      expect(dataOf(c).nameError, isNull);
    });

    test('tên quá dài → lỗi', () async {
      final (c, vm) = await ready(user: const AppUser(uid: 'u1'));
      vm.setName('a' * (maxNameLength + 1));
      expect(vm.submitName(), isFalse);
      expect(dataOf(c).nameError, contains('dài quá'));
    });

    test('tên hợp lệ → lưu đúng dữ liệu, sang S13', () async {
      final setup = FakeProfileSetupService(delay: Duration.zero);
      final (c, vm) = await ready(user: const AppUser(uid: 'u1'), setup: setup);
      vm.setName(' Sáu ');
      expect(vm.submitName(), isTrue);
      vm.setHonorific(Honorific.ba);
      vm.setWakeTime(const TimeOfDay(hour: 5, minute: 30));

      expect(await vm.submitProfile(), isTrue);
      final saved = setup.saved['u1']!;
      expect(saved.displayName, 'Sáu');
      expect(saved.honorific, Honorific.ba);
      expect(saved.toMap(),
          {'displayName': 'Sáu', 'honorific': 'ba', 'wakeTime': '05:30'});
      expect(dataOf(c).step, OnboardingStep.notifications);
      expect(dataOf(c).saving, isFalse);
    });

    test('lưu lỗi → saveError có userMessage, không mất dữ liệu; Thử lại được',
        () async {
      final setup =
          FakeProfileSetupService(failOnSave: true, delay: Duration.zero);
      final (c, vm) = await ready(user: lan, setup: setup);
      vm.confirmName();
      vm.setHonorific(Honorific.ba);

      expect(await vm.submitProfile(), isFalse);
      expect(dataOf(c).saveError, contains('Bác'));
      expect(dataOf(c).name, 'Nguyễn Thị Lan');
      expect(dataOf(c).honorific, Honorific.ba);
      expect(dataOf(c).profileStage, ProfileStage.details);

      setup.failOnSave = false;
      expect(await vm.submitProfile(), isTrue);
      expect(dataOf(c).saveError, isNull);
    });

    test('chưa đăng nhập → không lưu, báo đăng nhập lại', () async {
      final setup = FakeProfileSetupService(delay: Duration.zero);
      final (c, vm) = await ready(setup: setup);
      vm.setName('Lan');
      vm.submitName();
      expect(await vm.submitProfile(), isFalse);
      expect(setup.saved, isEmpty);
      expect(dataOf(c).saveError, contains('đăng nhập'));
    });

    test('tải tên gợi ý lỗi → UiError, "Thử lại" → UiData', () async {
      final settings = BrokenSettingsService();
      final c = containerWith(
          settings: settings, auth: FakeAuthService(signedIn: lan));
      await settled(c, onboardingViewModelProvider);
      expect(
          c.read(onboardingViewModelProvider), isA<UiError<OnboardingData>>());

      settings.broken = false;
      await c.read(onboardingViewModelProvider.notifier).load();
      expect(dataOf(c).profileStage, ProfileStage.confirmName);
    });
  });

  group('OnboardingViewModel · S13', () {
    Future<(ProviderContainer, OnboardingViewModel, FakeReminderService)> ready(
        {bool permissionGranted = true, bool alreadyGranted = false}) async {
      final reminder = FakeReminderService(
          permissionGranted: permissionGranted,
          alreadyGranted: alreadyGranted,
          delay: Duration.zero);
      final c = containerWith(reminder: reminder);
      await settled(c, onboardingViewModelProvider);
      return (c, c.read(onboardingViewModelProvider.notifier), reminder);
    }

    OnboardingData dataOf(ProviderContainer c) =>
        (c.read(onboardingViewModelProvider) as UiData<OnboardingData>).data;

    test('Fake cho phép → granted, notificationsOn = true', () async {
      final (c, vm, reminder) = await ready();
      expect(await vm.checkPermission(), isFalse);
      expect(await vm.allowReminders(), PermissionResult.granted);
      expect(reminder.requestCount, 1);
      expect(dataOf(c).notificationsOn, isTrue);
      expect(dataOf(c).step, OnboardingStep.notifications);
      expect(dataOf(c).saving, isFalse);
    });

    test('Fake từ chối → denied, sang S13d', () async {
      final (c, vm, _) = await ready(permissionGranted: false);
      expect(await vm.allowReminders(), PermissionResult.denied);
      expect(dataOf(c).step, OnboardingStep.notificationsDenied);
      expect(dataOf(c).notificationsOn, isFalse);
    });

    test('"Để sau" → S13d; "Quay lại" ở S13d → S13', () async {
      final (c, vm, reminder) = await ready();
      vm.skipReminders();
      expect(dataOf(c).step, OnboardingStep.notificationsDenied);
      expect(dataOf(c).notificationsOn, isFalse);
      expect(reminder.requestCount, 0);
      vm.showReminderPrompt();
      expect(dataOf(c).step, OnboardingStep.notifications);
    });

    test('đã có quyền sẵn → bỏ qua S13 (chỉ lần vào đầu), không hỏi lại',
        () async {
      final (c, vm, reminder) = await ready(alreadyGranted: true);
      expect(await vm.checkPermission(), isTrue);
      expect(dataOf(c).notificationsOn, isTrue);
      expect(reminder.requestCount, 0);
      // Quay lại từ N01: không tự chuyển nữa.
      expect(await vm.checkPermission(), isFalse);
    });

    test('S13d bấm "Bật nhắc việc" lần nữa → hỏi lại quyền', () async {
      final (c, vm, reminder) = await ready(permissionGranted: false);
      await vm.allowReminders();
      await vm.allowReminders();
      expect(reminder.requestCount, 2);
      expect(dataOf(c).step, OnboardingStep.notificationsDenied);
    });
  });

  group('TryReminderViewModel', () {
    test('bắt đầu ở N01 (idle), chưa có lỗi', () {
      final c = containerWith();
      final state = c.read(tryReminderViewModelProvider);
      expect(state.phase, TryReminderPhase.idle);
      expect(state.error, isNull);
    });
  });

  group('FirstTaskViewModel', () {
    test('nạp gợi ý từ HabitRepository → Data ở N04', () async {
      final c = containerWith();
      await settled(c, firstTaskViewModelProvider);
      final data =
          (c.read(firstTaskViewModelProvider) as UiData<FirstTaskData>).data;
      expect(data.step, FirstTaskStep.pick);
      expect(data.habits, isNotEmpty);
    });

    test('không có gợi ý → UiEmpty', () async {
      final c = containerWith(habits: StubHabitRepository(const []));
      await settled(c, firstTaskViewModelProvider);
      expect(c.read(firstTaskViewModelProvider), isA<UiEmpty<FirstTaskData>>());
    });

    test('lỗi → UiError, "Thử lại" → Data', () async {
      final repo = StubHabitRepository(
          const [Habit(key: 'move', name: 'Vận động', description: '')],
          fail: true);
      final c = containerWith(habits: repo);
      await settled(c, firstTaskViewModelProvider);
      expect(c.read(firstTaskViewModelProvider), isA<UiError<FirstTaskData>>());

      repo.fail = false;
      await c.read(firstTaskViewModelProvider.notifier).load();
      expect(c.read(firstTaskViewModelProvider), isA<UiData<FirstTaskData>>());
    });
  });
}
