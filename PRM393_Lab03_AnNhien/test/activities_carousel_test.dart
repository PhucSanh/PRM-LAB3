import 'package:an_nhien/models/guided_activity.dart';
import 'package:an_nhien/models/habit_guide.dart';
import 'package:an_nhien/widgets/activity_discovery_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader(AppTheme.fontFamily);
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  testWidgets('card speaker reads the current activity after swiping',
      (tester) async {
    final device = TestDevice();
    final container = demoContainer(device: device);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ActivityDiscoveryDeck(onOpen: (_) {}))))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đọc khung này'));
    await tester.pumpAndSettle();
    expect(device.spoken, contains(guidedActivities.first.title));
    expect(device.spoken, contains(guidedActivities.first.steps.last));
    final card = find.byKey(const Key('activity-swipe-card'));
    await tester.dragFrom(
        tester.getTopLeft(card) + const Offset(150, 60), const Offset(-150, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đọc khung này'));
    await tester.pumpAndSettle();
    expect(device.spoken, contains(guidedActivities[1].title));
    expect(device.spoken, isNot(contains(guidedActivities.first.title)));
    expect(container.read(activityChoicesProvider).length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('activity deck likes, skips, undoes and opens at scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      GuidedActivity? opened;
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                  body: MediaQuery(
                      data:
                          MediaQueryData(textScaler: TextScaler.linear(scale)),
                      child: SingleChildScrollView(
                          child: ActivityDiscoveryDeck(
                              onOpen: (a) => opened = a)))))));
      await tester.pumpAndSettle();
      await tester.runAsync(() => precacheImage(
          AssetImage(habitPhotosOf(guidedActivities.first.habitKey).first),
          tester.element(find.byType(ActivityDiscoveryDeck))));
      await tester.pumpAndSettle();
      await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
              'goldens/activities_hobbies_${scale.toInt()}x.png'));
      final card = find.byKey(const Key('activity-swipe-card'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getTopLeft(card) + const Offset(150, 60),
          const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(container.read(activityChoicesProvider)[guidedActivities[0].id],
          true);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getTopLeft(card) + const Offset(150, 60),
          const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(container.read(activityChoicesProvider)[guidedActivities[1].id],
          false);
      await tester.ensureVisible(find.text('Hoàn tác'));
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(
          container
              .read(activityChoicesProvider)
              .containsKey(guidedActivities[1].id),
          false);
      await tester.ensureVisible(find.text('Xem cách làm →'));
      await tester.tap(find.text('Xem cách làm →'));
      expect(opened?.id, guidedActivities[1].id);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'interest filters show matching hobbies and never schedule a task',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ActivityDiscoveryDeck(onOpen: (_) {}))))));
    final chip = find.widgetWithText(ChoiceChip, 'Cây cối');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Tưới cây'), findsOneWidget);
    expect(guidedActivities.where((a) => a.interest == 'Cây cối').length,
        greaterThanOrEqualTo(3));
    expect(guidedActivities.map((a) => a.interest).toSet(), hasLength(6));
    expect(container.read(activityChoicesProvider), isEmpty);
  });
}
