import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

class ReminderSettingsData {
  const ReminderSettingsData(this.settings, this.notificationsEnabled);
  final AppSettings settings;
  final bool notificationsEnabled;
}

/// F6 N07 – chỉ dùng SettingsService/ReminderService đã có, không tạo schema mới.
class ReminderSettingsViewModel extends Notifier<UiState<ReminderSettingsData>> {
  StreamSubscription<AppSettings>? _subscription;

  @override
  UiState<ReminderSettingsData> build() {
    Future.microtask(load);
    ref.onDispose(() => _subscription?.cancel());
    return const UiLoading();
  }

  Future<void> load() async {
    await _subscription?.cancel();
    state = const UiLoading();
    try {
      final notification = await ref.read(reminderServiceProvider).hasPermission();
      _subscription = ref.read(settingsServiceProvider).watch().listen(
        (settings) => state = UiData(ReminderSettingsData(settings, notification)),
        onError: (Object error, StackTrace stack) => _fail(error, stack),
      );
    } catch (error, stack) {
      await _fail(error, stack);
    }
  }

  Future<String?> setVibrate(bool value) => _save(
      (service) => service.setVibrate(value), 'save_reminder_vibrate');
  Future<String?> setReadAloud(bool value) => _save(
      (service) => service.setReadAloud(value), 'save_reminder_read_aloud');

  Future<String?> enableNotifications() async {
    try {
      final granted = await ref.read(reminderServiceProvider).requestPermission();
      if (!granted) return 'Máy chưa cho phép nhắc việc. Bác bật lại trong Cài đặt nhé.';
      await load();
      return null;
    } catch (error, stack) {
      await _record(error, stack, 'request_reminder_permission');
      return error is AppException ? error.userMessage : 'Chưa bật được nhắc việc.';
    }
  }

  Future<String?> _save(
      Future<void> Function(dynamic service) write, String reason) async {
    try {
      await write(ref.read(settingsServiceProvider));
      return null;
    } catch (error, stack) {
      await _record(error, stack, reason);
      return error is AppException ? error.userMessage : 'Chưa lưu được cài đặt. Bác thử lại nhé.';
    }
  }

  Future<void> _fail(Object error, StackTrace stack) async {
    state = UiError(error is AppException ? error.userMessage : 'Chưa tải được cài đặt.');
    await _record(error, stack, 'load_reminder_settings');
  }

  Future<void> _record(Object error, StackTrace stack, String reason) async {
    try {
      await ref.read(crashServiceProvider).recordError(error, stack, reason: reason);
    } catch (_) {}
  }
}

final reminderSettingsViewModelProvider = NotifierProvider<
    ReminderSettingsViewModel, UiState<ReminderSettingsData>>(
  ReminderSettingsViewModel.new,
);
