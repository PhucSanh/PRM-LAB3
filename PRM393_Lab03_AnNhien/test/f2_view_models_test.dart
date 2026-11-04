import 'dart:async';

import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/habit.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/services/task_repository.dart';
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

/// TaskRepository giả có cờ lỗi khi lưu.
class FlakyTaskRepository extends FakeTaskRepository {
  FlakyTaskRepository({this.failOnSave = false}) : super(const []);
  bool failOnSave;
  final saved = <TaskItem>[];

  @override
  Future<void> save(TaskItem task) async {
    if (failOnSave) {
      throw const AppException('Chưa lưu được việc. Bác thử lại nhé.');
    }
    saved.add(task);
    await super.save(task);
  }
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
    AnalyticsService? analytics,
    TaskRepository? tasks,
    ProfileService? profiles,
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
      analyticsServiceProvider
          .overrideWithValue(analytics ?? FakeAnalyticsService()),
      taskRepositoryProvider
          .overrideWithValue(tasks ?? FakeTaskRepository(const [])),
      profileServiceProvider
          .overrideWithValue(profiles ?? FakeProfileService()),
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
    (
      ProviderContainer,
      TryReminderViewModel,
      FakeReminderService,
      FakeAnalyticsService
    ) setUpVm({bool failOnShowTest = false}) {
      final reminder = FakeReminderService(
          alreadyGranted: true,
          failOnShowTest: failOnShowTest,
          delay: Duration.zero);
      final analytics = FakeAnalyticsService();
      final c = containerWith(reminder: reminder, analytics: analytics);
      return (
        c,
        c.read(tryReminderViewModelProvider.notifier),
        reminder,
        analytics
      );
    }

    TryReminderState stateOf(ProviderContainer c) =>
        c.read(tryReminderViewModelProvider);

    test('bắt đầu ở N01 (idle), chưa có lỗi', () {
      final (c, _, _, _) = setUpVm();
      expect(stateOf(c).phase, TryReminderPhase.idle);
      expect(stateOf(c).error, isNull);
    });

    test('gửi thử gọi Fake → hỏi Bác đã nhận chưa (N02)', () async {
      final (c, vm, reminder, _) = setUpVm();
      final sending = vm.sendTest();
      expect(stateOf(c).phase, TryReminderPhase.sending);
      await sending;
      expect(reminder.testShownCount, 1);
      expect(stateOf(c).phase, TryReminderPhase.waitingAnswer);
    });

    test('trả lời "đã nhận" → received, log test_reminder đúng 1 lần',
        () async {
      final (c, vm, _, analytics) = setUpVm();
      await vm.sendTest();
      await vm.answer(true);
      expect(stateOf(c).phase, TryReminderPhase.received);
      expect(analytics.logged.where((e) => e == 'test_reminder'), hasLength(1));
      // Bấm lại không log thêm.
      await vm.answer(true);
      expect(analytics.logged.where((e) => e == 'test_reminder'), hasLength(1));
    });

    test('trả lời "chưa nhận" → N03, log 1 lần; Thử lại → hỏi lại, log thêm 1',
        () async {
      final (c, vm, reminder, analytics) = setUpVm();
      await vm.sendTest();
      await vm.answer(false);
      expect(stateOf(c).phase, TryReminderPhase.notReceived);
      expect(analytics.logged.where((e) => e == 'test_reminder'), hasLength(1));

      await vm.retry();
      expect(reminder.testShownCount, 2);
      expect(stateOf(c).phase, TryReminderPhase.waitingAnswer);
      await vm.answer(true);
      expect(analytics.logged.where((e) => e == 'test_reminder'), hasLength(2));
    });

    test('chưa gửi thử thì không trả lời được', () async {
      final (c, vm, _, analytics) = setUpVm();
      await vm.answer(true);
      expect(stateOf(c).phase, TryReminderPhase.idle);
      expect(analytics.logged, isEmpty);
    });

    test('Fake lỗi → về N01 kèm câu lỗi cho Bác; Thử lại được', () async {
      final (c, vm, reminder, _) = setUpVm(failOnShowTest: true);
      await vm.sendTest();
      expect(stateOf(c).phase, TryReminderPhase.idle);
      expect(stateOf(c).error, contains('Bác'));

      reminder.failOnShowTest = false;
      await vm.retry();
      expect(stateOf(c).phase, TryReminderPhase.waitingAnswer);
      expect(stateOf(c).error, isNull);
    });

