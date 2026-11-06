import '../services/suggestion_service.dart';
import 'calm_feature_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/suggestion.dart';
import '../models/task_item.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'suggestion_compose_view_model.dart' show suggestionClockProvider;
import 'ui_state.dart';

/// F12 Bác xem và nhận gợi ý – chủ: Sanh. Route `/today/suggestions/:id?from=…`.
/// Biến thể Figma là **state** của màn, không phải route:
/// G03 `56:107` / G03b `56:201` ([SuggestionReviewStep.reviewing]) · G04 `57:2` ([changingTime]) ·
/// G05 `57:128` / G05b `58:2` ([accepted]) · G06 `58:117` ([choosing]) ·
/// G07 `61:2` / G07b `61:118` ([acceptedPartial]) · G09 `66:2` ([dismissed]).
///
/// Lịch Bác **chỉ đổi sau khi Bác bấm nhận**: [SuggestionReviewViewModel.acceptAll] mới gọi
/// `TaskRepository.save`; đổi giờ (G04 → G03b) chỉ đổi state, chưa ghi gì.
enum SuggestionReviewStep {
  /// G03 / G03b: xem gợi ý (G03b khi đã đổi giờ một việc).
  reviewing,

  /// G04: đổi giờ một việc (state toàn trang).
  changingTime,

  /// G06: chọn từng việc (chọn nhiều, mặc định chọn hết).
  choosing,

  /// G05 / G05b: đã nhận hết (G05b khi có việc đổi giờ).
  accepted,

  /// G07 / G07b: đã nhận một phần; việc còn lại "Gợi ý của …", nhận tiếp từ Gia đình.
  acceptedPartial,

  /// G09: đã bỏ qua (màn kết quả có nút "Hoàn tác").
  dismissed,
}

/// Nơi mở gợi ý. Mọi lối vào đều là một lần chạm của Bác (M6), trừ [direct].
enum SuggestionEntry {
  /// Popup G10 / G11 "Xem gợi ý".
  popup,

  /// Thẻ G12 trên Hôm nay.
  card,

  /// Bấm thông báo đẩy.
  push,

  /// Màn Gia đình (S09) – nhãn back theo Figma ("Gia đình").
  family,

  /// Không rõ (deep link, mở lại) – không tính chạm.
  direct;

  /// `?from=popup` → [popup]; giá trị lạ → [direct].
  static SuggestionEntry fromQuery(String? from) =>
      SuggestionEntry.values.asNameMap()[from] ?? SuggestionEntry.direct;

  int get openTaps => this == SuggestionEntry.direct ? 0 : 1;
}

class SuggestionReview {
  const SuggestionReview({
    required this.momUid,
    required this.suggestion,
    required this.times,
    required this.selected,
    required this.dayLabel,
    this.entry = SuggestionEntry.direct,
    this.step = SuggestionReviewStep.reviewing,
    this.editIndex,
    this.pendingTime,
    this.acceptedNow = const [],
    this.taps = 0,
    this.busy = false,
    this.actionError,
    this.needSelection = false,
  });

  final String momUid;
  final Suggestion suggestion;
  final SuggestionEntry entry;

  /// Giờ Bác chọn cho từng việc (cùng chỉ số với `suggestion.items`).
  final List<SuggestionTime> times;

  /// G06: chỉ số các việc đang chọn. Mặc định = các việc chưa nhận.
  final Set<int> selected;
  final SuggestionReviewStep step;

  /// "ngày mai" / "hôm nay" / "ngày 6/11" – ngày của các việc so với hôm nay.
  final String dayLabel;

  /// G04: việc đang đổi giờ + giờ đang chọn (chưa lưu).
  final int? editIndex;
  final SuggestionTime? pendingTime;

  /// G05: chỉ số các việc vừa nhận trong lần bấm này.
  final List<int> acceptedNow;

  /// Số chạm từ lúc mở (lối vào đã tính 1) – `accept_suggestion.taps` (M6 ≤ 2).
  final int taps;

