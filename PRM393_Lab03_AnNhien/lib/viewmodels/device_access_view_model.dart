import 'dart:async';

import 'package:clock/clock.dart';
import '../models/task_item.dart';
import '../models/voice_task_draft.dart';
import '../services/profile_setup_service.dart';
import '../services/remote_config_service.dart';
import '../services/local_voice_task_service.dart'
    show parseDurationMinutes, durationQuestion;
import 'caregiver_schedule_view_model.dart' show vietnamToday;
import 'daily_actions_view_model.dart';
import 'schedule_conflict.dart';
import 'voice_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'calm_feature_providers.dart';
import 'session_view_model.dart';
import 'task_form_view_model.dart';
import 'today_view_model.dart';

final _voiceConfigUpdatesProvider = StreamProvider<Set<String>>(
    (ref) => ref.watch(remoteConfigServiceProvider).onUpdated);
final voiceInputEnabledProvider = Provider<bool>((ref) {
  ref.watch(_voiceConfigUpdatesProvider);
  return ref
      .watch(remoteConfigServiceProvider)
      .getBool(RemoteConfigKeys.voiceInputEnabled);
});

String deviceError(Object error) => error is AppException
    ? error.userMessage
    : 'Chưa thực hiện được. Bác thử lại nhé.';

class VoiceDraft {
  const VoiceDraft(
      {this.text = '',
      this.busy = false,
      this.interpreting = false,
      this.error,
      this.followUp = '',
      this.utterances = const [],
      this.interpretation,
      this.conflict,
      this.reply,
      this.addedDay,
      this.adding = false});
  final String text, followUp;
  final bool busy, interpreting, adding;
  final String? error;
  final List<String> utterances;
  final VoiceTaskInterpretation? interpretation;

  /// Câu báo trùng giờ với việc đã có (chỉ hiện trên máy, không gửi đi).
  final String? conflict;

  /// Câu cháu trả lời một lệnh ("làm xong rồi", "việc tiếp theo"), đã đọc to.
  final String? reply;

  /// Ngày của việc vừa thêm bằng giọng nói, để View mở lịch đúng ngày đó.
  final DateTime? addedDay;

  /// [error], [conflict] và [reply] không giữ lại khi không truyền (giống [error] cũ).
  VoiceDraft copyWith(
          {String? text,
          String? followUp,
          bool? busy,
          bool? interpreting,
          bool? adding,
          String? error,
          List<String>? utterances,
          VoiceTaskInterpretation? interpretation,
          String? conflict,
          String? reply}) =>
      VoiceDraft(
          text: text ?? this.text,
          followUp: followUp ?? this.followUp,
          busy: busy ?? this.busy,
          interpreting: interpreting ?? this.interpreting,
          adding: adding ?? this.adding,
          error: error,
          utterances: utterances ?? this.utterances,
          interpretation: interpretation ?? this.interpretation,
          conflict: conflict,
          reply: reply);
}

