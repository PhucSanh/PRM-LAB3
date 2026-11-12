import 'dart:async';

import '../models/suggestion.dart';
import '../utils/app_error.dart';

/// Gợi ý lịch giữa 2 máy (F12; F14 C08 cũng gửi qua đây).
/// Máy con cháu `send`; máy Bác `watchPending` / `byId` / `markPopupShown` /
/// `accept` / `dismiss` / `undoDismiss`.
///
/// Bản Firebase tạo việc và thông báo phản hồi trong cùng transaction.
abstract interface class SuggestionService {
  /// Máy con cháu gửi. `s.id` rỗng → service tự tạo id. Gợi ý lưu ở trạng thái
  /// `pending`, `popupShown: false`.
  Future<void> send(String momUid, Suggestion s);

  /// Máy Bác: các gợi ý `pending`, mới nhất trước.
  Stream<List<Suggestion>> watchPending(String momUid);

  /// Đọc một gợi ý ở mọi trạng thái (G09: đã bỏ qua vẫn xem lại được). `null` = không có.
  Future<Suggestion?> byId(String momUid, String id);

  /// Popup G10 / G11 đã hiện – không hiện lại.
  Future<void> markPopupShown(String momUid, String id);

  /// Đánh dấu [items] đã nhận. Nhận hết → `accepted`, còn việc chưa nhận → `partial`.
  /// Gọi lại được trên gợi ý `partial` để nhận tiếp việc còn lại (G07).
  /// [indexes] giữ vị trí gốc của từng việc khi giờ đã đổi.
  Future<void> accept(String momUid, String id, List<SuggestionItem> items,
      {List<int>? indexes});

  /// Bỏ qua các việc chưa nhận (G09).
  Future<void> dismiss(String momUid, String id);

  /// Hoàn tác bỏ qua: về `partial` nếu đã nhận việc nào, ngược lại `pending`.
  Future<void> undoDismiss(String momUid, String id);
}

/// Acceptance creates the tasks in the same server transaction.
abstract interface class AtomicSuggestionService implements SuggestionService {}

/// Bản giả trong bộ nhớ, theo `momUid`. Một instance dùng chung được cho
/// "máy con cháu gửi" và "máy Bác nhận" trong cùng một test.
class FakeSuggestionService implements SuggestionService {
  FakeSuggestionService({
    Map<String, List<Suggestion>> seed = const {},
    this.withSample = false,
    this.delay = const Duration(milliseconds: 300),
    this.failOnSend = false,
    this.failOnLoad = false,
    this.failOnAccept = false,
  }) {
    seed.forEach((momUid, list) {
      final box = _box(momUid);
      for (final s in list) {
        box[s.id] = s;
      }
    });
  }

  /// `true` → lần đầu đọc / ghi của một `momUid` sẽ có sẵn [figmaSample]
  /// (để chạy app bằng Fake vẫn thấy popup G10 / thẻ G12).
  final bool withSample;
  final Duration delay;
  bool failOnSend;
  bool failOnLoad;
  bool failOnAccept;

  /// Số lần "báo cho Bác có gợi ý mới" (FCM ở bản thật) – tăng mỗi lần `send`.
  int momNotified = 0;

  /// Bản giả chỉ mô phỏng trạng thái gợi ý.
  int get senderNotified => 0;

  static const sendError =
      AppException('Chưa gửi được gợi ý. Kiểm tra mạng rồi bấm "Thử lại" nhé.');
  static const loadError =
      AppException('Chưa tải được gợi ý. Bác bấm "Thử lại" nhé.');
  static const acceptError =
      AppException('Chưa thêm được vào lịch. Bác bấm "Thử lại" nhé.');
  static const notFound = AppException('Gợi ý này không còn nữa.');
  static const noItem = AppException('Bác chọn ít nhất một việc nhé.');

