import '../models/habit.dart';

/// 9 thói quen (Firestore habits/). Bản thật: B – Hiếu. Dùng ở F9 (Hương).
abstract interface class HabitRepository {
  Future<List<Habit>> all();
  Future<Habit?> byKey(String key);
}

class FakeHabitRepository implements HabitRepository {
  static const _habits = [
    Habit(key: 'move', name: 'Vận động tự nhiên', description: 'Đi bộ, làm vườn, tự làm việc nhà'),
    Habit(key: 'purpose', name: 'Sống có mục đích', description: 'Mỗi sáng có một lý do để thức dậy'),
    Habit(key: 'downshift', name: 'Thư giãn mỗi ngày', description: 'Ngồi thở nhẹ, nghỉ trưa'),
    Habit(key: 'eighty', name: 'Ăn vừa đủ', description: 'Ăn chậm, dừng khi thấy vừa no'),
    Habit(key: 'plant', name: 'Ăn nhiều rau, đậu', description: 'Rau, đậu, ngũ cốc mỗi bữa'),
    Habit(key: 'tea', name: 'Trà chiều cùng bạn', description: 'Uống trà, trò chuyện buổi chiều'),
    Habit(key: 'belong', name: 'Gắn kết cộng đồng', description: 'Sinh hoạt chùa, nhà thờ, hội'),
    Habit(key: 'family', name: 'Gia đình trên hết', description: 'Gọi điện, ăn cơm cùng con cháu'),
    Habit(key: 'tribe', name: 'Bạn bè tích cực', description: 'Gặp những người bạn vui vẻ'),
  ];

  @override
  Future<List<Habit>> all() async => _habits;

  @override
  Future<Habit?> byKey(String key) async => _habits.where((h) => h.key == key).firstOrNull;
}