  /// Đang lưu: nút "Thêm vào lịch" hiện vòng xoay, không bấm lại được.
  final bool busy;

  /// Lỗi hành động (`AppException.userMessage`); lựa chọn vẫn giữ.
  final String? actionError;

  /// G06: bấm "Tiếp tục" khi chưa chọn việc nào → hiện câu nhắc (DT-32).
  final bool needSelection;

  /// Việc chưa nhận (gợi ý `partial` chỉ còn các việc này), theo chỉ số gốc.
  List<int> get remaining => [
        for (var i = 0; i < suggestion.items.length; i++)
          if (!suggestion.items[i].accepted) i
      ];

  /// Việc i đã đổi giờ so với gợi ý (`accept_suggestion.changed_time`).
  bool changedTime(int i) => times[i] != suggestion.items[i].time;

  /// G03b: việc đầu tiên đã đổi giờ (null = G03).
  int? get changedIndex => remaining.where(changedTime).firstOrNull;

  /// Nút "Đổi giờ …" (G03): việc chưa nhận đầu tiên có ≥ 2 giờ để chọn (DT-31).
  int? get changeableIndex => remaining
      .where((i) => suggestion.items[i].timeOptions.length >= 2)
      .firstOrNull;

  /// G05b: trong các việc vừa nhận có việc đã đổi giờ.
  bool get acceptedWithChangedTime => acceptedNow.any(changedTime);

  /// Việc i với giờ Bác đã chọn.
  SuggestionItem itemAt(int i) => suggestion.items[i]
      .copyWith(hour: times[i].hour, minute: times[i].minute);

  SuggestionReview copyWith({
    Suggestion? suggestion,
    List<SuggestionTime>? times,
    Set<int>? selected,
    SuggestionReviewStep? step,
    int? editIndex,
    SuggestionTime? pendingTime,
    List<int>? acceptedNow,
    int? taps,
    bool? busy,
    String? actionError,
    bool? needSelection,
  }) =>
      SuggestionReview(
        momUid: momUid,
        suggestion: suggestion ?? this.suggestion,
        entry: entry,
        times: times ?? this.times,
        selected: selected ?? this.selected,
        dayLabel: dayLabel,
        step: step ?? this.step,
        editIndex: editIndex ?? this.editIndex,
        pendingTime: pendingTime ?? this.pendingTime,
        acceptedNow: acceptedNow ?? this.acceptedNow,
        taps: taps ?? this.taps,
        busy: busy ?? this.busy,
        actionError: actionError,
        needSelection: needSelection ?? this.needSelection,
      );
}

const _loadFailed = 'Chưa tải được gợi ý. Bác bấm "Thử lại" nhé.';
const _acceptFailed = 'Chưa thêm được vào lịch. Bác bấm "Thử lại" nhé.';
const _dismissFailed = 'Chưa bỏ qua được gợi ý. Bác bấm lại nhé.';
const _undoFailed = 'Chưa hoàn tác được. Bác bấm "Hoàn tác" lại nhé.';

/// "ngày mai" / "hôm nay" / "ngày 6/11" – dùng chung cho G03–G09 và popup G10 / G11.
String suggestionDayLabel(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  if (d == today) return 'hôm nay';
  if (d == DateTime(today.year, today.month, today.day + 1)) return 'ngày mai';
  return 'ngày ${d.day}/${d.month}';
}

typedef SuggestionReviewArgs = ({String id, SuggestionEntry entry});

/// UiEmpty = không tìm thấy gợi ý hoặc đã nhận hết (Figma không vẽ – DT-31).
class SuggestionReviewViewModel extends Notifier<UiState<SuggestionReview>> {
  SuggestionReviewViewModel(this.args);

  final SuggestionReviewArgs args;