/// Ngữ cảnh của Bác gửi kèm câu nói. Lỗi đọc hồ sơ / lịch không chặn việc
/// hiểu lời nói: thiếu phần nào thì bỏ phần đó.
Future<(VoiceUserContext, List<TaskItem>)> loadVoiceContext(
    Ref ref, String uid, DateTime day) async {
  ProfileSetup? setup;
  var tasks = const <TaskItem>[];
  try {
    setup = await ref
        .read(profileSetupServiceProvider)
        .watchSetup(uid)
        .first
        .timeout(const Duration(seconds: 3));
  } catch (_) {/* hồ sơ chưa có hoặc chưa tải được */}
  final repo = ref.read(taskRepositoryProvider);
  try {
    tasks = await repo.tasksForDay(day).timeout(const Duration(seconds: 5));
  } catch (_) {/* lịch chưa tải được */}
  // 7 ngày tới, chỉ giờ / số phút / nhóm (không tên việc), để AI trả lời
  // "mai tui rảnh lúc nào".
  final week = <VoiceBusySlot>[];
  try {
    final today = vietnamToday();
    final days = await Future.wait([
      for (var i = 0; i < 7; i++)
        repo.tasksForDay(DateTime(today.year, today.month, today.day + i))
    ]).timeout(const Duration(seconds: 5));
    for (final (i, list) in days.indexed) {
      final date = DateTime(today.year, today.month, today.day + i);
      for (final t in [...list]..sort((a, b) =>
          (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute))) {
        if (t.status == TaskStatus.skipped) continue;
        week.add(VoiceBusySlot(
            date: date,
            hour: t.hour,
            minute: t.minute,
            durationMinutes: t.durationMinutes,
            habitKey: t.habitKey));
      }
    }
  } catch (_) {/* lịch tuần chưa tải được: AI vẫn hiểu câu thêm việc */}
  final sorted = [
    ...tasks
  ]..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  return (
    VoiceUserContext(
        honorific: setup?.honorific.name,
        wakeHour: setup?.wakeHour,
        wakeMinute: setup?.wakeMinute,
        busy: sorted
            .take(VoiceUserContext.maxBusy)
            .map((t) => VoiceBusySlot(
                hour: t.hour,
                minute: t.minute,
                durationMinutes: t.durationMinutes,
                habitKey: t.habitKey))
            .toList(growable: false),
        week: List.unmodifiable(week.take(VoiceUserContext.maxWeek))),
    tasks
  );
}