  /// Dữ liệu mẫu đúng Figma (đối chiếu 04/11/2026): Mai · Con gái gửi 2 việc
  /// cho ngày mai. Lời nhắn theo G03 cho cả popup G10 / G11 (DT trong docs).
  static Suggestion figmaSample({String id = 'sample-mai', DateTime? now}) {
    final n = now ?? DateTime.now();
    final tomorrow = DateTime(n.year, n.month, n.day + 1);
    const options = [SuggestionTime(8, 0), SuggestionTime(9, 0)];
    return Suggestion(
      id: id,
      fromUid: 'sample-mai-uid',
      fromName: 'Mai',
      fromRelation: 'Con gái',
      message: '“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”',
      items: [
        SuggestionItem(
          title: 'Đi bộ nhẹ nhàng',
          habitKey: 'move',
          date: tomorrow,
          hour: 8,
          minute: 0,
          durationMin: 20,
          timeOptions: options,
        ),
        SuggestionItem(
          title: 'Thư giãn nhẹ nhàng',
          habitKey: 'downshift',
          date: tomorrow,
          hour: 9,
          minute: 0,
          durationMin: 15,
          timeOptions: options,
        ),
      ],
      // Figma G10: "Mai vừa gửi lúc 4:20 chiều" (hôm nay).
      createdAt: DateTime(n.year, n.month, n.day, 16, 20),
    );
  }

  final _store = <String, Map<String, Suggestion>>{};
  final _sampled = <String>{};
  final _changes = StreamController<String>.broadcast(sync: true);
  int _seq = 0;

  Map<String, Suggestion> _box(String momUid) {
    final box = _store.putIfAbsent(momUid, () => <String, Suggestion>{});
    if (withSample && _sampled.add(momUid)) {
      final s = figmaSample();
      box.putIfAbsent(s.id, () => s);
    }
    return box;
  }

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  List<Suggestion> _pending(String momUid) => [
        for (final s in _box(momUid).values)
          if (s.status == SuggestionStatus.pending) s
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Suggestion _require(String momUid, String id) =>
      _box(momUid)[id] ?? (throw notFound);

  void _put(String momUid, Suggestion s) {
    _box(momUid)[s.id] = s;
    _changes.add(momUid);
  }

  @override
  Future<void> send(String momUid, Suggestion s) async {
    await _wait();
    if (failOnSend) throw sendError;
    final id = s.id.isEmpty ? 'sg-${++_seq}' : s.id;
    _put(
        momUid,
        s.copyWith(
          id: id,
          status: SuggestionStatus.pending,
          popupShown: false,
          items: [for (final i in s.items) i.copyWith(accepted: false)],
        ));
    momNotified++;
  }

  @override
  Stream<List<Suggestion>> watchPending(String momUid) =>
      Stream<List<Suggestion>>.multi((sink) {
        var ready = false;
        var closed = false;
        final sub = _changes.stream.where((u) => u == momUid).listen((_) {
          if (ready && !closed) sink.add(_pending(momUid));
        });
        _wait().then((_) {
          if (closed) return;
          if (failOnLoad) {
            sink.addError(loadError);
            return;
          }
          ready = true;
          sink.add(_pending(momUid));
        });
        sink.onCancel = () {
          closed = true;
          return sub.cancel();
        };
      });

  @override
  Future<Suggestion?> byId(String momUid, String id) async {
    await _wait();
    if (failOnLoad) throw loadError;
    return _box(momUid)[id];
  }

  @override
  Future<void> markPopupShown(String momUid, String id) async {
    await _wait();
    _put(momUid, _require(momUid, id).copyWith(popupShown: true));
  }

  @override
  Future<void> accept(String momUid, String id, List<SuggestionItem> items,
      {List<int>? indexes}) async {
    await _wait();
    if (failOnAccept) throw acceptError;
    if (items.isEmpty) throw noItem;
    final s = _require(momUid, id);
    final next = [...s.items];
    for (final (position, picked) in items.indexed) {
      final i = indexes?[position] ??
          next.indexWhere((x) => !x.accepted && x.sameTaskAs(picked));
      if (i >= 0) next[i] = next[i].copyWith(accepted: true);
    }
    final all = next.every((x) => x.accepted);
    _put(
        momUid,
        s.copyWith(
          items: next,
          popupShown: true,
          status: all ? SuggestionStatus.accepted : SuggestionStatus.partial,
        ));
  }

  @override
  Future<void> dismiss(String momUid, String id) async {
    await _wait();
    final s = _require(momUid, id);
    _put(momUid,
        s.copyWith(status: SuggestionStatus.dismissed, popupShown: true));
  }

  @override
  Future<void> undoDismiss(String momUid, String id) async {
    await _wait();
    final s = _require(momUid, id);
    if (s.status != SuggestionStatus.dismissed) return;
    _put(
        momUid,
        s.copyWith(
            status: s.acceptedCount > 0
                ? SuggestionStatus.partial
                : SuggestionStatus.pending));
  }

  Future<void> dispose() => _changes.close();
}
