import 'package:clock/clock.dart';
import '../models/voice_task_draft.dart';
import '../services/remote_config_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'session_view_model.dart';
import 'task_form_view_model.dart';

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
      this.interpretation});
  final String text, followUp;
  final bool busy, interpreting;
  final String? error;
  final List<String> utterances;
  final VoiceTaskInterpretation? interpretation;
  VoiceDraft copyWith(
          {String? text,
          String? followUp,
          bool? busy,
          bool? interpreting,
          String? error,
          List<String>? utterances,
          VoiceTaskInterpretation? interpretation}) =>
      VoiceDraft(
          text: text ?? this.text,
          followUp: followUp ?? this.followUp,
          busy: busy ?? this.busy,
          interpreting: interpreting ?? this.interpreting,
          error: error,
          utterances: utterances ?? this.utterances,
          interpretation: interpretation ?? this.interpretation);
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
      final result = await ref.read(voiceTaskServiceProvider).interpret(turns,
          contextDate: ref.read(taskFormViewModelProvider).date);
      if (!_active(generation, uid)) return;
      state = before.copyWith(
          busy: false,
          interpreting: false,
          interpretation: result,
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
}

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
