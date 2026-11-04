import 'dart:async';

import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/profile_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// F8: ProfileViewModel (N06) chạy bằng Fake.
Future<UiState<ProfileForm>> settled(ProviderContainer c) async {
  final ready = Completer<void>();
  final sub = c.listen(profileViewModelProvider, (_, next) {
    if (next is! UiLoading<ProfileForm> && !ready.isCompleted) {
      ready.complete();
    }
  }, fireImmediately: true);
  try {
    await ready.future.timeout(const Duration(seconds: 5));
  } finally {
    sub.close();
  }
  return c.read(profileViewModelProvider);
}

/// `watchSetup` lỗi cho tới khi tắt cờ [broken].
class BrokenProfileSetupService extends FakeProfileSetupService {
  BrokenProfileSetupService({super.seed}) : super(delay: Duration.zero);
  bool broken = true;

  @override
  Stream<ProfileSetup?> watchSetup(String uid) => broken
      ? Stream.error(const AppException('Chưa có mạng. Bác thử lại sau nhé.'))
      : super.watchSetup(uid);
}

/// Ghi lại lý do lỗi non-fatal.
class RecordingCrash extends FakeCrashService {
  final reasons = <String?>[];

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason}) async {
    reasons.add(reason);
  }
}

const _lan = ProfileSetup(
    displayName: 'Lan', honorific: Honorific.ba, wakeHour: 5, wakeMinute: 30);

ProfileForm formOf(ProviderContainer c) =>
    (c.read(profileViewModelProvider) as UiData<ProfileForm>).data;

