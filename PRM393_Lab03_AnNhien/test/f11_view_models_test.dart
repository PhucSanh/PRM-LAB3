import 'dart:async';

import 'package:an_nhien/models/relative.dart';
import 'package:an_nhien/services/contact_launcher_service.dart';
import 'package:an_nhien/services/contacts_service.dart';
import 'package:an_nhien/services/family_repository.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/family_view_model.dart';
import 'package:an_nhien/viewmodels/relative_form_view_model.dart';
import 'package:an_nhien/viewmodels/share_message_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

/// F11 bước 01: khung 3 ViewModel build được bằng service Fake, không cần mạng.
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

/// FamilyRepository giả có dữ liệu mẫu Figma (S09 / N21: Mai, Hùng, Bin) và cờ lỗi.
/// (`FakeFamilyRepository` của Hiếu không nhận seed nên test dùng bản riêng.)
class SeededFamilyRepository implements FamilyRepository {
  SeededFamilyRepository([List<Relative>? seed, this.failOnLoad = false])
      : _items = [...(seed ?? figma)];

  static const figma = [
    Relative(id: 'r1', name: 'Mai', relation: 'Con', phone: '0912345678'),
    Relative(id: 'r2', name: 'Hùng', relation: 'Con', phone: '0903222111'),
    Relative(id: 'r3', name: 'Bin', relation: 'Cháu', phone: '0987654321'),
  ];

  final List<Relative> _items;
  bool failOnLoad;

  @override
  Future<List<Relative>> all() async {
    if (failOnLoad) {
      throw const AppException('Chưa có mạng. Bác thử lại sau nhé.');
    }
    return List.unmodifiable(_items);
  }

  @override
  Future<void> save(Relative relative) async => _items
    ..removeWhere((r) => r.id == relative.id)
    ..add(relative);

  @override
  Future<void> delete(String id) async => _items.removeWhere((r) => r.id == id);
}