    test('"Quay lại" ở N02 / N03 → về N01', () async {
      final (c, vm, _, _) = setUpVm();
      await vm.sendTest();
      await vm.answer(false);
      vm.backToStart();
      expect(stateOf(c).phase, TryReminderPhase.idle);
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

    group('N04 → N05 → N18', () {
      const lan = AppUser(uid: 'u1', displayName: 'Lan');

      Future<
              (
                ProviderContainer,
                FirstTaskViewModel,
                FlakyTaskRepository,
                FakeProfileService,
                RecordingAnalytics,
                FakeReminderService
              )>
          ready({bool failOnSave = false, bool notificationsOn = true}) async {
        final tasks = FlakyTaskRepository(failOnSave: failOnSave);
        final profiles = FakeProfileService(
            [const UserProfile(uid: 'u1', role: UserRole.elder)]);
        addTearDown(profiles.dispose);
        final analytics = RecordingAnalytics();
        final reminder = FakeReminderService(
            alreadyGranted: notificationsOn, delay: Duration.zero);
        final c = containerWith(
          auth: FakeAuthService(signedIn: lan),
          tasks: tasks,
          profiles: profiles,
          analytics: analytics,
          reminder: reminder,
        );
        await settled(c, firstTaskViewModelProvider);
        return (
          c,
          c.read(firstTaskViewModelProvider.notifier),
          tasks,
          profiles,
          analytics,
          reminder
        );
      }

      FirstTaskData dataOf(ProviderContainer c) =>
          (c.read(firstTaskViewModelProvider) as UiData<FirstTaskData>).data;

      test(
          'N04 chọn sẵn việc đầu; chọn khác → Tiếp tục → N05, Quay lại giữ lựa chọn',
          () async {
        final (c, vm, _, _, _, _) = await ready();
        expect(dataOf(c).habitKey, dataOf(c).habits.first.key);
        vm.pick('tea');
        vm.confirmPick();
        expect(dataOf(c).step, FirstTaskStep.time);
        expect(dataOf(c).time, const TimeOfDay(hour: 9, minute: 0));
        vm.backToPick();
        expect(dataOf(c).step, FirstTaskStep.pick);
        expect(dataOf(c).habitKey, 'tea');
      });

      test(
          'lưu → TaskRepository nhận đúng dữ liệu, N18, add_task chỉ có khoá / số',
          () async {
        final (c, vm, tasks, _, analytics, reminder) = await ready();
        vm.pick('tea');
        vm.confirmPick();
        vm.setTime(const TimeOfDay(hour: 15, minute: 30));

        expect(await vm.save(), isTrue);
        final task = tasks.saved.single;
        expect(task.habitKey, 'tea');
        expect(task.title, dataOf(c).habit!.name);
        expect((task.hour, task.minute), (15, 30));
        expect(task.repeat, RepeatRule.daily);
        expect(dataOf(c).step, FirstTaskStep.saved);
        // Đã cho phép nhắc việc → đặt lời nhắc.
        expect(reminder.scheduled.keys, [task.id]);

        final params = analytics.paramsOf('add_task').single!;
        expect(params['habit_key'], 'tea');
        expect(params['repeat'], 'daily');
        expect(params['source'], 'first_task');
        expect(params['duration_sec'], isA<int>());
        expect(params.values, isNot(contains(task.title)));
      });

      test('lưu lỗi → saveError, giữ lựa chọn, không log; Thử lại được',
          () async {
        final (c, vm, tasks, _, analytics, _) = await ready(failOnSave: true);
        vm.pick('family');
        vm.confirmPick();
        expect(await vm.save(), isFalse);
        expect(dataOf(c).saveError, contains('Bác'));
        expect(dataOf(c).step, FirstTaskStep.time);
        expect(dataOf(c).habitKey, 'family');
        expect(analytics.paramsOf('add_task'), isEmpty);

        tasks.failOnSave = false;
        expect(await vm.save(), isTrue);
        expect(dataOf(c).saveError, isNull);
      });

      test(
          'finish() sau khi lưu → onboarded = true, tutorial_complete đủ tham số',
          () async {
        final (c, vm, _, profiles, analytics, _) = await ready();
        vm.confirmPick();
        await vm.save();
        expect(await vm.finish(), isTrue);

        expect((await profiles.watch('u1').first).onboarded, isTrue);
        final params = analytics.paramsOf('tutorial_complete').single!;
        expect(params, {
          'font_size': 'lon',
          'notifications_on': true,
          'has_first_task': true,
        });
        // Không chứa tên Bác / tên việc.
        expect(params.values, isNot(contains('Lan')));
        expect(params.values, isNot(contains(dataOf(c).title)));
      });

      test(
          '"Để sau" (không có việc đầu tiên) vẫn markOnboarded, has_first_task = false',
          () async {
        final (c, vm, tasks, profiles, analytics, _) =
            await ready(notificationsOn: false);
        c.read(fontScaleProvider.notifier).set(AppFontScale.ratLon);
        expect(await vm.finish(), isTrue);

        expect(tasks.saved, isEmpty);
        expect((await profiles.watch('u1').first).onboarded, isTrue);
        expect(analytics.paramsOf('tutorial_complete').single, {
          'font_size': 'rat_lon',
          'notifications_on': false,
          'has_first_task': false,
        });
      });

      test('markOnboarded lỗi → saveError, không log tutorial_complete',
          () async {
        final analytics = RecordingAnalytics();
        // Hồ sơ chưa chọn vai trò Bác → FakeProfileService ném AppException.
        final profiles = FakeProfileService([const UserProfile(uid: 'u1')]);
        addTearDown(profiles.dispose);
        final c = containerWith(
            auth: FakeAuthService(signedIn: lan),
            profiles: profiles,
            analytics: analytics);
        await settled(c, firstTaskViewModelProvider);
        final vm = c.read(firstTaskViewModelProvider.notifier);

        expect(await vm.finish(), isFalse);
        expect(dataOf(c).saveError, isNotNull);
        expect(dataOf(c).saving, isFalse);
        expect(analytics.paramsOf('tutorial_complete'), isEmpty);
      });
    });
  });
}
