import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/relative.dart';
import 'package:an_nhien/screens/family/family_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/contact_launcher_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/family_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:an_nhien/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'f11_view_models_test.dart' show SeededFamilyRepository, settled;

/// F11 bước 02: S09 Gia đình + S09b (ViewModel + màn).
const _mai =
    Relative(id: 'r1', name: 'Mai', relation: 'Con', phone: '0912345678');
const _hung =
    Relative(id: 'r2', name: 'Hùng', relation: 'Con', phone: '0903222111');
const _bin =
    Relative(id: 'r3', name: 'Bin', relation: 'Cháu', phone: '0987654321');

class _Deps {
  _Deps({
    List<Relative>? seed,
    bool familyFails = false,
    bool withSuggestion = true,
    FakeContactLauncherService? launcher,
  })  : family = SeededFamilyRepository(seed, familyFails),
        launcher = launcher ?? FakeContactLauncherService(),
        suggestions = FakeSuggestionService(
            withSample: withSuggestion, delay: Duration.zero);

  final SeededFamilyRepository family;
  final FakeContactLauncherService launcher;
  final FakeSuggestionService suggestions;

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      familyRepositoryProvider.overrideWithValue(family),
      contactLauncherServiceProvider.overrideWithValue(launcher),
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'mom-uid'))),
      suggestionServiceProvider.overrideWithValue(suggestions),
    ]);
    addTearDown(c.dispose);
    addTearDown(suggestions.dispose);
    return c;
  }
}

FamilyList _data(ProviderContainer c) =>
    (c.read(familyViewModelProvider) as UiData<FamilyList>).data;

