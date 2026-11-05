import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/widgets/suggestion_swipe_deck.dart';

void main() {
  testWidgets(
      'horizontal choices can be undone; vertical scroll does not choose',
      (tester) async {
    final selected = <int, bool>{};
    var reviewed = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SuggestionSwipeDeck(
                    tasks: [
          for (var i = 0; i < 2; i++)
            TaskItem(
                id: '$i',
                title: 'Việc $i',
                habitKey: 'move',
                hour: 8,
                minute: 0,
                startDate: '2026-11-05')
        ],
                    onChoice: (i, accepted) => selected[i] = accepted,
                    onReview: () => reviewed = true)))));
    await tester.drag(find.text('Việc 0'), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    await tester.drag(find.text('Việc 0'), const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(selected[0], true);
    expect(reviewed, false);
    await tester.drag(find.text('Việc 1'), const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(selected[1], false);
    await tester.tap(find.text('Hoàn tác lựa chọn'));
    await tester.pumpAndSettle();
    expect(find.text('Việc 1'), findsOneWidget);
    await tester.tap(find.text('Muốn làm'));
    await tester.pumpAndSettle();
    expect(selected[1], true);
    await tester.tap(find.text('Xem lại lựa chọn'));
    expect(reviewed, true);
  });
}
