import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../services/remote_config_service.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

class FirebaseDemoData {
  const FirebaseDemoData(this.snooze, this.voice, this.upcoming,
      {this.busy = false, this.message, this.url, this.progress});
  final int snooze, upcoming;
  final bool voice, busy;
  final String? message, url;
  final double? progress;
  FirebaseDemoData action(
          {bool busy = false,
          String? message,
          String? url,
          double? progress}) =>
      FirebaseDemoData(snooze, voice, upcoming,
          busy: busy, message: message, url: url, progress: progress);
}

final firebaseDemoViewModelProvider = NotifierProvider.autoDispose<
    FirebaseDemoViewModel,
    UiState<FirebaseDemoData>>(FirebaseDemoViewModel.new);

class FirebaseDemoViewModel extends Notifier<UiState<FirebaseDemoData>> {
  @override
  UiState<FirebaseDemoData> build() {
    final config = ref.watch(remoteConfigServiceProvider);
    final sub = config.onUpdated.listen((_) {
      if (ref.mounted) _read();
    }, onError: (Object _) {});
    ref.onDispose(sub.cancel);
    Future.microtask(() async {
      if (!ref.mounted) return;
      await _event('view_firebase_demo');
      if (ref.mounted) await refresh();
    });
    return const UiLoading();
  }

  void _read() {
    final config = ref.read(remoteConfigServiceProvider);
    final current = state;
    final previous = current is UiData<FirebaseDemoData> ? current.data : null;
    state = UiData(FirebaseDemoData(
        config.getInt(RemoteConfigKeys.snoozeMinutes),
        config.getBool(RemoteConfigKeys.voiceInputEnabled),
        config.getInt(RemoteConfigKeys.homeMaxUpcoming),
        busy: previous?.busy ?? false,
        message: previous?.message,
        url: previous?.url,
        progress: previous?.progress));
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      await ref.read(remoteConfigServiceProvider).init();
      if (!ref.mounted) return;
      _read();
      await _event('refresh_remote_config');
    } catch (_) {
      if (ref.mounted) {
        state = const UiError('Chưa tải được cài đặt. Bác thử lại nhé.');
      }
    }
  }

  Future<void> _event(String name, [Map<String, Object>? params]) async {
    try {
      await ref.read(analyticsServiceProvider).logEvent(name, params);
    } catch (_) {}
  }

  Future<void> export() async {
    final current = state;
    if (current is! UiData<FirebaseDemoData> || current.data.busy) return;
    final data = current.data;
    final crash = ref.read(crashServiceProvider);
    final service = ref.read(demoReportServiceProvider);
    state = UiData(data.action(busy: true, progress: 0));
    try {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      await for (final progress in service
          .exportWeek(day.subtract(Duration(days: day.weekday - 1)))) {
        if (!ref.mounted) return;
        state = UiData(data.action(
            busy: progress.downloadUrl == null,
            progress: progress.fraction,
            url: progress.downloadUrl,
            message: progress.downloadUrl == null
                ? 'Đang tải tệp lên…'
                : 'Đã tải tệp lên.'));
        if (progress.downloadUrl != null) {
          await _event('upload_demo_file', {'source': 'firebase_demo'});
        }
      }
      if (ref.mounted && state is UiData<FirebaseDemoData>) {
        final last = (state as UiData<FirebaseDemoData>).data;
        if (last.busy) {
          throw const AppException('Chưa nhận được đường dẫn tệp.');
        }
      }
    } catch (error, stack) {
      try {
        await crash.setCustomKey('feature', 'F10');
        await crash.setCustomKey('operation', 'upload_demo_file');
        await crash.recordError(error, stack, reason: 'firebase_demo_export');
      } catch (_) {}
      if (ref.mounted) {
        state = UiData(data.action(
            message: error is AppException
                ? error.userMessage
                : 'Chưa tải được tệp. Bác thử lại nhé.'));
      }
      if (ref.mounted) {
        await _event('upload_demo_failed', {'source': 'firebase_demo'});
      }
    }
  }

  Future<void> testCrash() async {
    final crash = ref.read(crashServiceProvider);
    await _event('test_crash', {'source': 'firebase_demo'});
    if (!ref.mounted) return;
    await crash.setCustomKey('feature', 'F10');
    if (ref.mounted) crash.testCrash();
  }
}