/// Dựng `/family` với route con giả (in ra đường dẫn đã mở) để kiểm điều hướng.
Future<ProviderContainer> _pump(
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
  Widget opened(GoRouterState s) => Scaffold(body: Text('opened ${s.uri}'));
  final router = GoRouter(initialLocation: '/family', routes: [
    GoRoute(path: '/family', builder: (_, __) => const FamilyScreen(), routes: [
      GoRoute(path: 'add', builder: (_, s) => opened(s)),
      GoRoute(path: ':personId/edit', builder: (_, s) => opened(s)),
      GoRoute(path: ':personId/share', builder: (_, s) => opened(s)),
    ]),
    GoRoute(path: '/today/suggestions/:id', builder: (_, s) => opened(s)),
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
  return c;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('FamilyViewModel bước 02', () {
    test('"Gọi điện" gọi service đúng số, mở được → null', () async {
      final deps = _Deps();
      final c = deps.container();
      await settled(c, familyViewModelProvider);
      final error = await c.read(familyViewModelProvider.notifier).call(_mai);
      expect(error, isNull);
      expect(deps.launcher.launched.single.kind, 'call');
      expect(deps.launcher.launched.single.phone, '0912345678');
    });

    test('máy không gọi được → câu cho Bác; lỗi service → userMessage',
        () async {
      final deps = _Deps(launcher: FakeContactLauncherService(noDialer: true));
      final c = deps.container();
      await settled(c, familyViewModelProvider);
      final vm = c.read(familyViewModelProvider.notifier);
      expect(
          await vm.call(_mai), 'Chưa gọi được cho Mai. Bác thử lại sau nhé.');

      deps.launcher
        ..noDialer = false
        ..failOnCall = true;
      expect(await vm.call(_mai),
          FakeContactLauncherService.callFailed.userMessage);
      expect(deps.launcher.launched, isEmpty);
    });

    test('showAdded: người mới đứng cuối + banner; dismissAdded tắt banner',
        () async {
      final deps = _Deps(seed: [_mai, _hung]);
      final c = deps.container();
      await settled(c, familyViewModelProvider);
      await deps.family.save(_bin);
      final vm = c.read(familyViewModelProvider.notifier);
      await vm.showAdded(_bin);
      expect(_data(c).relatives.map((r) => r.name), ['Mai', 'Hùng', 'Bin']);
      expect(_data(c).justAdded?.id, 'r3');
      vm.dismissAdded();
      expect(_data(c).justAdded, isNull);
      expect(_data(c).relatives, hasLength(3));
    });

    test('showAdded khi nạp lỗi → giữ Error (không vẽ danh sách rỗng)',
        () async {
      final deps = _Deps();
      final c = deps.container();
      await settled(c, familyViewModelProvider);
      deps.family.failOnLoad = true;
      await c.read(familyViewModelProvider.notifier).showAdded(_bin);
      expect(c.read(familyViewModelProvider), isA<UiError<FamilyList>>());
    });
  });

  group('S09 Gia đình', () {
    testWidgets('chữ Figma + hàng gợi ý + 3 thẻ, không câu phụ',
        (tester) async {
      await _pump(tester, _Deps());
      expect(find.text('Gia đình'), findsOneWidget);
      expect(find.text('Gợi ý từ Mai'), findsOneWidget);
      expect(find.text('2 việc'), findsOneWidget);
      for (final name in ['Mai', 'Hùng', 'Bin']) {
        await tester.ensureVisible(find.text(name));
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('M'),
          findsOneWidget); // avatar chữ cái (người dùng chọn 04/11)
      expect(find.text('Gọi điện'), findsNWidgets(3));
      expect(find.text('Nhắn tin'), findsNWidgets(3));
      expect(find.text('Thêm người thân'), findsOneWidget);
      expect(find.text('Bác chọn điều muốn kể cho con'), findsNothing);
      expect(find.textContaining('Đã gửi'), findsNothing);
    });

    testWidgets('không có gợi ý → hàng gợi ý không chiếm chỗ', (tester) async {
      await _pump(tester, _Deps(withSuggestion: false));
      expect(find.textContaining('Gợi ý từ'), findsNothing);
      expect(find.text('Mai'), findsOneWidget);
    });

    testWidgets('điều hướng: Nhắn tin, Sửa (chạm đầu thẻ), Thêm, Gợi ý',
        (tester) async {
      await _pump(tester, _Deps());
      await _tap(tester, find.text('Nhắn tin').first);
      expect(find.text('opened /family/r1/share'), findsOneWidget);
      GoRouter.of(tester.element(find.textContaining('opened'))).pop();
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Hùng'));
      expect(find.text('opened /family/r2/edit'), findsOneWidget);
      GoRouter.of(tester.element(find.textContaining('opened'))).pop();
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Thêm người thân'));
      expect(find.text('opened /family/add'), findsOneWidget);
      GoRouter.of(tester.element(find.textContaining('opened'))).pop();
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Gợi ý từ Mai'));
      expect(find.textContaining('opened /today/suggestions/'), findsOneWidget);
      expect(find.textContaining('?from=family'), findsOneWidget);
    });

    testWidgets('"Gọi điện" mở gọi ngay, không hộp thoại', (tester) async {
      final deps = _Deps();
      await _pump(tester, deps);
      await _tap(tester, find.text('Gọi điện').first);
      expect(deps.launcher.launched.single.phone, '0912345678');
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('gọi không được → câu báo', (tester) async {
      await _pump(
          tester, _Deps(launcher: FakeContactLauncherService(noDialer: true)));
      await _tap(tester, find.text('Gọi điện').first);
      expect(find.text('Chưa gọi được cho Mai. Bác thử lại sau nhé.'),
          findsOneWidget);
    });

    testWidgets('Trống → EmptyView + Thêm người thân', (tester) async {
      await _pump(tester, _Deps(seed: const []));
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('Thêm số điện thoại con cháu'), findsOneWidget);
      await _tap(tester, find.text('Thêm người thân'));
      expect(find.text('opened /family/add'), findsOneWidget);
    });

    testWidgets('Lỗi → ErrorView + Thử lại → Data', (tester) async {
      final deps = _Deps(familyFails: true);
      await _pump(tester, deps);
      expect(find.byType(ErrorView), findsOneWidget);
      deps.family.failOnLoad = false;
      await _tap(tester, find.text('Thử lại'));
      expect(find.text('Mai'), findsOneWidget);
    });
  });

  group('S09b đã thêm người thân', () {
    testWidgets(
        'banner + câu phụ + người mới ở cuối; mở màn khác thì banner mất',
        (tester) async {
      final deps = _Deps(seed: [_mai, _hung]);
      final c = await _pump(tester, deps);
      await deps.family.save(_bin);
      await c.read(familyViewModelProvider.notifier).showAdded(_bin);
      await tester.pumpAndSettle();

      expect(find.text('Bác chọn điều muốn kể cho con'), findsOneWidget);
      expect(find.text('Đã thêm Cháu Bin'), findsOneWidget);
      expect(find.text('Bác có thể gọi hoặc nhắn tin ngay.'), findsOneWidget);
      await tester.ensureVisible(find.text('Bin'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Bin')).dy,
          greaterThan(tester.getTopLeft(find.text('Hùng')).dy));

      await _tap(tester, find.text('Thêm người thân'));
      GoRouter.of(tester.element(find.textContaining('opened'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Đã thêm Cháu Bin'), findsNothing);
      expect(find.text('Bác chọn điều muốn kể cho con'), findsNothing);
    });
  });

  group('Không tràn: 360 / 412 dp × 1.0 / 1.3 / 2.0, thường + tương phản cao',
      () {
    const sizes = [Size(360, 800), Size(412, 915)];
    const scales = [1.0, 1.3, 2.0];
    for (final size in sizes) {
      for (final scale in scales) {
        for (final hc in [false, true]) {
          final label =
              '${size.width.toInt()} · ×$scale${hc ? ' · tương phản cao' : ''}';

          testWidgets('$label: S09b (banner + 3 thẻ + gợi ý)', (tester) async {
            final deps = _Deps(seed: [_mai, _hung]);
            final c = await _pump(tester, deps,
                size: size, scale: scale, highContrast: hc);
            await deps.family.save(_bin);
            await c.read(familyViewModelProvider.notifier).showAdded(_bin);
            await tester.pumpAndSettle();
            for (final text in [
              'Đã thêm Cháu Bin',
              'Gợi ý từ Mai',
              'Mai',
              'Hùng',
              'Bin',
              'Thêm người thân'
            ]) {
              await tester.ensureVisible(find.text(text).last);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: text);
            }
            expect(find.text('Gọi điện'), findsNWidgets(3));
          });

          testWidgets('$label: Trống + Lỗi', (tester) async {
            await _pump(tester, _Deps(seed: const []),
                size: size, scale: scale, highContrast: hc);
            await tester.ensureVisible(find.text('Thêm người thân'));
            expect(tester.takeException(), isNull);
            await _pump(tester, _Deps(familyFails: true),
                size: size, scale: scale, highContrast: hc);
            await tester.ensureVisible(find.text('Thử lại'));
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
