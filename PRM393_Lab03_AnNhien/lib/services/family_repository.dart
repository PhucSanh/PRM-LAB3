import '../models/relative.dart';

/// Người thân (Firestore users/{uid}/family). Bản thật: B – Hiếu. Dùng ở F11 (Hương).
abstract interface class FamilyRepository {
  Future<List<Relative>> all();
  Future<void> save(Relative relative);
  Future<void> delete(String id);
}

abstract interface class FavoriteFamilyRepository {
  Future<void> setFavorite(String id, bool value);
}

class FakeFamilyRepository
    implements FamilyRepository, FavoriteFamilyRepository {
  @override
  Future<void> setFavorite(String id, bool value) async {
    final index = _items.indexWhere((r) => r.id == id);
    if (index < 0) throw StateError('Contact no longer exists');
    _items[index] = _items[index].copyWith(favorite: value);
  }

  final List<Relative> _items = [
    const Relative(id: 'r1', name: 'Mai', relation: 'Con', phone: '0912345678'),
    const Relative(
        id: 'r2', name: 'Hùng', relation: 'Con', phone: '0987654321'),
  ];

  @override
  Future<List<Relative>> all() async => List.unmodifiable(_items);

  @override
  Future<void> save(Relative relative) async {
    _items
      ..removeWhere((r) => r.id == relative.id)
      ..add(relative);
  }

  @override
  Future<void> delete(String id) async => _items.removeWhere((r) => r.id == id);
}
