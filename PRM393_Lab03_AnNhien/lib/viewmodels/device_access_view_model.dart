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
  const VoiceDraft({this.text = '', this.busy = false, this.error});
  final String text;
  final bool busy;
  final String? error;
}

class VoiceInputViewModel extends Notifier<VoiceDraft> {
  @override
  VoiceDraft build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    return const VoiceDraft();
  }

  void edit(String text) => state = VoiceDraft(text: text);
  Future<void> listen() async {
    if (state.busy) return;
    if (!ref.read(voiceInputEnabledProvider)) {
      state = VoiceDraft(
          text: state.text,
          error: 'Nhập giọng nói đang tạm tắt. Bác có thể gõ tên việc.');
      return;
    }
    final uid = ref.read(sessionProvider).value?.uid;
    final before = state.text;
    state = VoiceDraft(text: before, busy: true);
    try {
      final text = await ref.read(deviceAccessServiceProvider).recognize();
      if (!ref.mounted || uid != ref.read(sessionProvider).value?.uid) return;
      state = VoiceDraft(
          text: text?.trim().isNotEmpty == true ? text!.trim() : before);
    } catch (e) {
      if (ref.mounted) state = VoiceDraft(text: before, error: deviceError(e));
    }
  }

  bool confirm() {
    if (state.busy || state.text.trim().isEmpty) return false;
    final form = ref.read(taskFormViewModelProvider.notifier);
    if (ref.read(taskFormViewModelProvider).date == null) form.startCreate();
    form.setTitle(state.text.trim());
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

  Future<void> toggle(String text) async {
    final service = ref.read(deviceAccessServiceProvider);
    final generation = ++_generation;
    if (state.speaking) {
      await service.stopSpeaking();
      if (ref.mounted && generation == _generation) state = const SpeechState();
      return;
    }
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
