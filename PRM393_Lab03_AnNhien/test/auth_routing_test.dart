import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'dart:async';
import 'package:an_nhien/models/app_notification.dart';
import 'package:an_nhien/services/messaging_service.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/session_data_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/account_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class RetryProfiles extends FakeProfileService {
  int attempts = 0;
  @override
  Future<void> ensureProfile(AppUser user) async {
    if (++attempts == 1) throw StateError('offline');
    await super.ensureProfile(user);
  }
}

class PushMessages extends FakeMessagingService {
  final opened = StreamController<AppNotification>.broadcast();
  @override
  Stream<AppNotification> get onOpened => opened.stream;
}

void main() {
  test('real login is enabled without opt-in flags', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(authGuardEnabledProvider), isTrue);
  });
  testWidgets(
      'notification opens approved destination and never bypasses signed-out gate',
      (tester) async {
    final auth = FakeAuthService(signedIn: const AppUser(uid: 'u'));
    final profiles = FakeProfileService(
        [const UserProfile(uid: 'u', role: UserRole.elder, onboarded: true)]);
    final push = PushMessages();
    final container = makeContainer(auth, profiles, messages: push);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    void open(String route) => push.opened.add(AppNotification(
        id: 'n',
        title: '',
        body: '',
        receivedAt: DateTime(2026),
        route: route));
    open('/reminder/a');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/reminder/a');
    open('https://evil.test');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/inbox');
    await auth.signOut();
    await tester.pumpAndSettle();
    open('/reminder/a');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await profiles.dispose();
    await push.opened.close();
  });
  testWidgets(
      'public introduction CTA still requires sign-in for protected home',
      (tester) async {
    final container = makeContainer(FakeAuthService(), FakeProfileService(),
        initialRoute: '/intro');
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/intro');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/sign-in');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'profile failure stays behind gate; retry reaches role at large text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final profiles = RetryProfiles();
    final container = makeContainer(
        FakeAuthService(signedIn: const AppUser(uid: 'u')), profiles);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    expect(router.routeInformationProvider.value.uri.path, '/session');
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/role');
    expect(tester.takeException(), isNull);
    router.go('/account');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await profiles.dispose();
  });

  for (final entry in <UserProfile, String>{
    const UserProfile(uid: 'u'): '/role',
    const UserProfile(uid: 'u', role: UserRole.elder): '/welcome',
    const UserProfile(uid: 'u', role: UserRole.elder, onboarded: true):
        '/calendar',
    const UserProfile(uid: 'u', role: UserRole.caregiver): '/activities',
    const UserProfile(uid: 'u', role: UserRole.caregiver, pairedMomUid: 'mom'):
        '/caregiver/schedule',
  }.entries) {
    testWidgets('restored profile routes to ${entry.value}', (tester) async {
      final auth = FakeAuthService(signedIn: const AppUser(uid: 'u'));
      final profiles = FakeProfileService([entry.key]);
      final container = makeContainer(auth, profiles);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      expect(router.routeInformationProvider.value.uri.path, entry.value);
      router.go('/sign-in');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, entry.value);
      if (entry.key.role == UserRole.caregiver && entry.key.pairedMomUid == null) {
        // Pairing is optional: browsing and settings remain reachable.
        for (final path in ['/settings', '/caregiver/schedule', '/activities']) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, path);
        }
        router.go('/caregiver/pair');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Để sau, khám phá ứng dụng'));
        await tester.tap(find.text('Để sau, khám phá ứng dụng'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/activities');
      }
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/sign-in');
      router.go('/family');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/sign-in');
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await profiles.dispose();
    });
  }

  for (final role in UserRole.values) {
    testWidgets('new account saves $role and logout clears local data',
        (tester) async {
      final auth = FakeAuthService(signedIn: const AppUser(uid: 'new'));
      final profiles = FakeProfileService();
      final cache = FakeSessionDataService();
      final container = makeContainer(auth, profiles, cache: cache);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      expect(router.routeInformationProvider.value.uri.path, '/role');
      final vm = container.read(roleViewModelProvider.notifier);
      vm.select(role);
      await vm.submit();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path,
          role == UserRole.elder ? '/welcome' : '/activities');
      expect((await tester.runAsync(() => profiles.watch('new').first))!.role,
          role);
      router.go('/account');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(cache.clearCount, 0);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNotNull);
      await tester.ensureVisible(find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
      await tester.pumpAndSettle();
      expect(cache.clearCount, 1);
      expect(auth.currentUser, isNull);
      expect(router.routeInformationProvider.value.uri.path, '/sign-in');
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await profiles.dispose();
    });
  }
}

ProviderContainer makeContainer(FakeAuthService auth, ProfileService profiles,
        {FakeSessionDataService? cache,
        MessagingService? messages,
        String initialRoute = '/calendar'}) =>
    ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue(initialRoute),
      settingsServiceProvider.overrideWithValue(FakeSettingsService()),
      suggestionServiceProvider
          .overrideWithValue(FakeSuggestionService(delay: Duration.zero)),
      reminderServiceProvider.overrideWithValue(FakeReminderService()),
      caregiverScheduleServiceProvider
          .overrideWithValue(FakeCaregiverScheduleService()),
      authServiceProvider.overrideWithValue(auth),
      profileServiceProvider.overrideWithValue(profiles),
      messagingServiceProvider
          .overrideWithValue(messages ?? FakeMessagingService()),
      sessionDataServiceProvider
          .overrideWithValue(cache ?? FakeSessionDataService()),
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository([])),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
