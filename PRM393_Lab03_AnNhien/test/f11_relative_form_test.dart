import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/relative.dart';
import 'package:an_nhien/screens/family/family_screen.dart';
import 'package:an_nhien/screens/family/relative_form_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/contact_launcher_service.dart';
import 'package:an_nhien/services/contacts_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/relative_form_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:an_nhien/widgets/app_text_field.dart';
import 'package:an_nhien/widgets/relative_card.dart';
import 'package:an_nhien/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'f11_view_models_test.dart' show SeededFamilyRepository;

/// F11 bước 03: S12 Thêm người thân (S12a / S12 tự nhập / S12e + danh bạ `1:2146`).

/// Ghi lại cả tham số event.
class RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async =>
      events.add((name, params));

  @override
  Future<void> setUserId(String? uid) async {}
}

class RecordingCrash extends FakeCrashService {
  final reasons = <String?>[];

  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {String? reason}) async =>
      reasons.add(reason);
}

/// Repo lưu lỗi theo cờ.
class FlakyFamilyRepository extends SeededFamilyRepository {
  FlakyFamilyRepository() : super(const []);
  bool failOnSave = true;

  @override
  Future<void> save(Relative relative) async {
    if (failOnSave) {
      throw const AppException('Chưa có mạng. Bác thử lại sau nhé.');
    }
    return super.save(relative);
  }
}

class _Deps {
  _Deps({SeededFamilyRepository? family, FakeContactsService? contacts})
      : family = family ?? SeededFamilyRepository(const []),
        contacts = contacts ?? FakeContactsService();

  final SeededFamilyRepository family;
  final FakeContactsService contacts;
  final analytics = RecordingAnalytics();
  final crash = RecordingCrash();
  final suggestions = FakeSuggestionService(delay: Duration.zero);

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      familyRepositoryProvider.overrideWithValue(family),
      contactsServiceProvider.overrideWithValue(contacts),
      contactLauncherServiceProvider
          .overrideWithValue(FakeContactLauncherService()),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(crash),
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'mom-uid'))),
      suggestionServiceProvider.overrideWithValue(suggestions),
    ]);
    addTearDown(c.dispose);
    addTearDown(suggestions.dispose);
    return c;
  }
}

final _add = relativeFormViewModelProvider(null);

/// Container + giữ provider autoDispose sống trong test.
(ProviderContainer, RelativeFormViewModel) _vm(_Deps deps) {
  final c = deps.container();
  final sub = c.listen(_add, (_, __) {});
  addTearDown(sub.close);
  return (c, c.read(_add.notifier));
}

RelativeForm _form(ProviderContainer c) =>
    (c.read(_add) as UiData<RelativeForm>).data;