class VoiceInputViewModel extends Notifier<VoiceDraft> {
  int _generation = 0;
  @override
  VoiceDraft build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    ref.onDispose(() {
      _generation++;
    });
    return const VoiceDraft();
  }

  bool _active(int generation, String? uid) =>
      ref.mounted &&
      generation == _generation &&
      uid == ref.read(sessionProvider).value?.uid;

  void edit(String text) {
    if (state.busy) return;
    _generation++;
    state = VoiceDraft(text: text);
  }

  void editFollowUp(String text) {
    if (!state.busy) state = state.copyWith(followUp: text);
  }

  Future<void> listen({bool followUp = false}) async {
    if (state.busy) return;
    if (!ref.read(voiceInputEnabledProvider)) {
      state = state.copyWith(
          error: 'Nhập giọng nói đang tạm tắt. Bác có thể gõ tên việc.');
      return;
    }
    final uid = ref.read(sessionProvider).value?.uid,
        generation = ++_generation;
    final before = state;
    state = state.copyWith(busy: true);
    try {
      await ref.read(speechViewModelProvider.notifier).stop();
      if (!_active(generation, uid)) return;
      final text = await ref.read(deviceAccessServiceProvider).recognize();
      if (!_active(generation, uid)) return;
      state = text?.trim().isNotEmpty == true
          ? followUp
              ? before.copyWith(followUp: text!.trim(), busy: false)
              : VoiceDraft(text: text!.trim())
          : before.copyWith(busy: false);
    } catch (e) {
      if (_active(generation, uid)) {
        state = before.copyWith(busy: false, error: deviceError(e));
      }
    }
  }

  /// Hiểu câu Bác nói. Lệnh "làm xong" trả về thay đổi để View hiện
  /// "Hoàn tác"; thêm việc mới thì trả `null`.
  Future<QuickTaskUndo?> analyze() async {
    if (state.busy || state.text.trim().isEmpty) return null;
    if (!ref.read(voiceInputEnabledProvider)) {
      state = state.copyWith(
          error: 'Hiểu lời nói đang tạm tắt. Bác có thể nhập tay.');
      return null;
    }
    final uid = ref.read(sessionProvider).value?.uid;
    if (uid == null) {
      state =
          state.copyWith(error: 'Bác đăng nhập lại để dùng hiểu lời nói nhé.');
      return null;
    }
    final clarification = state.interpretation?.question != null;
    if (!clarification) {
      final command = parseVoiceCommand(state.text);
      if (command != null) return _runCommand(command, uid);
    }
    if (clarification && state.followUp.trim().isEmpty) {
      state = state.copyWith(error: 'Bác trả lời câu hỏi bên trên nhé.');
      return null;
    }
    final turns = clarification
        ? [...state.utterances, state.followUp.trim()]
        : [state.text.trim()];
    if (turns.length > 4 || turns.any((s) => s.length > 500)) {
      state = state.copyWith(
          error:
              'Bác sửa câu nói ban đầu, gộp tên việc, ngày và giờ trong một câu ngắn nhé.');
      return null;
    }
    final before = state, generation = ++_generation;
    state = state.copyWith(busy: true, interpreting: true);
    try {
      await ref.read(speechViewModelProvider.notifier).stop();
      if (!_active(generation, uid)) return null;
      final contextDate = ref.read(taskFormViewModelProvider).date;
      final (userContext, _) =
          await loadVoiceContext(ref, uid, contextDate ?? clock.now());
      if (!_active(generation, uid)) return null;
      var result = await ref
          .read(voiceTaskServiceProvider)
          .interpret(turns, contextDate: contextDate, userContext: userContext);
      if (!_active(generation, uid)) return null;
      // Không phải thêm việc: app tự đọc lịch / đánh dấu trên máy; AI chỉ
      // phân loại. Câu trả lời tự do của AI chỉ hiển thị và đọc to.
      if (result.intent != VoiceIntent.add) {
        state = before;
        return await switch (result.intent) {
          VoiceIntent.answer => _answer(result.reply!, generation, uid),
          VoiceIntent.agenda => _runCommand(VoiceCommandKind.agenda, uid,
              from: result.queryDate, days: result.queryDays),
          VoiceIntent.complete => _runCommand(VoiceCommandKind.complete, uid),
          _ => _runCommand(VoiceCommandKind.next, uid),
        };
      }
      result = _withDuration(result, turns);
      String? conflict;
      if (result.ready) {
        final hit = await findScheduleConflict(ref.read(taskRepositoryProvider),
            result.draft.toTask('voice-draft'));
        if (!_active(generation, uid)) return null;
        if (hit != null) conflict = overlapMessage(hit);
      }
      state = before.copyWith(
          busy: false,
          interpreting: false,
          interpretation: result,
          conflict: conflict,
          utterances: List.unmodifiable(turns),
          followUp: '');
      // Read only a checked proposal or a clarification; never execute model output.
      await ref
          .read(speechViewModelProvider.notifier)
          .read(result.question ?? conflict ?? result.draft.reviewText);
    } catch (e) {
      if (_active(generation, uid)) {
        state = before.copyWith(
            busy: false, interpreting: false, error: deviceError(e));
      }
    }
    return null;
  }

  /// Server chưa trả thời lượng: tự hiểu từ câu nói, không được thì hỏi lại.
  VoiceTaskInterpretation _withDuration(
      VoiceTaskInterpretation result, List<String> turns) {
    if (result.question != null ||
        !result.draft.scheduleComplete ||
        result.draft.durationMinutes != null) {
      return result;
    }
    final minutes = parseDurationMinutes(turns);
    return minutes == null
        ? result.copyWith(question: durationQuestion)
        : result.copyWith(draft: result.draft.withDuration(minutes));
  }

  /// "Làm xong rồi" → đánh dấu xong việc hôm nay rồi báo việc tiếp theo;
  /// "Việc tiếp theo?" → chỉ báo; "Công việc ngày mai?" → đọc lịch ngày đó. Không gọi AI, không đoán việc ngày khác.
  Future<QuickTaskUndo?> _answer(
      String reply, int generation, String uid) async {
    await ref
        .read(analyticsServiceProvider)
        .logEvent('voice_command', {'action': 'answer', 'success': true});
    if (!_active(generation, uid)) return null;
    state = VoiceDraft(reply: reply);
    await ref.read(speechViewModelProvider.notifier).read(reply);
    return null;
  }

  /// [from] / [days]: ngày AI hiểu cho câu hỏi lịch; không có thì tự đọc
  /// ngày trong câu nói (luật trên máy).
  Future<QuickTaskUndo?> _runCommand(VoiceCommandKind kind, String uid,
      {DateTime? from, int days = 1}) async {
    final before = state, generation = ++_generation;
    final analytics = ref.read(analyticsServiceProvider);
    state = state.copyWith(busy: true, interpreting: true);
    QuickTaskUndo? change;
    String reply;
    try {
      await ref.read(speechViewModelProvider.notifier).stop();
      final today = vietnamToday(), now = vietnamNow();
      final offset = kind != VoiceCommandKind.agenda
          ? 0
          : from != null
              ? calendarDate(from).difference(today).inDays.clamp(0, 365)
              : agendaDayOffset(before.text, today);
      final day = DateTime(today.year, today.month, today.day + offset);
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.tasksForDay(day);
      if (!_active(generation, uid)) return null;
      if (kind == VoiceCommandKind.complete) {
        final done = taskToComplete(before.text, tasks, now);
        if (done == null) {
          reply = 'Hôm nay Bác không còn việc nào chưa làm. '
              '${nextTaskSentence(null)}';
        } else {
          change =
              await ref.read(dailyActionsProvider.notifier).complete(done, day);
          if (!_active(generation, uid)) return change;
          if (change == null) {
            throw const AppException(
                'Cháu đang cập nhật việc khác. Bác nói lại sau giây lát nhé.');
          }
          reply = completedSentence(
              done, nextOpenTask(tasks, now, except: done.id));
        }
      } else if (kind == VoiceCommandKind.agenda) {
        final parts = [agendaSentence(day, offset, tasks)];
        for (var i = 1; i < days.clamp(1, 7); i++) {
          final d = DateTime(day.year, day.month, day.day + i);
          parts.add(agendaSentence(d, offset + i, await repo.tasksForDay(d)));
          if (!_active(generation, uid)) return null;
        }
        reply = parts.join(' ');
      } else {
        reply = nextTaskSentence(nextOpenTask(tasks, now));
      }
      await analytics.logEvent('voice_command',
          {'action': kind.name, 'success': true, 'changed': change != null});
      if (!_active(generation, uid)) return change;
      // Hỏi lịch thì kèm nút mở Lịch đúng ngày đó.
      state = VoiceDraft(
          reply: reply, addedDay: kind == VoiceCommandKind.agenda ? day : null);
      await ref.read(speechViewModelProvider.notifier).read(reply);
      return change;
    } catch (e) {
      await analytics
          .logEvent('voice_command', {'action': kind.name, 'success': false});
      if (_active(generation, uid)) {
        state = before.copyWith(
            busy: false, interpreting: false, error: deviceError(e));
      }
      return null;
    }
  }

  /// Explicit manual fallback. Never persists and never interprets a sentence as a command.
  bool confirm() {
    if (state.busy) return false;
    if (state.text.trim().length > 80) {
      state = state.copyWith(
          error: 'Bác rút gọn tên việc còn tối đa 80 ký tự để nhập tay nhé.');
      return false;
    }
    final form = ref.read(taskFormViewModelProvider.notifier);
    final old = ref.read(taskFormViewModelProvider);
    if (old.date == null || old.mode == TaskFormMode.edit) form.startCreate();
    form.setTitle(state.text.trim());
    return true;
  }

  bool confirmInterpretation() {
    final result = state.interpretation;
    if (state.busy || result == null || !result.ready) return false;
    final draft = result.draft;
    if (!draft.isFuture(clock.now())) {
      state = state.copyWith(
          error: 'Thời điểm này đã qua. Bác sửa câu nói và chọn giờ khác nhé.');
      return false;
    }
    final form = ref.read(taskFormViewModelProvider.notifier);
    form.startCreate(
        day: draft.date, activity: draft.habitKey, title: draft.title!);
    form.setDate(draft.date!);
    form.setTime(
        hour: draft.hour!, minute: draft.minute!, isAm: draft.hour! < 12);
    form.setRepeat(draft.repeat);
    if (draft.durationMinutes != null) form.setDuration(draft.durationMinutes!);
    form.setWeekdays(draft.weekdays.isEmpty
        ? {draft.date!.weekday}
        : draft.weekdays.toSet());
    return true;
  }

  /// Thêm thẳng bản nháp đã đủ thông tin vào lịch của Bác. Trả về việc đã lưu
  /// để View hiện "Hoàn tác"; `null` khi chưa lưu được (lỗi nằm trong state).
  Future<TaskItem?> addToSchedule() async {
    final result = state.interpretation;
    if (state.busy || result == null || !result.ready) return null;
    if (state.conflict != null) {
      // Một khung giờ chỉ một việc: phải chọn giờ khác trước khi lưu.
      state = state.copyWith(conflict: state.conflict);
      return null;
    }
    if (!result.draft.isFuture(clock.now())) {
      state = state.copyWith(
          conflict: state.conflict,
          error: 'Thời điểm này đã qua. Bác sửa câu nói và chọn giờ khác nhé.');
      return null;
    }
    final uid = ref.read(sessionProvider).value?.uid;
    final before = state, generation = ++_generation;
    state = state.copyWith(busy: true, adding: true, conflict: state.conflict);
    try {
      final task = await ref
          .read(voiceTaskWriterProvider)
          .add(result.draft, attempts: before.utterances.length);
      // Bắt đầu lượt mới để Bác nói tiếp việc khác, kèm lời báo đã thêm
      // vào ngày nào để Bác mở đúng lịch ngày đó.
      final draft = result.draft;
      if (_active(generation, uid)) {
        state = VoiceDraft(
            addedDay: draft.date,
            reply: 'Cháu đã thêm “${task.title}” vào ngày ${draft.dateLabel}, '
                'lúc ${draft.timeLabel}, làm trong ${draft.durationLabel}. '
                'Bác nói tiếp việc khác được.');
      }
      return task;
    } catch (e) {
      if (_active(generation, uid)) {
        state = e is ScheduleConflictException
            ? before.copyWith(conflict: e.userMessage)
            : before.copyWith(
                conflict: before.conflict,
                error: e is AppException
                    ? e.userMessage
                    : 'Chưa thêm được vào lịch. Bác thử lại hoặc nhập tay nhé.');
      }
      return null;
    }
  }
}

