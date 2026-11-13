import 'package:an_nhien/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task Date Utility Functions Unit Tests', () {
    test('1. dateKey formats single-digit month and day with zero-padding', () {
      final date = DateTime(2026, 4, 5, 14, 30);
      final key = dateKey(date);
      expect(key, '2026-04-05');
    });

    test('2. calendarDate strips time component and normalizes to midnight', () {
      final dateWithTime = DateTime(2026, 11, 13, 13, 45, 59, 123);
      final normalized = calendarDate(dateWithTime);
      expect(normalized.year, 2026);
      expect(normalized.month, 11);
      expect(normalized.day, 13);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.millisecond, 0);
    });

    test('3. dateKey formats leap year dates and end of year correctly', () {
      final leapDay = DateTime(2028, 2, 29);
      expect(dateKey(leapDay), '2028-02-29');

      final newYearEve = DateTime(2026, 12, 31);
      expect(dateKey(newYearEve), '2026-12-31');
    });
  });
}\n