void main() {
  group('RelativeFormViewModel – thêm mới', () {
    test('thiếu số → lỗi S12e, giữ tên + quan hệ, không lưu', () async {
      final deps = _Deps();
      final (c, vm) = _vm(deps);
      vm
        ..setName('Mai')
        ..setRelation('Con');
      expect(await vm.save(), isNull);
      final f = _form(c);
      expect(f.phoneError, 'Bác chưa nhập số điện thoại.');
      expect(f.nameError, isNull);
      expect((f.name, f.relation), ('Mai', 'Con'));
      expect(f.hadError, isTrue);
      expect(await deps.family.all(), isEmpty);
    });

    test('tên trống + số sai → 2 lỗi đã duyệt', () async {
      final (c, vm) = _vm(_Deps());
      vm.setPhone('0912');
      await vm.save();
      expect(_form(c).nameError, 'Bác chưa nhập tên gọi.');
      expect(_form(c).phoneError, 'Số điện thoại chưa đúng.');
      vm.setPhone('09123456ab');
      await vm.save();
      expect(_form(c).phoneError, 'Số điện thoại chưa đúng.');
    });

    test('sửa ô thì lỗi ô đó mất', () async {
      final (c, vm) = _vm(_Deps());
      await vm.save();
      vm.setPhone('0');
      expect(_form(c).phoneError, isNull);
      expect(_form(c).nameError, isNotNull);
    });

    test(
        '"+84 912 345 678" hợp lệ → lưu số 0912345678, log add_relative không tên / số',
        () async {
      final deps = _Deps();
      final (c, vm) = _vm(deps);
      vm
        ..setName(' Mai ')
        ..setRelation('Con')
        ..setPhone('+84 912 345 678');
      final saved = await vm.save();
      expect(saved?.name, 'Mai');
      expect(saved?.phone, '0912345678');
      expect((await deps.family.all()).single.relation, 'Con');
      expect(_form(c).saving, isFalse);
      final (name, params) = deps.analytics.events.single;
      expect(name, 'add_relative');
      expect(params,
          {'relation': 'con', 'from_contacts': false, 'had_error': false});
    });

    test('đã từng lỗi rồi sửa → had_error: true', () async {
      final deps = _Deps();
      final (_, vm) = _vm(deps);
      vm.setName('Mai');
      await vm.save();
      vm.setPhone('0912345678');
      expect(await vm.save(), isNotNull);
      expect(deps.analytics.events.single.$2?['had_error'], isTrue);
    });

    test(
        'từ chối quyền danh bạ → ở lại form + dòng gợi ý, vẫn tự nhập lưu được',
        () async {
      final deps = _Deps(contacts: FakeContactsService(granted: false));
      final (c, vm) = _vm(deps);
      await vm.pickFromContacts();
      expect(_form(c).step, RelativeFormStep.manual);
      expect(_form(c).contactsAccess, ContactsAccess.denied);
      expect(_form(c).contactsNotice, 'Bác có thể tự nhập tên và số ở dưới.');
      vm
        ..setName('Bin')
        ..setPhone('0987654321');
      expect(await vm.save(), isNotNull);
      expect(deps.analytics.events.single.$2?['from_contacts'], isFalse);
    });

    test(
        'danh bạ: mở danh sách, tìm, chọn → điền sẵn 4-3-3 + quan hệ, from_contacts: true',
        () async {
      final deps = _Deps();
      final (c, vm) = _vm(deps);
      await vm.pickFromContacts();
      expect(_form(c).step, RelativeFormStep.contacts);
      expect(_form(c).contacts, hasLength(5));
      await vm.search('hung');
      expect(_form(c).contacts.map((x) => x.name), ['Hùng']);
      vm.selectContact(_form(c).contacts.single);
      final f = _form(c);
      expect(f.step, RelativeFormStep.manual);
      expect((f.name, f.phone, f.relation, f.fromContacts),
          ('Hùng', '0903 222 111', 'Con', true));
      await vm.save();
      final params = deps.analytics.events.single.$2!;
      expect(params['from_contacts'], isTrue);
      expect(params.values.map((v) => '$v'),
          isNot(contains(anyOf('Hùng', '0903222111', '0903 222 111'))));
    });

    test('đọc danh bạ lỗi → về form với câu của service', () async {
      final (c, vm) = _vm(_Deps(
          contacts:
              FakeContactsService(alreadyGranted: true, failOnList: true)));
      await vm.pickFromContacts();
      expect(_form(c).step, RelativeFormStep.manual);
      expect(_form(c).contactsNotice, contains('tự nhập'));
    });

    test('lưu lỗi → saveError + Crashlytics, giữ dữ liệu', () async {
      final deps = _Deps(family: FlakyFamilyRepository());
      final (c, vm) = _vm(deps);
      vm
        ..setName('Mai')
        ..setPhone('0912345678');
      expect(await vm.save(), isNull);
      expect(_form(c).saveError, 'Chưa có mạng. Bác thử lại sau nhé.');
      expect(_form(c).saving, isFalse);
      expect(_form(c).name, 'Mai');
      expect(deps.crash.reasons, ['save_relative']);
      expect(deps.analytics.events, isEmpty);
    });

    test('nhãn liên hệ → 4 nhóm; chèn khoảng trắng khi gõ', () {
      expect(relationFromLabel('Con gái'), 'Con');
      expect(relationFromLabel('Cháu nội'), 'Cháu');
      expect(relationFromLabel('Bạn'), 'Bạn bè');
      expect(relationFromLabel('Hàng xóm'), 'Khác');
      expect(relationFromLabel(null), 'Khác');
      expect(formatPhoneInput('0912'), '0912');
      expect(formatPhoneInput('09123'), '0912 3');
      expect(formatPhoneInput('0912345678'), '0912 345 678');
      expect(formatPhoneInput('+84912'), '+84912');
      // Avatar = chữ cái của tên gọi (từ cuối), như Figma.
      expect(RelativeCard.initial('Cô Tám'), 'T');
      expect(RelativeCard.initial('Chị Hoa'), 'H');
      expect(RelativeCard.initial('Mai'), 'M');
    });
  });

  // ---------------------------------------------------------------- Widget

  Future<ProviderContainer> pump(
    WidgetTester tester,
    _Deps deps, {
    Size size = const Size(360, 800),
    double scale = 1.0,
    bool highContrast = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = deps.container();
    final router = GoRouter(initialLocation: '/family', routes: [
      GoRoute(
          path: '/family',
          builder: (_, __) => const FamilyScreen(),
          routes: [
            GoRoute(
                path: 'add', builder: (_, __) => const RelativeFormScreen()),
          ]),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    router.push('/family/add');
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField));

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.ensureVisible(field(label));
    await tester.enterText(field(label), text);
    await tester.pumpAndSettle();
  }

  /// Gõ vào ô "Tìm tên" (cuộn lên đầu danh sách trước – ListView dựng lười).
  Future<void> searchFor(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(field('Tìm tên'), -300,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(field('Tìm tên'), text);
    await tester.pumpAndSettle();
  }

  Future<void> seen(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    expect(find.text(text), findsWidgets, reason: text);
  }

  group('S12a / S12e / tự nhập', () {
    testWidgets('S12a: mọi chữ Figma, "Khác" đang chọn', (tester) async {
      await pump(tester, _Deps());
      for (final t in [
        'Gia đình',
        'Thêm người thân',
        'Chọn từ danh bạ',
        'hoặc tự nhập',
        'Tên gọi',
        'Ví dụ: Mai, Hùng',
        'Là gì của Bác?',
        'Con',
        'Cháu',
        'Bạn bè',
        'Khác',
        'Đang chọn',
        'Số điện thoại',
        'Ví dụ: 0912 345 678',
        'Chỉ gửi tin khi Bác chọn gửi.',
        'Lưu người thân',
      ]) {
        await seen(tester, t);
      }
      expect(tester.getSemantics(find.bySemanticsLabel('Khác')),
          isSemantics(isChecked: true));
    });

    testWidgets('S12e → sửa → lưu → về S09 có banner "Đã thêm Con Mai"',
        (tester) async {
      final deps = _Deps();
      final c = await pump(tester, deps);
      await type(tester, 'Tên gọi', 'Mai');
      await tap(tester, find.text('Con'));
      await tap(tester, find.text('Lưu người thân'));

      await seen(tester, 'Bác chưa nhập số điện thoại.');
      await seen(tester, 'Ví dụ: 0912 345 678');
      await seen(tester, 'Bác chạm “Chọn từ danh bạ” ở trên cho nhanh.');
      expect(_form(c).name, 'Mai');
      expect(_form(c).relation, 'Con');

      await type(tester, 'Số điện thoại', '0912345678');
      expect(find.text('0912 345 678'), findsOneWidget);
      await tap(tester, find.text('Lưu người thân'));
      expect(find.byType(RelativeFormScreen), findsNothing);
      expect(find.text('Đã thêm Con Mai'), findsOneWidget);
      expect((await deps.family.all()).single.phone, '0912345678');
    });

    testWidgets('số sai → "Số điện thoại chưa đúng." + Ví dụ', (tester) async {
      await pump(tester, _Deps());
      await type(tester, 'Tên gọi', 'Mai');
      await type(tester, 'Số điện thoại', '0912');
      await tap(tester, find.text('Lưu người thân'));
      await seen(tester, 'Số điện thoại chưa đúng.');
      await seen(tester, 'Ví dụ: 0912 345 678');
    });

    testWidgets(
        'quay lại khi đã nhập → hỏi; "Ở lại nhập tiếp" giữ, "Bỏ, quay lại" về S09',
        (tester) async {
      await pump(tester, _Deps());
      await type(tester, 'Tên gọi', 'Mai');
      await tap(tester, find.text('Gia đình').first);
      expect(find.text('Bỏ người thân đang nhập?'), findsOneWidget);
      expect(find.text('Tên và số Bác vừa nhập sẽ không được lưu.'),
          findsOneWidget);
      await tap(tester, find.text('Ở lại nhập tiếp'));
      expect(find.byType(RelativeFormScreen), findsOneWidget);
      expect(find.text('Mai'), findsOneWidget);

      await tap(tester, find.text('Gia đình').first);
      await tap(tester, find.text('Bỏ, quay lại'));
      expect(find.byType(RelativeFormScreen), findsNothing);
    });

    testWidgets('quay lại khi chưa nhập → về S09 ngay, không hỏi',
        (tester) async {
      await pump(tester, _Deps());
      await tap(tester, find.text('Gia đình').first);
      expect(find.text('Bỏ người thân đang nhập?'), findsNothing);
      expect(find.byType(RelativeFormScreen), findsNothing);
    });
  });

  group('Danh bạ 1:2146', () {
    testWidgets('mở → chữ Figma; tìm "hung" → chọn → điền sẵn → lưu',
        (tester) async {
      final deps = _Deps();
      await pump(tester, deps);
      await tap(tester, find.text('Chọn từ danh bạ'));
      expect(find.text('Quay lại'), findsOneWidget);
      for (final t in [
        'Chọn từ danh bạ',
        'Tìm tên',
        'Nhập tên người thân',
        'Mai',
        'Con gái · 0912 345 678'
      ]) {
        await seen(tester, t);
      }
      await searchFor(tester, 'hung');
      expect(find.text('Mai'), findsNothing);
      await tap(tester, find.text('Hùng'));

      expect(find.text('Hùng'), findsOneWidget);
      expect(find.text('0903 222 111'), findsOneWidget);
      await tap(tester, find.text('Lưu người thân'));
      expect(find.text('Đã thêm Con Hùng'), findsOneWidget);
      expect(deps.analytics.events.single.$2?['from_contacts'], isTrue);
    });

    testWidgets('"Quay lại" ở danh bạ → về form, giữ chữ đã nhập',
        (tester) async {
      await pump(tester, _Deps());
      await type(tester, 'Tên gọi', 'Bà Tư');
      await tap(tester, find.text('Chọn từ danh bạ'));
      await tap(tester, find.text('Quay lại'));
      expect(find.text('Tên gọi'), findsOneWidget);
      expect(find.text('Bà Tư'), findsOneWidget);
    });

    testWidgets('tìm không thấy → EmptyView + "Tự nhập" về form',
        (tester) async {
      await pump(tester, _Deps());
      await tap(tester, find.text('Chọn từ danh bạ'));
      await searchFor(tester, 'xyz');
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('Không thấy tên này trong danh bạ'), findsOneWidget);
      expect(find.text('Bác thử tên khác hoặc tự nhập.'), findsOneWidget);
      await tap(tester, find.text('Tự nhập'));
      expect(find.text('Tên gọi'), findsOneWidget);
    });

    testWidgets('từ chối quyền → dòng gợi ý, tự nhập vẫn lưu được',
        (tester) async {
      await pump(tester, _Deps(contacts: FakeContactsService(granted: false)));
      await tap(tester, find.text('Chọn từ danh bạ'));
      expect(find.text('Bác có thể tự nhập tên và số ở dưới.'), findsOneWidget);
      await type(tester, 'Tên gọi', 'Bin');
      await type(tester, 'Số điện thoại', '0987654321');
      await tap(tester, find.text('Lưu người thân'));
      expect(find.text('Đã thêm Khác Bin'), findsOneWidget);
    });
  });

  group('Không tràn: 360 / 412 × 1.0 / 1.3 / 2.0, thường + tương phản cao', () {
    const sizes = [Size(360, 800), Size(412, 915)];
    const scales = [1.0, 1.3, 2.0];
    for (final size in sizes) {
      for (final scale in scales) {
        for (final hc in [false, true]) {
          final label =
              '${size.width.toInt()} · ×$scale${hc ? ' · tương phản cao' : ''}';

          testWidgets('$label: S12e + bàn phím mở', (tester) async {
            await pump(tester, _Deps(),
                size: size, scale: scale, highContrast: hc);
            await type(tester, 'Tên gọi', 'Nguyễn Thị Mai');
            await tap(tester, find.text('Lưu người thân'));
            for (final t in [
              'Bác chưa nhập số điện thoại.',
              'Bác chạm “Chọn từ danh bạ” ở trên cho nhanh.',
              'Chỉ gửi tin khi Bác chọn gửi.',
              'Khác',
            ]) {
              await seen(tester, t);
              expect(tester.takeException(), isNull, reason: t);
            }
            // Bàn phím mở: nút Lưu vẫn thấy, không bị che.
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            addTearDown(tester.view.resetViewInsets);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Lưu người thân').hitTestable(), findsOneWidget);
          });

          testWidgets('$label: danh bạ + không thấy', (tester) async {
            await pump(tester, _Deps(),
                size: size, scale: scale, highContrast: hc);
            await tap(tester, find.text('Chọn từ danh bạ'));
            await seen(tester, 'Chị Hoa');
            expect(tester.takeException(), isNull);
            await searchFor(tester, 'xyz');
            await seen(tester, 'Tự nhập');
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