void main() {
  late FakeProfileSetupService setup;
  late RecordingCrash crash;

  ProviderContainer containerWith({
    AppUser? signedIn = const AppUser(uid: 'u1', displayName: 'Bác Lan'),
    FakeProfileSetupService? service,
    Map<String, ProfileSetup> seed = const {'u1': _lan},
  }) {
    setup =
        service ?? FakeProfileSetupService(delay: Duration.zero, seed: seed);
    crash = RecordingCrash();
    final c = ProviderContainer(overrides: [
      authServiceProvider
          .overrideWithValue(FakeAuthService(signedIn: signedIn)),
      profileServiceProvider.overrideWithValue(FakeProfileService(const [
        UserProfile(uid: 'u1', displayName: 'Lan', role: UserRole.elder),
      ])),
      profileSetupServiceProvider.overrideWithValue(setup),
      crashServiceProvider.overrideWithValue(crash),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('ProfileViewModel · nạp', () {
    test('bắt đầu Loading', () {
      final c = containerWith();
      expect(c.read(profileViewModelProvider), isA<UiLoading<ProfileForm>>());
    });

    test('load() → UiData: tên, cách gọi, giờ thức dậy đã lưu', () async {
      final c = containerWith();
      final state = await settled(c);
      expect(state, isA<UiData<ProfileForm>>());
      final form = formOf(c);
      expect(form.displayName, 'Lan');
      expect(form.honorific, Honorific.ba);
      expect(form.wakeTime, const TimeOfDay(hour: 5, minute: 30));
      expect(form.dirty, isFalse);
      expect(form.saving, isFalse);
      expect(form.nameError, isNull);
    });

    test('chưa lưu hồ sơ S02 → tên từ tài khoản, mặc định Ông, 6:00', () async {
      final c = containerWith(seed: const {});
      await settled(c);
      final form = formOf(c);
      expect(form.displayName, 'Lan');
      expect(form.honorific, Honorific.ong);
      expect(form.wakeTime, const TimeOfDay(hour: 6, minute: 0));
    });

    test('chưa đăng nhập → UiError có câu cho Bác', () async {
      final state = await settled(containerWith(signedIn: null));
      expect(state, isA<UiError<ProfileForm>>());
      expect((state as UiError).message, contains('đăng nhập'));
    });

    test('Fake lỗi → UiError + recordError; retry() → UiData', () async {
      final broken = BrokenProfileSetupService(seed: const {'u1': _lan});
      final c = containerWith(service: broken);
      final state = await settled(c);
      expect(state, isA<UiError<ProfileForm>>());
      expect((state as UiError).message, 'Chưa có mạng. Bác thử lại sau nhé.');
      expect(crash.reasons, contains('load_profile'));

      broken.broken = false;
      await c.read(profileViewModelProvider.notifier).retry();
      expect(c.read(profileViewModelProvider), isA<UiData<ProfileForm>>());
      expect(formOf(c).displayName, 'Lan');
    });
  });

  group('ProfileViewModel · sửa + lưu', () {
    test('sửa bật dirty; sửa về như cũ thì tắt dirty', () async {
      final c = containerWith();
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);

      vm.changeName('Lan Anh');
      expect(formOf(c).dirty, isTrue);
      vm.changeName('  Lan ');
      expect(formOf(c).dirty, isFalse);

      vm.changeHonorific(Honorific.ong);
      expect(formOf(c).dirty, isTrue);
      vm.changeHonorific(Honorific.ba);
      vm.changeWakeTime(const TimeOfDay(hour: 7, minute: 0));
      expect(formOf(c).dirty, isTrue);
    });

    test('tên trống → nameError, không lưu; gõ lại thì ẩn lỗi', () async {
      final c = containerWith();
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);
      vm.changeName('   ');
      expect(await vm.save(), isNull);
      expect(formOf(c).nameError, 'Bác chưa nhập tên gọi.');
      expect(setup.saved['u1']!.toMap(), _lan.toMap());

      vm.changeName('L');
      expect(formOf(c).nameError, isNull);
    });

    test('tên quá dài → nameError, không lưu', () async {
      final c = containerWith();
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);
      vm.changeName('A' * (maxProfileNameLength + 1));
      expect(await vm.save(), isNull);
      expect(formOf(c).nameError, 'Tên gọi dài quá, Bác viết ngắn lại nhé.');
      expect(setup.saved['u1']!.toMap(), _lan.toMap());
    });

    test('lưu đúng giá trị vào Fake (tên gọn khoảng trắng), hết dirty',
        () async {
      final c = containerWith();
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);
      vm.changeName('  Lan   Anh ');
      vm.changeHonorific(Honorific.ong);
      vm.changeWakeTime(const TimeOfDay(hour: 6, minute: 15));

      final saved = await vm.save();
      expect(saved, isNotNull);
      expect(saved!.previous.toMap(), _lan.toMap());
      final stored = setup.saved['u1']!;
      expect(stored.displayName, 'Lan Anh');
      expect(stored.honorific, Honorific.ong);
      expect((stored.wakeHour, stored.wakeMinute), (6, 15));
      expect(formOf(c).displayName, 'Lan Anh');
      expect(formOf(c).dirty, isFalse);
    });

    test('failOnSave → trả null, saveError, giữ chữ đã gõ, ghi Crashlytics',
        () async {
      final c = containerWith(
          service: FakeProfileSetupService(
              failOnSave: true,
              delay: Duration.zero,
              seed: const {'u1': _lan}));
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);
      vm.changeName('Lan Anh');

      expect(await vm.save(), isNull);
      final form = formOf(c);
      expect(
          form.saveError, 'Chưa lưu được. Bác kiểm tra mạng rồi thử lại nhé.');
      expect(form.displayName, 'Lan Anh');
      expect(form.dirty, isTrue);
      expect(form.saving, isFalse);
      expect(crash.reasons, contains('save_profile'));
    });

    test('undo lưu lại bản cũ', () async {
      final c = containerWith();
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);
      vm.changeName('Lan Anh');
      vm.changeHonorific(Honorific.ong);
      final saved = await vm.save();

      expect(await vm.undo(saved!), isNull);
      expect(setup.saved['u1']!.toMap(), _lan.toMap());
      expect(formOf(c).displayName, 'Lan');
      expect(formOf(c).honorific, Honorific.ba);
      expect(formOf(c).dirty, isFalse);
    });

    test('discard bỏ thay đổi chưa lưu', () async {
      final c = containerWith();
      await settled(c);
      final vm = c.read(profileViewModelProvider.notifier);
      vm.changeName('Lan Anh');
      vm.changeWakeTime(const TimeOfDay(hour: 8, minute: 0));
      vm.discard();
      final form = formOf(c);
      expect(form.displayName, 'Lan');
      expect(form.wakeTime, const TimeOfDay(hour: 5, minute: 30));
      expect(form.dirty, isFalse);
      expect(setup.saved['u1']!.toMap(), _lan.toMap());
    });
  });

  group('FakeProfileSetupService.watchSetup', () {
    test('phát null rồi giá trị mới sau saveSetup', () async {
      final service = FakeProfileSetupService(delay: Duration.zero);
      final values = <ProfileSetup?>[];
      final sub = service.watchSetup('u1').listen(values.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await service.saveSetup('u1', _lan);
      await pumpEventQueue();
      expect(values.length, 2);
      expect(values.first, isNull);
      expect(values.last?.displayName, 'Lan');
    });
  });
}
