import 'dart:async';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/session_data_service.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/account_view_model.dart';
import 'package:an_nhien/viewmodels/sign_in_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class BrokenCache implements SessionDataService {
  @override
  Future<void> clearLocalData() async => throw AppException.network;
}

class BrokenTelemetry extends FakeCrashService {
  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {String? reason}) async =>
      throw StateError('telemetry unavailable');
}

class DeferredProfiles extends FakeProfileService {
  final pending = Completer<void>();
  int saves = 0;
  @override
  Future<void> setRole(String uid, UserRole role) {
    saves++;
    return pending.future;
  }
}

class PendingAuth extends FakeAuthService {
  final pending = Completer<AppUser>();
  int attempts = 0;
  @override
  Future<AppUser> signInWithGoogle() {
    attempts++;
    return pending.future;
  }
}

class BrokenAnalytics extends FakeAnalyticsService {
  @override
  Future<void> setUserId(String? uid) async =>
      throw StateError('analytics unavailable');
}

void main() {
  for (final error in [AppException.cancelled, AppException.network]) {
    test('sign-in handles $error and ignores duplicate taps', () async {
      final auth = PendingAuth();
      final cache = FakeSessionDataService();
      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(auth),
        sessionDataServiceProvider.overrideWithValue(cache),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(signInViewModelProvider.notifier);
      final pending = vm.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      await vm.signInWithGoogle();
      expect(auth.attempts, 1);
      expect(cache.clearCount, 1);
      auth.pending.completeError(error);
      await pending;
      expect(container.read(signInViewModelProvider).busy, false);
      expect(
          container.read(signInViewModelProvider).message, error.userMessage);
    });
  }
  test('analytics failure does not undo successful authentication', () async {
    final auth = FakeAuthService();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
      sessionDataServiceProvider.overrideWithValue(FakeSessionDataService()),
      analyticsServiceProvider.overrideWithValue(BrokenAnalytics()),
    ]);
    addTearDown(container.dispose);
    await container.read(signInViewModelProvider.notifier).signInWithGoogle();
    expect(auth.currentUser, isNotNull);
    expect(container.read(signInViewModelProvider).message, isNull);
  });

  test('logout still ends auth when cache and crash reporting fail', () async {
    final auth = FakeAuthService(signedIn: const AppUser(uid: 'u'));
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
      sessionDataServiceProvider.overrideWithValue(BrokenCache()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(BrokenTelemetry()),
    ]);
    addTearDown(container.dispose);
    await container.read(signOutViewModelProvider.notifier).signOut();
    expect(auth.currentUser, isNull);
    expect(container.read(signOutViewModelProvider).busy, false);
    expect(container.read(signOutViewModelProvider).message, isNotNull);
    await container.read(signInViewModelProvider.notifier).signInWithGoogle();
    expect(auth.currentUser, isNull,
        reason: 'Do not allow another account before cache cleanup succeeds');
    expect(container.read(signInViewModelProvider).message,
        AppException.network.userMessage);
  });
  test('role save ignores duplicate taps and retains selection on failure',
      () async {
    final profiles = DeferredProfiles();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'u'))),
      profileServiceProvider.overrideWithValue(profiles),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(BrokenTelemetry()),
    ]);
    addTearDown(container.dispose);
    addTearDown(profiles.dispose);
    final vm = container.read(roleViewModelProvider.notifier);
    vm.select(UserRole.caregiver);
    final saving = vm.submit();
    await vm.submit();
    vm.select(UserRole.elder);
    expect(profiles.saves, 1);
    profiles.pending.completeError(AppException.network);
    await saving;
    final result =
        (container.read(roleViewModelProvider) as UiData<RoleSelection>).data;
    expect(result.role, UserRole.caregiver);
    expect(result.busy, false);
    expect(result.message, AppException.network.userMessage);
  });
  test('bootstrap preserves existing role and onboarding', () async {
    final profiles = FakeProfileService(
        [const UserProfile(uid: 'u', role: UserRole.elder, onboarded: true)]);
    addTearDown(profiles.dispose);
    await profiles.ensureProfile(
        const AppUser(uid: 'u', displayName: 'Updated Google name'));
    final value = await profiles.watch('u').first;
    expect(value.role, UserRole.elder);
    expect(value.onboarded, true);
    await expectLater(profiles.setRole('u', UserRole.caregiver),
        throwsA(isA<AppException>()));
    expect(() => UserProfile.fromMap('u', {'role': 'admin'}),
        throwsFormatException);
  });
}
