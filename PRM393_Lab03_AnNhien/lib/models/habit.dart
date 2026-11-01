/// Một trong 9 thói quen Power 9 (Firestore: habits/{key}, nạp sẵn, không hard-code trong app).
class Habit {
  const Habit({required this.key, required this.name, required this.description});

  final String key;
  final String name;
  final String description;

  factory Habit.fromMap(String key, Map<String, Object?> m) => Habit(
        key: key,
        name: m['name'] as String? ?? key,
        description: m['description'] as String? ?? '',
      );
}
