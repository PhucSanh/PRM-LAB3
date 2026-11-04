import 'task_item.dart';

/// Gợi ý lịch con cháu gửi Bác (F12, Firestore `users/{momUid}/suggestions/{id}`).
///
/// F12 đề xuất (chờ Hiếu chốt schema, ghi trong PR): thêm `fromRelation` ("Con gái",
/// Figma G02 / G03), `items[].timeOptions` (giờ để chọn – G01 / G04) và
/// `items[].accepted` (việc đã nhận, để nhận tiếp gợi ý `partial` – G07 "Bác có thể thêm sau").
enum SuggestionStatus { pending, accepted, partial, dismissed }

/// Một mốc giờ (giờ 0–23, phút). Model thuần Dart nên không dùng `TimeOfDay`.
class SuggestionTime {
  const SuggestionTime(this.hour, this.minute);

  final int hour;
  final int minute;

  Map<String, Object?> toMap() => {'hour': hour, 'minute': minute};

  factory SuggestionTime.fromMap(Map<Object?, Object?> m) => SuggestionTime(
        (m['hour'] as num?)?.toInt() ?? 0,
        (m['minute'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is SuggestionTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'SuggestionTime($hour:$minute)';
}

/// Một việc trong gợi ý. Lịch của Bác **không** đổi cho tới khi Bác nhận
/// (ViewModel gọi `TaskRepository.save(item.toTask(...))`).
class SuggestionItem {
  const SuggestionItem({
    required this.title,
    required this.habitKey,
    required this.date,
    required this.hour,
    required this.minute,
    this.durationMin,
    this.timeOptions = const [],
    this.accepted = false,
  });

  final String title;

  /// Một trong 9 khoá thói quen (nạp từ `habits`, không hard-code danh sách).
  final String habitKey;

  /// Ngày của việc (chỉ phần ngày), vd. ngày mai.
  final DateTime date;
  final int hour;
  final int minute;
  final int? durationMin;

  /// Các giờ để chọn (G01 nút giờ, G04 "Chọn giờ đi bộ:"). Rỗng = chỉ có giờ gợi ý.
  final List<SuggestionTime> timeOptions;

  /// Bác đã nhận việc này vào lịch.
  final bool accepted;

  SuggestionTime get time => SuggestionTime(hour, minute);

  SuggestionItem copyWith({
    String? title,
    String? habitKey,
    DateTime? date,
    int? hour,
    int? minute,
    int? durationMin,
    List<SuggestionTime>? timeOptions,
    bool? accepted,
  }) =>
      SuggestionItem(
        title: title ?? this.title,
        habitKey: habitKey ?? this.habitKey,
        date: date ?? this.date,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        durationMin: durationMin ?? this.durationMin,
        timeOptions: timeOptions ?? this.timeOptions,
        accepted: accepted ?? this.accepted,
      );

  /// Cùng một việc (bỏ qua giờ – Bác có thể đã đổi giờ trước khi nhận).
  bool sameTaskAs(SuggestionItem other) =>
      other.title == title &&
      other.habitKey == habitKey &&
      dateKey(other.date) == dateKey(date);

  /// Việc một lần vào lịch Bác, đúng ngày + giờ của gợi ý.
  TaskItem toTask(String id) => TaskItem(
        id: id,
        title: title,
        habitKey: habitKey,
        hour: hour,
        minute: minute,
        repeat: RepeatRule.once,
        startDate: date,
        durationMin: durationMin,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'habitKey': habitKey,
        'date': dateKey(date),
        'hour': hour,
        'minute': minute,
        if (durationMin != null) 'durationMin': durationMin,
        if (timeOptions.isNotEmpty)
          'timeOptions': [for (final t in timeOptions) t.toMap()],
        'accepted': accepted,
      };

  factory SuggestionItem.fromMap(Map<Object?, Object?> m) {
    final options = m['timeOptions'];
    return SuggestionItem(
      title: m['title'] as String? ?? '',
      habitKey: m['habitKey'] as String? ?? 'move',
      date: parseDateKey(m['date']) ?? _today(),
      hour: (m['hour'] as num?)?.toInt() ?? 0,
      minute: (m['minute'] as num?)?.toInt() ?? 0,
      durationMin: (m['durationMin'] as num?)?.toInt(),
      timeOptions: options is List
          ? [
              for (final o in options)
                if (o is Map) SuggestionTime.fromMap(o)
            ]
          : const [],
      accepted: m['accepted'] as bool? ?? false,
    );
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

class Suggestion {
  const Suggestion({
    required this.id,
    required this.fromUid,
    required this.fromName,
    this.fromRelation,
    this.message = '',
    required this.items,
    this.status = SuggestionStatus.pending,
    this.popupShown = false,
    required this.createdAt,
  });

  final String id;
  final String fromUid;

  /// Tên người gửi giữ nguyên (SG-05), vd. "Mai". Không gửi lên analytics.
  final String fromName;

  /// Quan hệ với Bác, vd. "Con gái" (G02 chip "Mai · Con gái"). `null` = không ghi.
  final String? fromRelation;

  /// Lời nhắn (có thể rỗng). Không gửi lên analytics.
  final String message;
  final List<SuggestionItem> items;
  final SuggestionStatus status;

  /// Popup G10 / G11 đã hiện (chỉ hiện một lần).
  final bool popupShown;

  /// Lúc gửi ("Mai vừa gửi lúc 4:20 chiều").
  final DateTime createdAt;

  int get acceptedCount => items.where((i) => i.accepted).length;

  /// Việc chưa nhận (G07: còn chip "Gợi ý của Mai").
  List<SuggestionItem> get remaining => [
        for (final i in items)
          if (!i.accepted) i
      ];

  Suggestion copyWith({
    String? id,
    String? fromRelation,
    String? message,
    List<SuggestionItem>? items,
    SuggestionStatus? status,
    bool? popupShown,
    DateTime? createdAt,
  }) =>
      Suggestion(
        id: id ?? this.id,
        fromUid: fromUid,
        fromName: fromName,
        fromRelation: fromRelation ?? this.fromRelation,
        message: message ?? this.message,
        items: items ?? this.items,
        status: status ?? this.status,
        popupShown: popupShown ?? this.popupShown,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Không ghi `id` (là id tài liệu Firestore).
  Map<String, Object?> toMap() => {
        'fromUid': fromUid,
        'fromName': fromName,
        if (fromRelation != null) 'fromRelation': fromRelation,
        'message': message,
        'items': [for (final i in items) i.toMap()],
        'status': status.name,
        'popupShown': popupShown,
        'createdAt': createdAt,
      };

  factory Suggestion.fromMap(String id, Map<String, Object?> m) {
    final items = m['items'];
    return Suggestion(
      id: id,
      fromUid: m['fromUid'] as String? ?? '',
      fromName: m['fromName'] as String? ?? '',
      fromRelation: m['fromRelation'] as String?,
      message: m['message'] as String? ?? '',
      items: items is List
          ? [
              for (final i in items)
                if (i is Map) SuggestionItem.fromMap(i)
            ]
          : const [],
      status: SuggestionStatus.values.asNameMap()[m['status']] ??
          SuggestionStatus.pending,
      popupShown: m['popupShown'] as bool? ?? false,
      createdAt: _parseInstant(m['createdAt']),
    );
  }

  /// `DateTime`, mili-giây, chuỗi ISO hoặc Timestamp Firestore (có `toDate()`).
  static DateTime _parseInstant(Object? v) {
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    if (v != null) {
      try {
        return (v as dynamic).toDate() as DateTime;
      } catch (_) {/* rơi xuống mặc định */}
    }
    return DateTime.now();
  }
}