ProviderContainer container(FamilyRepository family) {
  final c = ProviderContainer(overrides: [
    familyRepositoryProvider.overrideWithValue(family),
    contactsServiceProvider.overrideWithValue(FakeContactsService()),
    contactLauncherServiceProvider
        .overrideWithValue(FakeContactLauncherService()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('FamilyViewModel (S09, S09b, N21)', () {
    test('có người thân → Data, chưa có banner', () async {
      final c = container(SeededFamilyRepository());
      await settled(c, familyViewModelProvider);
      final state = c.read(familyViewModelProvider);
      expect(state, isA<UiData<FamilyList>>());
      final data = (state as UiData<FamilyList>).data;
      expect(data.relatives.map((r) => r.name), ['Mai', 'Hùng', 'Bin']);
      expect(data.justAdded, isNull);
      expect(data.justDeleted, isNull);
    });

    test('chưa có ai → Empty', () async {
      final c = container(SeededFamilyRepository(const []));
      await settled(c, familyViewModelProvider);
      expect(c.read(familyViewModelProvider), isA<UiEmpty<FamilyList>>());
    });

    test('lỗi → Error có câu cho Bác; Thử lại → Data', () async {
      final repo = SeededFamilyRepository(null, true);
      final c = container(repo);
      await settled(c, familyViewModelProvider);
      final err = c.read(familyViewModelProvider);
      expect(err, isA<UiError<FamilyList>>());
      expect((err as UiError).message, 'Chưa có mạng. Bác thử lại sau nhé.');
      repo.failOnLoad = false;
      await c.read(familyViewModelProvider.notifier).retry();
      expect(c.read(familyViewModelProvider), isA<UiData<FamilyList>>());
    });

    test('relativeTitle = quan hệ + tên (N15 / N21 / N10)', () {
      expect(relativeTitle(SeededFamilyRepository.figma.first), 'Con Mai');
    });
  });

  group('RelativeFormViewModel (S12, S12a, S12e, N09, N15)', () {
    test('thêm mới: Data ngay, form S12a, quan hệ mặc định "Khác"', () {
      final c = container(SeededFamilyRepository());
      final state = c.read(relativeFormViewModelProvider(null));
      final form = (state as UiData<RelativeForm>).data;
      expect(form.isEdit, isFalse);
      expect(form.step, RelativeFormStep.manual);
      expect(form.relation, 'Khác');
      expect(form.name, isEmpty);
      expect(form.phone, isEmpty);
      expect(form.dirty, isFalse);
      expect(form.fromContacts, isFalse);
      expect(form.contactsAccess, ContactsAccess.unknown);
      expect(relativeRelations, ['Con', 'Cháu', 'Bạn bè', 'Khác']);
    });

    test('nhập tay cập nhật ô + bật dirty', () {
      final c = container(SeededFamilyRepository());
      final vm = c.read(relativeFormViewModelProvider(null).notifier);
      vm.setName('Mai');
      vm.setRelation('Con');
      vm.setPhone('0912345678');
      final form =
          (c.read(relativeFormViewModelProvider(null)) as UiData<RelativeForm>)
              .data;
      expect(form.step, RelativeFormStep.manual);
      expect((form.name, form.relation, form.phone),
          ('Mai', 'Con', '0912 345 678'));
      expect(form.dirty, isTrue);
    });

    test('sửa: nạp đúng người thân, số hiển thị 4-3-3', () async {
      final c = container(SeededFamilyRepository());
      final sub = c.listen(relativeFormViewModelProvider('r1'), (_, __) {});
      addTearDown(sub.close);
      await settled(c, relativeFormViewModelProvider('r1'));
      final form =
          (c.read(relativeFormViewModelProvider('r1')) as UiData<RelativeForm>)
              .data;
      expect(form.isEdit, isTrue);
      expect(form.step, RelativeFormStep.manual);
      expect((form.name, form.relation, form.phone),
          ('Mai', 'Con', '0912 345 678'));
    });

    test('sửa: không tìm thấy → Empty; lỗi → Error', () async {
      final c = container(SeededFamilyRepository());
      final sub = c.listen(relativeFormViewModelProvider('x'), (_, __) {});
      addTearDown(sub.close);
      await settled(c, relativeFormViewModelProvider('x'));
      expect(c.read(relativeFormViewModelProvider('x')),
          isA<UiEmpty<RelativeForm>>());

      final c2 = container(SeededFamilyRepository(null, true));
      final sub2 = c2.listen(relativeFormViewModelProvider('r1'), (_, __) {});
      addTearDown(sub2.close);
      await settled(c2, relativeFormViewModelProvider('r1'));
      expect(c2.read(relativeFormViewModelProvider('r1')),
          isA<UiError<RelativeForm>>());
    });

    test('số điện thoại: chuẩn hoá, kiểm tra, hiển thị 4-3-3', () {
      expect(phoneDigits('0912 345 678'), '0912345678');
      expect(phoneDigits('+84 912 345 678'), '0912345678');
      expect(isValidPhone('+84 912 345 678'), isTrue);
      expect(isValidPhone('0912.345.678'), isTrue);
      expect(isValidPhone('091234'), isFalse);
      expect(isValidPhone(''), isFalse);
      expect(isValidPhone('1912345678'), isFalse);
      expect(formatPhone('0912345678'), '0912 345 678');
      expect(formatPhone('0912'), '0912');
    });
  });

  group('ShareMessageViewModel (S17, S17b, N10)', () {
    test('nạp người nhận, kênh mặc định Zalo, chưa mở app', () async {
      final c = container(SeededFamilyRepository());
      final sub = c.listen(shareMessageViewModelProvider('r1'), (_, __) {});
      addTearDown(sub.close);
      await settled(c, shareMessageViewModelProvider('r1'));
      final msg =
          (c.read(shareMessageViewModelProvider('r1')) as UiData<ShareMessage>)
              .data;
      expect(msg.recipient.name, 'Mai');
      expect(msg.channel, ShareChannel.zalo);
      expect(msg.text, figmaSampleMessage);
      expect(msg.opened, isFalse);
    });

    test('đổi kênh sang SMS', () async {
      final c = container(SeededFamilyRepository());
      final sub = c.listen(shareMessageViewModelProvider('r1'), (_, __) {});
      addTearDown(sub.close);
      await settled(c, shareMessageViewModelProvider('r1'));
      c
          .read(shareMessageViewModelProvider('r1').notifier)
          .selectChannel(ShareChannel.sms);
      final msg =
          (c.read(shareMessageViewModelProvider('r1')) as UiData<ShareMessage>)
              .data;
      expect(msg.channel, ShareChannel.sms);
    });

    test('không tìm thấy người nhận → Empty', () async {
      final c = container(SeededFamilyRepository());
      final sub = c.listen(shareMessageViewModelProvider('x'), (_, __) {});
      addTearDown(sub.close);
      await settled(c, shareMessageViewModelProvider('x'));
      expect(c.read(shareMessageViewModelProvider('x')),
          isA<UiEmpty<ShareMessage>>());
    });
  });
}
