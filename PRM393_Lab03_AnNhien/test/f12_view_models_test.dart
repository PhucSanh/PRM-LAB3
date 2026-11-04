import 'dart:async';

import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/suggestion.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/suggestion_compose_view_model.dart';
import 'package:an_nhien/viewmodels/suggestion_inbox_view_model.dart';
import 'package:an_nhien/viewmodels/suggestion_review_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

/// F12 bước 01: khung 3 ViewModel chạy bằng service Fake, không cần mạng.
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

const momUid = 'mom-uid';
const mom = AppUser(uid: momUid, displayName: 'Bác Lan');
const caregiver = AppUser(uid: 'mai-uid', displayName: 'Mai');

ProviderContainer device(AppUser user, FakeSuggestionService suggestions,
    {List<UserProfile> profiles = const [], FakeTaskRepository? tasks}) {
  final c = ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(FakeAuthService(signedIn: user)),
    profileServiceProvider.overrideWithValue(FakeProfileService(profiles)),
    suggestionServiceProvider.overrideWithValue(suggestions),
    habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
    taskRepositoryProvider
        .overrideWithValue(tasks ?? FakeTaskRepository(const [])),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late FakeSuggestionService service;

  setUp(() => service = FakeSuggestionService(delay: Duration.zero));
  tearDown(() => service.dispose());

  group('SuggestionInboxViewModel (G10 – G12)', () {
    test('không có gợi ý chờ → Empty', () async {
      final c = device(mom, service);
      await settled(c, suggestionInboxViewModelProvider);
      expect(c.read(suggestionInboxViewModelProvider),
          isA<UiEmpty<SuggestionInbox>>());
    });

    test(
        'có gợi ý mẫu → pendingCard + popupToShow đúng tên provider của thẻ G12',
        () async {
      await service.send(momUid, FakeSuggestionService.figmaSample());
      final c = device(mom, service);
      await settled(c, suggestionInboxViewModelProvider);
      final data =
          (c.read(suggestionInboxViewModelProvider) as UiData<SuggestionInbox>)
              .data;
      expect(data.pendingCard!.fromName, 'Mai');
      expect(data.pendingCard!.items.length, 2);
      expect(data.popupToShow!.id, data.pendingCard!.id);

      await service.markPopupShown(momUid, data.pendingCard!.id);
      await pumpEventQueue();
      final after =
          (c.read(suggestionInboxViewModelProvider) as UiData<SuggestionInbox>)
              .data;
      expect(after.popupToShow, isNull); // popup không hiện lại.
      expect(after.pendingCard, isNotNull); // thẻ G12 vẫn còn.
    });

    test('2 máy: con cháu gửi khi Bác đang mở app → hộp cập nhật', () async {
      final momDevice = device(mom, service);
      final sub =
          momDevice.listen(suggestionInboxViewModelProvider, (_, __) {});
      await settled(momDevice, suggestionInboxViewModelProvider);
      expect(sub.read(), isA<UiEmpty<SuggestionInbox>>());

      await service.send(momUid, FakeSuggestionService.figmaSample(id: ''));
      await pumpEventQueue();
      expect(sub.read(), isA<UiData<SuggestionInbox>>());
      sub.close();
    });

    test('lỗi tải → Error có câu cho Bác; Thử lại → Data', () async {
      await service.send(momUid, FakeSuggestionService.figmaSample());
      service.failOnLoad = true;
      final c = device(mom, service);
      final sub = c.listen(suggestionInboxViewModelProvider, (_, __) {});
      await settled(c, suggestionInboxViewModelProvider);
      expect((sub.read() as UiError).message, contains('Thử lại'));

      service.failOnLoad = false;
      c.read(suggestionInboxViewModelProvider.notifier).retry();
      await settled(c, suggestionInboxViewModelProvider);
      expect(sub.read(), isA<UiData<SuggestionInbox>>());
      sub.close();
    });
  });

  group('SuggestionReviewViewModel (G03 – G09)', () {
    test('mở gợi ý → Data reviewing, giờ theo gợi ý, chọn sẵn mọi việc, 1 chạm',
        () async {
      await service.send(momUid, FakeSuggestionService.figmaSample(id: 'g1'));
      final tasks = FakeTaskRepository(const []);
      final c = device(mom, service, tasks: tasks);
      final p = suggestionReviewViewModelProvider(
          (id: 'g1', entry: SuggestionEntry.card));
      final sub = c.listen(p, (_, __) {});
      await settled(c, p);
      final data = (sub.read() as UiData<SuggestionReview>).data;
      expect(data.step, SuggestionReviewStep.reviewing);
      expect(data.times, const [SuggestionTime(8, 0), SuggestionTime(9, 0)]);
      expect(data.selected, {0, 1});
      expect(data.taps, 1);
      expect(data.changedTime(0), isFalse);
      // Lịch Bác chưa đổi khi mới xem.
      expect(await tasks.tasksForDay(DateTime.now()), isEmpty);
      sub.close();
    });

    test('gợi ý partial → chỉ chọn sẵn việc chưa nhận', () async {
      final s = FakeSuggestionService.figmaSample(id: 'g1');
      await service.send(momUid, s);
      await service.accept(momUid, 'g1', [s.items.first]);
      final c = device(mom, service);
      final p = suggestionReviewViewModelProvider(
          (id: 'g1', entry: SuggestionEntry.card));
      final sub = c.listen(p, (_, __) {});
      await settled(c, p);
      expect((sub.read() as UiData<SuggestionReview>).data.selected, {1});
      sub.close();
    });

    test('id không có → Empty', () async {
      final c = device(mom, service);
      final p = suggestionReviewViewModelProvider(
          (id: 'nope', entry: SuggestionEntry.card));
      final sub = c.listen(p, (_, __) {});
      await settled(c, p);
      expect(sub.read(), isA<UiEmpty<SuggestionReview>>());
      sub.close();
    });

    test('lỗi tải → Error; Thử lại → Data', () async {
      await service.send(momUid, FakeSuggestionService.figmaSample(id: 'g1'));
      service.failOnLoad = true;
      final c = device(mom, service);
      final p = suggestionReviewViewModelProvider(
          (id: 'g1', entry: SuggestionEntry.card));
      final sub = c.listen(p, (_, __) {});
      await settled(c, p);
      expect(sub.read(), isA<UiError<SuggestionReview>>());

      service.failOnLoad = false;
      await c.read(p.notifier).load();
      expect(sub.read(), isA<UiData<SuggestionReview>>());
      sub.close();
    });
  });

  group('SuggestionComposeViewModel (G01 – G02)', () {
    test('đã ghép nối → compose với momUid', () async {
      final c = device(caregiver, service, profiles: const [
        UserProfile(
            uid: 'mai-uid',
            displayName: 'Mai',
            role: UserRole.caregiver,
            pairedMomUid: momUid),
      ]);
      final sub = c.listen(suggestionComposeViewModelProvider, (_, __) {});
      await settled(c, suggestionComposeViewModelProvider);
      final data = (sub.read() as UiData<SuggestionCompose>).data;
      expect(data.step, SuggestionComposeStep.compose);
      expect(data.momUid, momUid);
      expect(data.fromName, 'Mai');
      sub.close();
    });

    test('chưa ghép nối → needsPairing', () async {
      final c = device(caregiver, service, profiles: const [
        UserProfile(uid: 'mai-uid', role: UserRole.caregiver),
      ]);
      final sub = c.listen(suggestionComposeViewModelProvider, (_, __) {});
      await settled(c, suggestionComposeViewModelProvider);
      final data = (sub.read() as UiData<SuggestionCompose>).data;
      expect(data.needsPairing, isTrue);
      expect(data.momUid, isNull);
      sub.close();
    });
  });
}
