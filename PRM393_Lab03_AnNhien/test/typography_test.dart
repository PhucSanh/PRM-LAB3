import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/widgets/app_back_bar.dart';
import 'package:an_nhien/widgets/app_button.dart';
import 'package:an_nhien/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/demo_container.dart';

const _longLabel = 'Lưu hoạt động đi bộ cùng gia đình';

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBackBar.adaptive(context, step: 'Bước 1/2'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Lịch của Bác', style: text.headlineMedium),
          Text('Đi bộ cùng gia đình', style: text.titleMedium),
          Text('Giữ nhịp sinh hoạt mỗi ngày.', style: text.bodyLarge),
          Text('Đã lên lịch', style: text.bodySmall),
          const AppTextField(
            label: 'Tên hoạt động',
            hint: 'Đi bộ nhẹ nhàng',
            errorText: 'Vui lòng nhập tên hoạt động.',
          ),
          ChoiceChip(
              label: const Text('Thói quen'),
              selected: true,
              onSelected: (_) {}),
          AppButton(label: _longLabel, icon: Icons.check, onPressed: () {}),
          const SizedBox(height: 16),
          const ListTile(title: Text('Gia đình'), subtitle: Text('Đã kết nối')),
        ]),
      ),
    );
  }
}

TextStyle renderedStyle(WidgetTester tester, String label) {
  final rich = find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == label);
  return (tester.renderObject<RenderParagraph>(rich.first).text as TextSpan)
      .style!;
}

void main() {
  setUpAll(() async {
    // Actual bundled font: golden QA includes Vietnamese accents and real widths.
    final loader = FontLoader(AppTheme.fontFamily);
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
    final welcomeSerif = FontLoader('NotoSerif')
      ..addFont(rootBundle.load('assets/fonts/NotoSerif-Regular.ttf'));
    await welcomeSerif.load();
    final serif = FontLoader('NotoSerifDisplay')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifDisplay-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSerifDisplay-Bold.ttf'));
    await serif.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final caregiver in [false, true]) {
    for (final contrast in [false, true]) {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 1.3, 1.6, 2.0]) {
          testWidgets(
              'TYPE-01 role=$caregiver contrast=$contrast $width x$scale',
              (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(MaterialApp(
              theme: contrast
                  ? AppTheme.highContrast(caregiver: caregiver)
                  : AppTheme.light(caregiver: caregiver),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: const _Preview(),
            ));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            void check(String label, double size, FontWeight weight) {
              final style = renderedStyle(tester, label);
              expect(style.fontSize, size, reason: label);
              expect(style.fontWeight, weight, reason: label);
              expect(style.fontFamily, AppTheme.fontFamily, reason: label);
            }

            check('Lịch của Bác', caregiver ? 28 : 30, FontWeight.w600);
            check('Đi bộ cùng gia đình', caregiver ? 18 : 20, FontWeight.w600);
            check('Giữ nhịp sinh hoạt mỗi ngày.', caregiver ? 17 : 18,
                FontWeight.w400);
            check('Đã lên lịch', 14, FontWeight.w400);
            check('Ví dụ: Đi bộ nhẹ nhàng', 16, FontWeight.w400);
            final input =
                tester.widget<EditableText>(find.byType(EditableText));
            expect(input.style.fontSize, caregiver ? 17 : 18);
            expect(input.style.fontWeight, FontWeight.w400);
            check('Thói quen', caregiver ? 15 : 16, FontWeight.w600);
            check(_longLabel, caregiver ? 17 : 18, FontWeight.w600);
            check('Gia đình', caregiver ? 18 : 20, FontWeight.w600);
            check('Đã kết nối', 16, FontWeight.w400);
            await tester.ensureVisible(find.text(_longLabel));
            await tester.pumpAndSettle();
            expect(find.text(_longLabel).hitTestable(), findsOneWidget);
            expect(find.byType(FittedBox), findsNothing);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets('theme follows resolved profile and resets on sign-out',
      (tester) async {
    final container = demoContainer(role: null);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    double bodySize() => Theme.of(tester.element(find.byType(Scaffold).first))
        .textTheme
        .bodyLarge!
        .fontSize!;
    expect(bodySize(), 18); // unresolved role defaults elderly
    await container
        .read(profileServiceProvider)
        .setRole('demo-user', UserRole.caregiver);
    await tester.pumpAndSettle();
    expect(bodySize(), 17);
    await container.read(authServiceProvider).signOut();
    await tester.pumpAndSettle();
    expect(bodySize(), 18);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });

  for (final caregiver in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('typography golden role=$caregiver scale=$scale',
          (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light(caregiver: caregiver),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const _Preview(),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(_Preview),
            matchesGoldenFile(
                'goldens/typography_${caregiver ? 'caregiver' : 'elderly'}_${scale.toInt()}x.png'));
      });
    }
  }
}
