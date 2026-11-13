import 'package:an_nhien/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit Model Unit Tests', () {
    test('1. parses standard map fields correctly', () {
      final habit = Habit.fromMap('move', {
        'name': 'Vận động tự nhiên',
        'description': 'Đi bộ nhẹ nhàng mỗi ngày',
      });
      expect(habit.key, 'move');
      expect(habit.name, 'Vận động tự nhiên');
      expect(habit.description, 'Đi bộ nhẹ nhàng mỗi ngày');
    });

    test('2. falls back to key when name is omitted in map', () {
      final habit = Habit.fromMap('downshift', {
        'description': 'Giảm căng thẳng và thư giãn',
      });
      expect(habit.key, 'downshift');
      expect(habit.name, 'downshift');
      expect(habit.description, 'Giảm căng thẳng và thư giãn');
    });

    test('3. handles missing description with default empty string', () {
      final habit = Habit.fromMap('family', {
        'name': 'Gắn kết gia đình',
      });
      expect(habit.key, 'family');
      expect(habit.name, 'Gắn kết gia đình');
      expect(habit.description, '');
    });
  });
}\n