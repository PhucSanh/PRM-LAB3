import 'package:an_nhien/services/schedule_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activityIdentity Normalization Function Unit Tests', () {
    test('1. trims leading and trailing whitespace from task titles', () {
      final normalized = activityIdentity('   Uống thuốc huyết áp   ');
      expect(normalized, 'uống thuốc huyết áp');
    });

    test('2. collapses multiple consecutive spaces into a single space', () {
      final normalized = activityIdentity('Đi    bộ     buổi     sáng');
      expect(normalized, 'đi bộ buổi sáng');
    });

    test('3. normalizes mixed casing into lowercase for uniform comparisons', () {
      final id1 = activityIdentity('UỐNG THUỐC CANXI');
      final id2 = activityIdentity('uống Thuốc canxi');
      expect(id1, id2);
      expect(id1, 'uống thuốc canxi');
    });
  });
}\n