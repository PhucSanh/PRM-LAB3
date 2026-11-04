import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/widgets/app_button.dart';
import 'support/demo_container.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  testWidgets('empty Today still exposes settings and notifications',
      (tester) async {
    final c = demoContainer();
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay chưa có việc'), findsOneWidget);
    expect(find.text('Đã xong 0/0 việc'), findsNothing);
    await tester.tap(find.text('Thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Hộp thông báo'), findsOneWidget);
    c.read(routerProvider).go('/today');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt hiển thị'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'polished surfaces 360px x$scale preserve readable actions and optional tools',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = demoContainer(tasks: FakeTaskRepository());
      c.read(fontScaleProvider.notifier).set(AppFontScale.vua);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: UncontrolledProviderScope(
              container: c, child: const AnNhienApp())));
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      for (final route in [
        '/sign-in',
        '/welcome',
        '/today',
        '/caregiver/task/new',
        '/inbox',
        '/account'
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$route x$scale');
        if (route == '/account') {
          expect(find.text('Nhận lịch gợi ý (khu thử)'), findsNothing);
          final home = find.byWidgetPredicate(
              (w) => w is AppButton && w.label == 'Về Hôm nay');
          await tester.ensureVisible(home);
          await tester.pumpAndSettle();
          expect(tester.getSize(home).height, greaterThanOrEqualTo(72));
          final tools = find.text('Công cụ thử nghiệm');
          await tester.ensureVisible(tools);
          await tester.pumpAndSettle();
          await tester.tap(tools);
          await tester.pumpAndSettle();
          expect(find.text('Nhận lịch gợi ý (khu thử)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        if (const bool.fromEnvironment('CAPTURE_UI') && scale == 1) {
          await tester.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('/tmp/annhien-polish').create(recursive: true);
            await File('/tmp/annhien-polish/${route.replaceAll('/', '_')}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  }
}
