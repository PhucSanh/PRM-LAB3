import 'package:an_nhien/widgets/relationship_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('relationship is selected without typing at scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? value;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: StatefulBuilder(
                      builder: (context, setState) => ListView(children: [
                            RelationshipDropdown(
                                value: value,
                                onChanged: (next) =>
                                    setState(() => value = next))
                          ]))))));
      expect(find.byType(EditableText), findsNothing);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cháu').last);
      await tester.pumpAndSettle();
      expect(value, 'Cháu');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('legacy relationship remains selected without silent conversion',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RelationshipDropdown(value: 'Em gái', onChanged: (_) {}))));
    expect(find.text('Em gái'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
