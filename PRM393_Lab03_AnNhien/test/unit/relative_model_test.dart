import 'package:an_nhien/models/relative.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Relative Model Unit Tests', () {
    test('1. instantiates relative with default favorite as false', () {
      const rel = Relative(
        id: 'rel_01',
        name: 'Nguyễn Văn Nam',
        relation: 'Con trai',
        phone: '0901234567',
      );
      expect(rel.id, 'rel_01');
      expect(rel.name, 'Nguyễn Văn Nam');
      expect(rel.relation, 'Con trai');
      expect(rel.phone, '0901234567');
      expect(rel.favorite, isFalse);
    });

    test('2. copyWith toggles favorite flag while preserving identity', () {
      const rel = Relative(
        id: 'rel_02',
        name: 'Nguyễn Thị Mai',
        relation: 'Con gái',
        phone: '0912345678',
        favorite: false,
      );
      final updated = rel.copyWith(favorite: true);
      expect(updated.id, rel.id);
      expect(updated.name, rel.name);
      expect(updated.relation, rel.relation);
      expect(updated.phone, rel.phone);
      expect(updated.favorite, isTrue);
    });

    test('3. copyWith preserves existing favorite when null is passed', () {
      const rel = Relative(
        id: 'rel_03',
        name: 'Lê Hoàng Minh',
        relation: 'Cháu',
        phone: '0987654321',
        favorite: true,
      );
      final copied = rel.copyWith();
      expect(copied.favorite, isTrue);
    });
  });
}\n