/// Lưu / hoàn tác việc thêm bằng giọng nói. Không autoDispose để "Hoàn tác"
/// trên snackbar vẫn chạy khi Bác đã rời màn nói.
class VoiceTaskWriter {
  VoiceTaskWriter(this._ref);
  final Ref _ref;

  Future<TaskItem> add(VoiceTaskDraft draft, {int attempts = 1}) async {
    final task = draft.toTask(clock.now().microsecondsSinceEpoch.toString());
    final analytics = _ref.read(analyticsServiceProvider);
    final repository = _ref.read(taskRepositoryProvider);
    final hit = await findScheduleConflict(repository, task);
    if (hit != null) throw ScheduleConflictException(hit);
    try {
      task.validate();
      await repository.save(task);
    } catch (error, stack) {
      await _ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: 'save_voice_task');
      await analytics
          .logEvent('voice_add_task', {'success': false, 'attempts': attempts});
      rethrow;
    }
    await analytics
        .logEvent('voice_add_task', {'success': true, 'attempts': attempts});
    await analytics.logEvent('add_task', {
      'habit_key': task.habitKey,
      'repeat': task.repeat.name,
      'source': 'voice',
    });
    _refresh();
    return task;
  }

  Future<void> undo(TaskItem task) async {
    await _ref.read(taskRepositoryProvider).delete(task.id);
    await _ref
        .read(analyticsServiceProvider)
        .logEvent('undo_action', {'action': 'voice_add_task'});
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(todayViewModelProvider);
    _ref.invalidate(calendarTasksProvider);
    _ref.invalidate(recentActivitiesProvider);
  }
}

