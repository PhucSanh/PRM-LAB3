import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/assistant_service.dart';
import '../services/assistant_contact_filter.dart';
import '../models/task_item.dart';
import '../models/relative.dart';
import '../models/user_profile.dart';
import '../utils/app_error.dart';
import 'account_view_model.dart';
import 'caregiver_schedule_view_model.dart';
import '../services/providers.dart';
import 'device_access_view_model.dart';
import 'session_view_model.dart';

class AssistantMessage {
  const AssistantMessage(this.text, {this.fromUser = false});
  final String text;
  final bool fromUser;
}

class AssistantState {
  const AssistantState(
      {this.messages = const [],
      this.busy = false,
      this.listening = false,
      this.error,
      this.action,
      this.target = '',
      this.onDevice = false,
      this.day,
      this.tasks = const [],
      this.contacts = const []});
  final List<AssistantMessage> messages;
  final bool busy, listening;
  final String? error;
  final AssistantAction? action;
  final String target;
  final bool onDevice;
  final DateTime? day;
  final List<TaskItem> tasks;
  final List<Relative> contacts;
}

class AssistantViewModel extends Notifier<AssistantState> {
  int _generation = 0;
  @override
  AssistantState build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    ref.watch(
        profileProvider.select((p) => (p.value?.role, p.value?.pairedMomUid)));
    _generation++;
    ref.onDispose(() {
      _generation++;
    });
    return const AssistantState();
  }

  Future<void> listen() async {
    if (state.busy) return;
    final generation = _generation;
    state =
        AssistantState(messages: state.messages, busy: true, listening: true);
    try {
      await ref.read(speechViewModelProvider.notifier).stop();
      final text = await ref.read(deviceAccessServiceProvider).recognize();
      if (!ref.mounted || generation != _generation) return;
      state = AssistantState(messages: state.messages);
      if (text != null && text.trim().isNotEmpty) await send(text);
    } catch (e) {
      if (ref.mounted && generation == _generation) {
        state = AssistantState(messages: state.messages, error: deviceError(e));
      }
    }
  }

  Future<void> send(String text) async {
    text = text.trim();
    if (state.busy || text.isEmpty) return;
    if (text.length > 500) {
      state = AssistantState(
          messages: state.messages,
          error: 'Bác nói ngắn hơn, tối đa 500 ký tự nhé.');
      return;
    }
    final generation = ++_generation;
    final messages = [
      ...state.messages,
      AssistantMessage(text, fromUser: true)
    ];
    state = AssistantState(messages: messages, busy: true);
    try {
      await ref.read(speechViewModelProvider.notifier).stop();
      final history = messages
          .skip(messages.length > 10 ? messages.length - 10 : 0)
          .map((m) => {
                'role': m.fromUser ? 'user' : 'assistant',
                'content':
                    m.text.length > 2000 ? m.text.substring(0, 2000) : m.text
              })
          .toList();
      final reply = await ref.read(assistantServiceProvider).reply(history);
      if (!ref.mounted || generation != _generation) return;
      var answer = reply.text;
      final caregiver =
          ref.read(profileProvider).value?.role == UserRole.caregiver;
      final day = reply.day ?? (caregiver ? vietnamToday() : clock.now());
      var tasks = <TaskItem>[];
      var contacts = <Relative>[];
      if ([
        AssistantAction.schedule,
        AssistantAction.editTask,
        AssistantAction.deleteTask
      ].contains(reply.action)) {
        if (caregiver) {
          final mom = ref.read(pairedMomUidProvider);
          if (mom == null) {
            throw const AppException(
                'Cần ghép nối với máy của cha/mẹ để xem lịch.');
          }
          final date = DateTime(day.year, day.month, day.day);
          tasks = (await ref
                  .read(caregiverScheduleServiceProvider)
                  .watch(mom, date, date)
                  .first)
              .map((o) => o.task)
              .toList();
        } else {
          tasks = [...await ref.read(taskRepositoryProvider).tasksForDay(day)];
        }
        if (!ref.mounted || generation != _generation) return;
        tasks.sort((a, b) =>
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        if (reply.action == AssistantAction.schedule) {
          answer = tasks.isEmpty
              ? 'Ngày này Bác chưa có việc trong lịch.'
              : 'Lịch ngày ${day.day}/${day.month} của Bác: ${tasks.map((t) => '${t.hour} giờ ${t.minute} phút, ${t.title}${t.isDone ? ', đã xong' : ''}').join('. ')}.';
        }
      }
      if (reply.action == AssistantAction.callFamily) {
        final all = await ref.read(familyRepositoryProvider).all();
        contacts =
            filterAssistantContacts(all, utterance: text, target: reply.target);
        if (contacts.isEmpty) {
          answer = all.isEmpty
              ? 'Chưa có người thân trong danh bạ An Nhiên.'
              : 'Chưa tìm thấy người thân phù hợp. Bác kiểm tra tên và mối quan hệ trong danh bạ nhé.';
        }
      }
      if (!ref.mounted || generation != _generation) return;
      state = AssistantState(
          messages: [...messages, AssistantMessage(answer)],
          action: reply.action,
          target: reply.target,
          onDevice: reply.onDevice,
          day: day,
          tasks: tasks,
          contacts: contacts);
      await ref.read(speechViewModelProvider.notifier).read(answer);
    } catch (e) {
      if (ref.mounted && generation == _generation) {
        state = AssistantState(messages: messages, error: deviceError(e));
      }
    }
  }

  void dismissAction() {
    state = AssistantState(
        messages: state.messages,
        busy: state.busy,
        listening: state.listening,
        error: state.error,
        onDevice: state.onDevice);
  }

  void cancel() {
    _generation++;
    state = AssistantState(messages: state.messages);
    ref.read(speechViewModelProvider.notifier).stop();
  }
}

final assistantViewModelProvider =
    NotifierProvider<AssistantViewModel, AssistantState>(
        AssistantViewModel.new);

/// All floating assistant buttons open the same intent-aware conversation.
class AssistantLauncher extends Notifier<int> {
  @override
  int build() => 0;
  void open() => state++;
}

final assistantLauncherProvider =
    NotifierProvider<AssistantLauncher, int>(AssistantLauncher.new);