  @override
  UiState<SuggestionReview> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  /// Tải gợi ý; cũng là "Thử lại" khi lỗi.
  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      state = const UiError('Bác cần đăng nhập lại.');
      return;
    }
    try {
      final s = await ref.read(suggestionServiceProvider).byId(uid, args.id);
      if (!ref.mounted) return;
      if (s == null ||
          s.status == SuggestionStatus.accepted ||
          s.items.isEmpty) {
        state = const UiEmpty();
        return;
      }
      final remaining = {
        for (var i = 0; i < s.items.length; i++)
          if (!s.items[i].accepted) i
      };
      state = UiData(SuggestionReview(
        momUid: uid,
        suggestion: s,
        entry: args.entry,
        times: [for (final i in s.items) i.time],
        selected: remaining,
        dayLabel: suggestionDayLabel(
            s.items.first.date, ref.read(suggestionClockProvider)()),
        taps: args.entry.openTaps,
      ));
    } catch (e) {
      if (!ref.mounted) return;
      state = UiError(e is AppException ? e.userMessage : _loadFailed);
    }
  }

  void _update(SuggestionReview Function(SuggestionReview) change) {
    if (state case UiData(:final data)) state = UiData(change(data));
  }

  /// G03 "Đổi giờ …" → G04 cho việc [index]. Chưa ghi gì vào lịch.
  void startChangeTime(int index) => _update((d) {
        if (d.busy ||
            d.step != SuggestionReviewStep.reviewing ||
            !d.remaining.contains(index)) {
          return d;
        }
        return d.copyWith(
          step: SuggestionReviewStep.changingTime,
          editIndex: index,
          pendingTime: d.times[index],
          taps: d.taps + 1,
        );
      });

  /// G04: chọn một giờ trong các giờ của việc (không dùng bánh xe giờ).
  void pickTime(SuggestionTime time) => _update((d) {
        if (d.step != SuggestionReviewStep.changingTime) return d;
        final options = d.suggestion.items[d.editIndex!].timeOptions;
        if (!options.contains(time)) return d;
        return d.copyWith(pendingTime: time, taps: d.taps + 1);
      });

  /// G04 "Lưu giờ mới" → G03b (hoặc G03 nếu chọn lại giờ gốc). Lịch **chưa** đổi.
  void saveNewTime() => _update((d) {
        if (d.step != SuggestionReviewStep.changingTime) return d;
        final times = [...d.times];
        times[d.editIndex!] = d.pendingTime!;
        return d.copyWith(
            times: times,
            step: SuggestionReviewStep.reviewing,
            taps: d.taps + 1);
      });

  /// G04 "Quay lại" → G03, bỏ giờ đang chọn.
  void cancelChangeTime() =>
      _update((d) => d.step == SuggestionReviewStep.changingTime
          ? d.copyWith(step: SuggestionReviewStep.reviewing, taps: d.taps + 1)
          : d);

  /// G03 "Thêm vào lịch" → G05 / G05b: nhận mọi việc chưa nhận. Xem [_accept].
  Future<bool> acceptAll() async {
    final data = _data;
    if (data == null ||
        data.busy ||
        data.step != SuggestionReviewStep.reviewing) {
      return false;
    }
    return _accept(data, data.remaining, taps: data.taps + 1);
  }

  /// Lưu từng việc [indexes] (đúng ngày + giờ đã chọn) bằng `TaskRepository.save`, rồi
  /// `SuggestionService.accept`, rồi đặt nhắc (nếu máy đã cho phép). Nhận hết → G05 / G05b,
  /// còn việc → G07 / G07b. Lỗi giữa chừng → **xoá các việc vừa lưu** (lịch không nửa vời, Bác bấm
  /// lại là đủ – người dùng chọn 04/11), ghi Crashlytics, `actionError`. Log
  /// `accept_suggestion { count, changed_time, partial, taps }`. `true` khi đã nhận.
  Future<bool> _accept(SuggestionReview data, List<int> indexes,
      {required int taps}) async {
    if (indexes.isEmpty) return false;
    state = UiData(data.copyWith(busy: true, taps: taps));

    final tasks = ref.read(taskRepositoryProvider);
    final s = data.suggestion;
    final items = [for (final i in indexes) data.itemAt(i)];
    final toSave = [
      for (final (k, i) in indexes.indexed) items[k].toTask('sg-${s.id}-$i'),
    ];
    final saved = <TaskItem>[];
    try {
      if (ref.read(suggestionServiceProvider) is! AtomicSuggestionService) {
        for (final task in toSave) {
          await tasks.save(task);
          saved.add(task);
        }
      }
      await ref
          .read(suggestionServiceProvider)
          .accept(data.momUid, s.id, items);
    } catch (e, st) {
      for (final task in saved.reversed) {
        try {
          await tasks.delete(task.id);
        } catch (_) {/* Đã cố xoá; lỗi xoá không che lỗi gốc. */}
      }
      await _record(e, st, 'accept_suggestion');
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          busy: false,
          actionError: e is AppException ? e.userMessage : _acceptFailed));
      return false;
    }
    if (!ref.mounted) return false;
    ref.invalidate(calendarTasksProvider);
    final next = [
      for (var i = 0; i < s.items.length; i++)
        indexes.contains(i)
            // Giữ giờ gốc của gợi ý để G05b biết việc nào đã đổi giờ.
            ? s.items[i].copyWith(accepted: true)
            : s.items[i],
    ];
    final all = next.every((i) => i.accepted);
    _update((d) => d.copyWith(
          suggestion: s.copyWith(
              items: next,
              status:
                  all ? SuggestionStatus.accepted : SuggestionStatus.partial),
          busy: false,
          step: all
              ? SuggestionReviewStep.accepted
              : SuggestionReviewStep.acceptedPartial,
          acceptedNow: indexes,
        ));
    if (ref.read(suggestionServiceProvider) is! AtomicSuggestionService) {
      await _scheduleReminders(toSave);
    }
    await _log('accept_suggestion', {
      'count': indexes.length,
      'changed_time': indexes.any(data.changedTime),
      'partial': !all,
      'taps': taps,
    });
    return true;
  }

  SuggestionReview? get _data =>
      switch (state) { UiData(:final data) => data, _ => null };

  Future<void> _record(Object e, StackTrace st, String reason) async {
    try {
      await ref.read(crashServiceProvider).recordError(e, st, reason: reason);
    } catch (_) {/* Crashlytics không được chặn Bác. */}
  }

  Future<void> _log(String name, Map<String, Object> params) async {
    try {
      await ref.read(analyticsServiceProvider).logEvent(name, params);
    } catch (_) {/* Analytics không được chặn Bác. */}
  }

  /// Đặt nhắc cho việc vừa nhận nếu máy đã cho phép (như F2 N05). Lỗi không chặn Bác.
  Future<void> _scheduleReminders(List<TaskItem> saved) async {
    try {
      final reminders = ref.read(reminderServiceProvider);
      if (!await reminders.hasPermission()) return;
      for (final task in saved) {
        await reminders.schedule(task);
      }
    } catch (e, st) {
      await _record(e, st, 'schedule_suggestion');
    }
  }

  /// G03 "Chọn từng việc" → G06; mặc định chọn hết các việc chưa nhận (như Figma G06).
  void startChoosing() => _update((d) {
        if (d.busy || d.step != SuggestionReviewStep.reviewing) return d;
        return d.copyWith(
          step: SuggestionReviewStep.choosing,
          selected: d.remaining.toSet(),
          needSelection: false,
          taps: d.taps + 1,
        );
      });

  /// G06: chạm thẻ việc [index] để chọn / bỏ chọn (chọn nhiều).
  void toggle(int index) => _update((d) {
        if (d.busy ||
            d.step != SuggestionReviewStep.choosing ||
            !d.remaining.contains(index)) {
          return d;
        }
        final selected = {...d.selected};
        if (!selected.remove(index)) selected.add(index);
        return d.copyWith(
            selected: selected, needSelection: false, taps: d.taps + 1);
      });

  /// G06 "Quay lại" → G03, giữ giờ đã đổi.
  void backToReview() =>
      _update((d) => d.step == SuggestionReviewStep.choosing && !d.busy
          ? d.copyWith(
              step: SuggestionReviewStep.reviewing,
              needSelection: false,
              taps: d.taps + 1)
          : d);

  /// G06 "Tiếp tục": lưu luôn các việc đã chọn (không có bước xác nhận – DT-32) → G07 / G07b
  /// (chọn hết → G05). Chưa chọn việc nào → `needSelection` (câu nhắc trên nút), không lưu gì.
  Future<bool> continueChoosing() async {
    final data = _data;
    if (data == null ||
        data.busy ||
        data.step != SuggestionReviewStep.choosing) {
      return false;
    }
    final indexes = [
      for (final i in data.remaining)
        if (data.selected.contains(i)) i
    ];
    if (indexes.isEmpty) {
      state = UiData(data.copyWith(needSelection: true, taps: data.taps + 1));
      return false;
    }
    return _accept(data.copyWith(needSelection: false), indexes,
        taps: data.taps + 1);
  }

  /// G03 "Bỏ qua gợi ý" → G09 (không hỏi lại – lịch không đổi, G09 có "Hoàn tác").
  /// `SuggestionService.dismiss` chỉ đổi `status`; **không** báo gì cho người gửi (FR08).
  /// Log `dismiss_suggestion { items }`.
  Future<bool> dismiss() async {
    final data = _data;
    if (data == null ||
        data.busy ||
        data.step != SuggestionReviewStep.reviewing) {
      return false;
    }
    state = UiData(data.copyWith(busy: true, taps: data.taps + 1));
    try {
      await ref
          .read(suggestionServiceProvider)
          .dismiss(data.momUid, data.suggestion.id);
    } catch (e, st) {
      await _record(e, st, 'dismiss_suggestion');
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          busy: false,
          actionError: e is AppException ? e.userMessage : _dismissFailed));
      return false;
    }
    if (!ref.mounted) return false;
    _update((d) => d.copyWith(
          suggestion: d.suggestion.copyWith(status: SuggestionStatus.dismissed),
          busy: false,
          step: SuggestionReviewStep.dismissed,
        ));
    await _log('dismiss_suggestion', {'items': data.remaining.length});
    return true;
  }

  /// G09 "Hoàn tác" → G03 nguyên trạng (giờ đã đổi vẫn giữ). Log
  /// `undo_action { action: dismiss_suggestion }`.
  Future<bool> undoDismiss() async {
    final data = _data;
    if (data == null ||
        data.busy ||
        data.step != SuggestionReviewStep.dismissed) {
      return false;
    }
    state = UiData(data.copyWith(busy: true));
    try {
      await ref
          .read(suggestionServiceProvider)
          .undoDismiss(data.momUid, data.suggestion.id);
    } catch (e, st) {
      await _record(e, st, 'undo_dismiss_suggestion');
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          busy: false,
          actionError: e is AppException ? e.userMessage : _undoFailed));
      return false;
    }
    if (!ref.mounted) return false;
    _update((d) => d.copyWith(
          suggestion: d.suggestion.copyWith(
              status: d.suggestion.acceptedCount > 0
                  ? SuggestionStatus.partial
                  : SuggestionStatus.pending),
          busy: false,
          step: SuggestionReviewStep.reviewing,
        ));
    await _log('undo_action', {'action': 'dismiss_suggestion'});
    return true;
  }
}

final suggestionReviewViewModelProvider = NotifierProvider.autoDispose.family<
    SuggestionReviewViewModel,
    UiState<SuggestionReview>,
    SuggestionReviewArgs>(SuggestionReviewViewModel.new);
