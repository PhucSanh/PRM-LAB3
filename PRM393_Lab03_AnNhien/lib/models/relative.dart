/// Người thân (Firestore: users/{uid}/family/{id}).
class Relative {
  const Relative({required this.id, required this.name, required this.relation, required this.phone});

  final String id;
  final String name;
  final String relation; // Con, Cháu, Bạn bè, Khác
  final String phone;
}