final voiceTaskWriterProvider =
    Provider<VoiceTaskWriter>((ref) => VoiceTaskWriter(ref));

final voiceInputViewModelProvider =
    NotifierProvider.autoDispose<VoiceInputViewModel, VoiceDraft>(
        VoiceInputViewModel.new);

class SpeechState {
  const SpeechState({this.speaking = false, this.error, this.text});
  final bool speaking;
  final String? error;

  /// Câu đang đọc, để mỗi bong bóng biết nút của mình có đang phát không.
  final String? text;
}

class SpeechViewModel extends Notifier<SpeechState> {
  int _generation = 0;
  @override
  SpeechState build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    final service = ref.read(deviceAccessServiceProvider);
    ref.onDispose(() {
      _generation++;
      service.stopSpeaking().catchError((Object _) {});
    });
    return const SpeechState();
  }

  Future<void> stop() async {
    _generation++;
    try {
      await ref.read(deviceAccessServiceProvider).stopSpeaking();
    } catch (_) {/* recognition still works */}
    if (ref.mounted) state = const SpeechState();
  }

  Future<void> toggle(String text) async {
    final service = ref.read(deviceAccessServiceProvider);
    final generation = ++_generation;
    // Đang đọc câu khác thì chuyển sang đọc câu này thay vì chỉ dừng.
    if (state.speaking && (state.text == null || state.text == text)) {
      await service.stopSpeaking();
      if (ref.mounted && generation == _generation) state = const SpeechState();
      return;
    }
    await read(text);
  }

  Future<void> read(String text) async {
    final service = ref.read(deviceAccessServiceProvider);
    final generation = ++_generation;
    if (state.speaking) await service.stopSpeaking();
    if (!ref.mounted || generation != _generation) return;
    state = SpeechState(speaking: true, text: text);
    try {
      // Android TTS limits each utterance to about 4000 characters.
      // Keep long schedules readable and allow Stop between chunks.
      var remaining = text;
      while (remaining.isNotEmpty) {
        var end = remaining.length > 3500 ? 3500 : remaining.length;
        if (end < remaining.length) {
          final space = remaining.lastIndexOf(' ', end);
          if (space > 0) end = space;
        }
        await service.speak(remaining.substring(0, end));
        if (!ref.mounted || generation != _generation) return;
        remaining = remaining.substring(end).trimLeft();
      }
      if (ref.mounted && generation == _generation) state = const SpeechState();
    } catch (e) {
      if (ref.mounted && generation == _generation) {
        state = SpeechState(error: deviceError(e));
      }
    }
  }
}

