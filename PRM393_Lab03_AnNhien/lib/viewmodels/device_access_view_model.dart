import 'dart:async';

import 'package:clock/clock.dart';
import '../models/task_item.dart';
import '../models/voice_task_draft.dart';
import '../services/profile_setup_service.dart';
import '../services/remote_config_service.dart';
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
      this.adding = false});
  final String text, followUp;
  final bool busy, interpreting, adding;
  final String? error;
  final List<String> utterances;
  final VoiceTaskInterpretation? interpretation;

  /// Câu báo trùng giờ với việc đã có (chỉ hiện trên máy, không gửi đi).
  final String? conflict;

  /// [error] và [conflict] không giữ lại khi không truyền (giống [error] cũ).
  VoiceDraft copyWith(
          {String? text,
          String? followUp,
          bool? busy,
          bool? interpreting,
          bool? adding,
          String? error,
          List<String>? utterances,
          VoiceTaskInterpretation? interpretation,
          String? conflict}) =>
      VoiceDraft(
          text: text ?? this.text,
          followUp: followUp ?? this.followUp,
          busy: busy ?? this.busy,
          interpreting: interpreting ?? this.interpreting,
          adding: adding ?? this.adding,
          error: error,
          utterances: utterances ?? this.utterances,
          interpretation: interpretation ?? this.interpretation,
          conflict: conflict);
}

/// Thời lượng mặc định của việc thêm bằng giọng nói (giống form F4).
const voiceTaskDurationMinutes = 15;

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
  try {
    tasks = await ref
        .read(taskRepositoryProvider)
        .tasksForDay(day)
        .timeout(const Duration(seconds: 5));
  } catch (_) {/* lịch chưa tải được */}
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
            .toList(growable: false)),
    tasks
  );
}

/// Việc đã có trùng khung giờ với bản nháp, hoặc `null`.
TaskItem? findConflict(VoiceTaskDraft draft, List<TaskItem> sameDay,
    {int durationMinutes = voiceTaskDurationMinutes}) {
  if (draft.hour == null || draft.minute == null) return null;
  final start = draft.hour! * 60 + draft.minute!, end = start + durationMinutes;
  for (final t in sameDay) {
    if (t.status == TaskStatus.skipped) continue;
    final s = t.hour * 60 + t.minute, e = s + t.durationMinutes;
    if (start < e && s < end) return t;
  }
  return null;
}

String conflictMessage(TaskItem task) {
  final time = '${task.hour.toString().padLeft(2, '0')}:'
      '${task.minute.toString().padLeft(2, '0')}';
  return 'Lúc $time Bác đã có việc “${task.title}”. '
      'Bác vẫn thêm được, hoặc nói giờ khác nhé.';
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

  Future<void> analyze() async {
    if (state.busy || state.text.trim().isEmpty) return;
    if (!ref.read(voiceInputEnabledProvider)) {
      state = state.copyWith(
          error: 'Hiểu lời nói đang tạm tắt. Bác có thể nhập tay.');
      return;
    }
    final uid = ref.read(sessionProvider).value?.uid;
    if (uid == null) {
      state =
          state.copyWith(error: 'Bác đăng nhập lại để dùng hiểu lời nói nhé.');
      return;
    }
    final clarification = state.interpretation?.question != null;
    if (clarification && state.followUp.trim().isEmpty) {
      state = state.copyWith(error: 'Bác trả lời câu hỏi bên trên nhé.');
      return;
    }
    final turns = clarification
        ? [...state.utterances, state.followUp.trim()]
        : [state.text.trim()];
    if (turns.length > 4 || turns.any((s) => s.length > 500)) {
      state = state.copyWith(
          error:
              'Bác sửa câu nói ban đầu, gộp tên việc, ngày và giờ trong một câu ngắn nhé.');
      return;
    }
    final before = state, generation = ++_generation;
    state = state.copyWith(busy: true, interpreting: true);
    try {
      await ref.read(speechViewModelProvider.notifier).stop();
      if (!_active(generation, uid)) return;
      final contextDate = ref.read(taskFormViewModelProvider).date;
      final (userContext, _) =
          await loadVoiceContext(ref, uid, contextDate ?? clock.now());
      if (!_active(generation, uid)) return;
      final result = await ref
          .read(voiceTaskServiceProvider)
          .interpret(turns, contextDate: contextDate, userContext: userContext);
      if (!_active(generation, uid)) return;
      String? conflict;
      if (result.ready) {
        final (_, sameDay) =
            await loadVoiceContext(ref, uid, result.draft.date!);
        if (!_active(generation, uid)) return;
        final hit = findConflict(result.draft, sameDay);
        if (hit != null) conflict = conflictMessage(hit);
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
          .read(result.question ?? result.draft.reviewText);
    } catch (e) {
      if (_active(generation, uid)) {
        state = before.copyWith(
            busy: false, interpreting: false, error: deviceError(e));
      }
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
      // Bắt đầu lượt mới để Bác nói tiếp việc khác.
      if (_active(generation, uid)) state = const VoiceDraft();
      return task;
    } catch (_) {
      if (_active(generation, uid)) {
        state = before.copyWith(
            conflict: before.conflict,
            error: 'Chưa thêm được vào lịch. Bác thử lại hoặc nhập tay nhé.');
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
    final task = draft.toTask(clock.now().microsecondsSinceEpoch.toString(),
        durationMinutes: voiceTaskDurationMinutes);
    final analytics = _ref.read(analyticsServiceProvider);
    try {
      task.validate();
      await _ref.read(taskRepositoryProvider).save(task);
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
  const SpeechState({this.speaking = false, this.error});
  final bool speaking;
  final String? error;
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
    if (state.speaking) {
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
    state = const SpeechState(speaking: true);
    try {
      await service.speak(text);
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
