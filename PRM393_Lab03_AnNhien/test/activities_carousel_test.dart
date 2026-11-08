import 'package:an_nhien/models/guided_activity.dart';
import 'package:an_nhien/widgets/activity_discovery_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';

void main() {
  testWidgets('card speaker reads the current activity after swiping',
      (tester) async {
    final device = TestDevice();
    final container = demoContainer(device: device);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
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
              home: Scaffold(
                  body: MediaQuery(
                      data:
                          MediaQueryData(textScaler: TextScaler.linear(scale)),
                      child: SingleChildScrollView(
                          child: ActivityDiscoveryDeck(
                              onOpen: (a) => opened = a)))))));
      final card = find.byKey(const Key('activity-swipe-card'));
      await tester.dragFrom(tester.getTopLeft(card) + const Offset(150, 60),
          const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(container.read(activityChoicesProvider)[guidedActivities[0].id],
          true);
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
}