final speechViewModelProvider =
    NotifierProvider.autoDispose<SpeechViewModel, SpeechState>(
        SpeechViewModel.new);

class ReminderSettingsState {
  const ReminderSettingsState(
      {this.allowed, this.busy = false, this.message, this.error});
  final bool? allowed;
  final bool busy;
  final String? message, error;
}

class ReminderSettingsViewModel extends Notifier<ReminderSettingsState> {
  @override
  ReminderSettingsState build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    Future.microtask(refresh);
    return const ReminderSettingsState();
  }

  Future<void> refresh() async {
    try {
      final allowed = await ref.read(reminderServiceProvider).hasPermission();
      if (ref.mounted) state = ReminderSettingsState(allowed: allowed);
    } catch (e) {
      if (ref.mounted) state = ReminderSettingsState(error: deviceError(e));
    }
  }

  Future<void> act(String action) async {
    if (state.busy) return;
    final allowed = state.allowed;
    state = ReminderSettingsState(allowed: allowed, busy: true);
    try {
      final service = ref.read(reminderServiceProvider);
      String? message;
      if (action == 'request') {
        final granted = await service.requestPermission();
        message = granted
            ? 'Đã cho phép nhắc việc.'
            : 'Chưa được cấp quyền. Bác có thể mở cài đặt điện thoại để bật lại.';
      } else if (action == 'test') {
        await service.showTest();
        message = 'Đã gửi lời nhắc thử. Bác xem thanh thông báo nhé.';
      } else {
        await ref.read(deviceAccessServiceProvider).openNotificationSettings();
      }
      final permission = await service.hasPermission();
      if (ref.mounted) {
        state = ReminderSettingsState(allowed: permission, message: message);
      }
    } catch (e) {
      if (ref.mounted) {
        state = ReminderSettingsState(allowed: allowed, error: deviceError(e));
      }
    }
  }
}

final reminderSettingsViewModelProvider = NotifierProvider.autoDispose<
    ReminderSettingsViewModel,
    ReminderSettingsState>(ReminderSettingsViewModel.new);
