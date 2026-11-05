import 'package:an_nhien/services/contact_launcher_service.dart';
import 'package:an_nhien/services/contacts_service.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

/// F11 bước 01: service danh bạ + mở gọi điện / Zalo / SMS (bản Fake).
void main() {
  group('FakeContactsService', () {
    test('danh bạ mẫu đúng Figma S12 1:2146', () async {
      final s = FakeContactsService(alreadyGranted: true);
      final all = await s.list();
      expect(
          all.map((c) => c.name), ['Mai', 'Hùng', 'Bin', 'Cô Tám', 'Chị Hoa']);
      expect(all.first.label, 'Con gái');
      expect(all.first.phone, '0912 345 678');
    });

    test('lọc theo tên, không phân biệt hoa / thường và dấu', () async {
      final s = FakeContactsService(alreadyGranted: true);
      expect((await s.list(query: 'hung')).map((c) => c.name), ['Hùng']);
      expect((await s.list(query: 'MAI')).map((c) => c.name), ['Mai']);
      expect((await s.list(query: 'tám')).map((c) => c.name), ['Cô Tám']);
      expect((await s.list(query: 'chi')).map((c) => c.name), ['Chị Hoa']);
      expect(await s.list(query: 'xyz'), isEmpty);
      expect(await s.list(query: '  '), hasLength(5));
    });

    test('chưa có quyền → hỏi; cho phép → đọc được, không hỏi lại', () async {
      final s = FakeContactsService();
      expect(await s.hasPermission(), isFalse);
      expect(await s.requestPermission(), isTrue);
      expect(await s.hasPermission(), isTrue);
      expect(await s.requestPermission(), isTrue);
      expect(s.requestCount, 1);
      expect(await s.list(), hasLength(5));
    });

    test('từ chối quyền → requestPermission false, list ném AppException',
        () async {
      final s = FakeContactsService(granted: false);
      expect(await s.requestPermission(), isFalse);
      expect(await s.hasPermission(), isFalse);
      await expectLater(s.list(), throwsA(isA<AppException>()));
    });

    test('cờ failOnList → AppException có câu cho Bác', () async {
      final s = FakeContactsService(alreadyGranted: true, failOnList: true);
      await expectLater(
          s.list(),
          throwsA(isA<AppException>().having(
              (e) => e.userMessage, 'userMessage', contains('tự nhập'))));
    });
  });

  group('FakeContactLauncherService', () {
    test('ghi đúng số / nội dung từng lần mở', () async {
      final s = FakeContactLauncherService();
      expect(await s.call('0912345678'), isTrue);
      expect(await s.openZalo('0912345678', 'Mẹ nhớ con.'), isTrue);
      expect(await s.openSms('0903222111', 'Chào con'), isTrue);
      expect(s.launched.map((r) => (r.kind, r.phone, r.text)), [
        ('call', '0912345678', null),
        ('zalo', '0912345678', 'Mẹ nhớ con.'),
        ('sms', '0903222111', 'Chào con'),
      ]);
    });

    test('máy không có app → false, không ghi lần mở', () async {
      final s =
          FakeContactLauncherService(noZalo: true, noSms: true, noDialer: true);
      expect(await s.openZalo('0912345678', 'x'), isFalse);
      expect(await s.openSms('0912345678', 'x'), isFalse);
      expect(await s.call('0912345678'), isFalse);
      expect(s.launched, isEmpty);
    });

    test('cờ lỗi → ném AppException', () async {
      final s = FakeContactLauncherService(
          failOnCall: true, failOnZalo: true, failOnSms: true);
      await expectLater(s.call('1'), throwsA(isA<AppException>()));
      await expectLater(s.openZalo('1', 'x'), throwsA(isA<AppException>()));
      await expectLater(s.openSms('1', 'x'), throwsA(isA<AppException>()));
      expect(s.launched, isEmpty);
    });

    test('ShareChannel.name = method của event share', () {
      expect(ShareChannel.values.map((c) => c.name), ['zalo', 'sms']);
    });
  });

  test('foldVietnamese bỏ dấu + chữ thường', () {
    expect(foldVietnamese('Hùng'), 'hung');
    expect(foldVietnamese('Cô Tám'), 'co tam');
    expect(foldVietnamese('Đào'), 'dao');
  });
}
