import 'package:an_nhien/models/suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuggestionTime Serialization & Equality Unit Tests', () {
    test('1. toMap serializes hour and minute into map representation', () {
      const time = SuggestionTime(14, 45);
      final map = time.toMap();
      expect(map['hour'], 14);
      expect(map['minute'], 45);
    });

    test('2. fromMap parses map and defaults missing numbers to 0', () {
      final timeFromFull = SuggestionTime.fromMap(const {'hour': 8, 'minute': 15});
      expect(timeFromFull.hour, 8);
      expect(timeFromFull.minute, 15);

      final timeFromEmpty = SuggestionTime.fromMap(const {});
      expect(timeFromEmpty.hour, 0);
      expect(timeFromEmpty.minute, 0);
    });

    test('3. equality operator compares hour and minute values accurately', () {
      const t1 = SuggestionTime(10, 30);
      const t2 = SuggestionTime(10, 30);
      const t3 = SuggestionTime(11, 30);
      expect(t1 == t2, isTrue);
      expect(t1 == t3, isFalse);
      expect(t1.hashCode, t2.hashCode);
    });
  });
}\n