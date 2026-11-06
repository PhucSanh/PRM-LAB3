import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../router/app_router.dart';
import '../services/assistant_service.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/assistant_view_model.dart';
import '../viewmodels/device_access_view_model.dart';
import '../viewmodels/family_actions_view_model.dart';
import 'app_button.dart';
import 'assistant_mascot.dart';
import 'form_parts.dart';
import 'voice_task_review.dart';
import 'undo_snackbar.dart';

/// Above the router, so support stays available on every route and dialog.
class GlobalAssistance extends ConsumerStatefulWidget {
  const GlobalAssistance({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<GlobalAssistance> createState() => _GlobalAssistanceState();
}

class _GlobalAssistanceState extends ConsumerState<GlobalAssistance> {
  final _screenKey = GlobalKey();
  bool _open = false;
  bool _addingTask = false;
  String _initialTask = '';
  Offset? _petPosition;
  ChildBackButtonDispatcher? _backDispatcher;
  late final _router = ref.read(routerProvider);

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_routeChanged);
    _backDispatcher = ref
        .read(routerProvider)
        .backButtonDispatcher
        .createChildBackButtonDispatcher();
    _backDispatcher!.addCallback(_handleBack);
  }

  void _routeChanged() {
    if (mounted) ref.read(speechViewModelProvider.notifier).stop();
  }

  Future<bool> _handleBack() async {
    if (!_open) return false;
    _close();
    return true;
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_routeChanged);
    _backDispatcher?.removeCallback(_handleBack);
    super.dispose();
  }

  String _screenText() {
    final root = _screenKey.currentContext as Element?;
    final box = root?.findRenderObject();
    if (root == null || box is! RenderBox || !box.hasSize) return '';
    final viewport = box.localToGlobal(Offset.zero) & box.size;
    final parts = <String>[];
    void visit(Element element) {
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) return;
      if (widget is Visibility && !widget.visible) return;
      final render = element.findRenderObject();
      if (render is RenderBox &&
          render.attached &&
          render.hasSize &&
          (render.localToGlobal(Offset.zero) & render.size)
              .overlaps(viewport)) {
        final text = widget is Text
            ? widget.data ?? widget.textSpan?.toPlainText()
            : widget is EditableText && !widget.obscureText
                ? widget.controller.text
                : null;
        if (text != null && text.trim().isNotEmpty) parts.add(text.trim());
      }
      element.visitChildren(visit);
    }

    root.visitChildren(visit);
    return parts.join('. ');
  }

  void _readScreen({bool restart = false}) {
    final text = _screenText();
    final vm = ref.read(speechViewModelProvider.notifier);
    final content =
        text.isEmpty ? 'Màn hình hiện chưa có nội dung để đọc.' : text;
    if (restart) {
      vm.read(content);
    } else {
      vm.toggle(content);
    }
  }

  void _close() {
    ref.read(assistantViewModelProvider.notifier).cancel();
    setState(() {
      _open = false;
      _addingTask = false;
    });
  }

  void _navigate(String path) {
    _close();
    ref.read(routerProvider).push(path);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(speechViewModelProvider);
    final colors = Theme.of(context).colorScheme;
    ref.listen(assistantViewModelProvider, (before, next) {
      if (!_open || next.action == null || before?.action == next.action) {
        return;
      }
      if (next.action == AssistantAction.readScreen) {
        ref.read(assistantViewModelProvider.notifier).dismissAction();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _readScreen(restart: true);
        });
      }
    });
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: LayoutBuilder(builder: (context, box) {
              const size = AppSizes.assistanceTarget;
              final maxX = (box.maxWidth - size).clamp(0.0, double.infinity);
              final maxY =
                  (box.maxHeight - size - MediaQuery.paddingOf(context).bottom)
                      .clamp(0.0, double.infinity);
              final point = _petPosition ??
                  Offset(maxX - AppSpacing.base,
                      maxY - AppSizes.navBar - AppSpacing.base);
              final position =
                  Offset(point.dx.clamp(0.0, maxX), point.dy.clamp(0.0, maxY));
              return Stack(fit: StackFit.expand, children: [
                KeyedSubtree(key: _screenKey, child: widget.child),
                if (!_open)
                  Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: GestureDetector(
                          onPanUpdate: (details) => setState(() {
                                _petPosition = Offset(
                                    (position.dx + details.delta.dx)
                                        .clamp(0.0, maxX),
                                    (position.dy + details.delta.dy)
                                        .clamp(0.0, maxY));
                              }),
                          child: Semantics(
                              hint: 'Kéo để di chuyển trợ lý',
                              child: SizedBox.square(
                                  dimension: size,
                                  child: FloatingActionButton(
                                      backgroundColor: colors.primaryContainer,
                                      foregroundColor: colors.primary,
                                      elevation: 0,
                                      highlightElevation: 0,
                                      shape: CircleBorder(
                                          side: BorderSide(
                                              color: colors.outlineVariant)),
                                      heroTag: 'global-assistant-pet',
                                      tooltip: 'Nói chuyện với trợ lý An Nhiên',
                                      onPressed: () {
                                        setState(() => _open = true);
                                        _backDispatcher?.takePriority();
                                      },
                                      child: const AssistantMascot()))))),
                if (_open) ...[
                  ModalBarrier(
                      dismissible: true,
                      onDismiss: _close,
                      color: colors.scrim.withValues(alpha: .32)),
                  SafeArea(
                      child: Align(
                          alignment: Alignment.bottomRight,
                          child: FractionallySizedBox(
                              heightFactor: .94,
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 600),
                                  child: Material(
                                      color: colors.surface,
                                      borderRadius: AppRadius.dialogAll,
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(children: [
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                left: AppSpacing.screen),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Text(
                                                      _addingTask
                                                          ? 'Thêm lịch cùng cháu'
                                                          : 'Trợ lý An Nhiên',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium)),
                                              IconButton(
                                                  tooltip:
                                                      'Đóng trợ lý An Nhiên',
                                                  onPressed: _close,
                                                  icon: const Icon(
                                                      Icons.close_rounded)),
                                            ])),
                                        Expanded(
                                            child: _addingTask
                                                ? _AssistantTaskPanel(
                                                    initialText: _initialTask,
                                                    onBack: () => setState(() =>
                                                        _addingTask = false))
                                                : _ConversationPanel(
                                                    onNavigate: _navigate,
                                                    onRead: _readScreen,
                                                    onCreate: (text) =>
                                                        setState(() {
                                                          _initialTask = text;
                                                          _addingTask = true;
                                                        }))),
                                      ]))))))
                ],
              ]);
            })));
  }
}

class _ConversationPanel extends ConsumerStatefulWidget {
  const _ConversationPanel(
      {required this.onNavigate, required this.onRead, required this.onCreate});
  final ValueChanged<String> onNavigate, onCreate;
  final VoidCallback onRead;
  @override
  ConsumerState<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<_ConversationPanel> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  String? _callError;
  bool _calling = false;
  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().isEmpty) return;
    final text = _text.text;
    _text.clear();
    FocusScope.of(context).unfocus();
    ref.read(assistantViewModelProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantViewModelProvider);
    final vm = ref.read(assistantViewModelProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    ref.listen(assistantViewModelProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: AppButton(
              label: state.listening ? 'Đang nghe Bác…' : 'Nói với cháu',
              icon: Icons.mic_rounded,
              busy: state.busy,
              onPressed: state.busy ? null : vm.listen)),
      Expanded(
          child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
            if (state.onDevice || state.messages.isEmpty) ...[
              const Text(
                  'Cháu hỗ trợ các lệnh trong ứng dụng, chưa trò chuyện tự do.'),
              const SizedBox(height: AppSpacing.base),
            ],
            if (state.messages.isEmpty) ...[
              const Text('Cháu đây, Bác cần cháu giúp gì?'),
              const SizedBox(height: AppSpacing.base),
              const Text(
                  'Bác có thể hỏi lịch, thêm sửa xoá việc hoặc gọi người thân.'),
              const SizedBox(height: AppSpacing.base),
              const Text(
                  'Nhấn “Nói với cháu” để bắt đầu. Cháu chỉ nghe khi Bác nhấn nút.'),
            ],
            for (final message in state.messages)
              Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.base),
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: message.fromUser
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: AppRadius.cardAll),
                      child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.base),
                          child: Text(
                              '${message.fromUser ? 'Bác' : 'Cháu'}: ${message.text}')))),
            if (state.busy)
              Semantics(
                  liveRegion: true,
                  child: Text(state.listening
                      ? 'Cháu đang nghe Bác…'
                      : 'Cháu đang suy nghĩ…')),
            if (state.error != null) FieldMessage.error(state.error!),
            if (_callError != null) FieldMessage.error(_callError!),
            if (state.action == AssistantAction.createFamily)
              AppButton(
                  label: 'Thêm người thân',
                  icon: Icons.person_add_rounded,
                  onPressed: () => widget.onNavigate('/family/add')),
            if (state.action == AssistantAction.createTask)
              AppButton(
                  label: 'Kiểm tra lịch Bác vừa nói',
                  icon: Icons.event_note_rounded,
                  onPressed: () => widget.onCreate(
                      state.messages.lastWhere((m) => m.fromUser).text)),
            if (state.action == AssistantAction.schedule)
              AppButton(
                  label: 'Mở lịch',
                  icon: Icons.calendar_month_rounded,
                  onPressed: () => widget
                      .onNavigate('/calendar?date=${dateKey(state.day!)}')),
            if (state.action == AssistantAction.family)
              AppButton(
                  label: 'Mở gia đình',
                  icon: Icons.family_restroom_rounded,
                  onPressed: () => widget.onNavigate('/family')),
            if (state.action == AssistantAction.settings)
              AppButton(
                  label: 'Mở cài đặt',
                  icon: Icons.settings_rounded,
                  onPressed: () => widget.onNavigate('/settings')),
            if ([AssistantAction.editTask, AssistantAction.deleteTask]
                .contains(state.action)) ...[
              Text(
                  'Bác chọn việc cần ${state.action == AssistantAction.editTask ? 'sửa' : 'xoá'} ngày ${state.day!.day}/${state.day!.month}:'),
              if (state.tasks.isEmpty)
                const Text('Ngày này chưa có việc. Bác nói ngày khác nhé.'),
              for (final task in _prioritize(
                  state.tasks, (t) => t.title, state.target)) ...[
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label:
                        '${task.title} — ${task.hour}:${task.minute.toString().padLeft(2, '0')}',
                    icon: state.action == AssistantAction.editTask
                        ? Icons.edit_calendar_rounded
                        : Icons.delete_outline_rounded,
                    onPressed: () => widget.onNavigate(
                        '/today/task/${Uri.encodeComponent(task.id)}/edit?date=${dateKey(state.day!)}')),
              ],
              const SizedBox(height: AppSpacing.base),
              const Text(
                  'Cháu sẽ mở việc Bác chọn để Bác sửa hoặc bấm Xoá và chọn phạm vi trước khi xác nhận.'),
            ],
            if (state.action == AssistantAction.callFamily) ...[
              const Text(
                  'Bác chọn người muốn gọi. Điện thoại sẽ mở số để Bác bấm gọi.'),
              if (state.contacts.isEmpty)
                const Text('Chưa có người thân trong danh bạ An Nhiên.'),
              for (final person in _prioritize(state.contacts,
                  (p) => '${p.name} ${p.relation}', state.target)) ...[
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label: 'Gọi ${person.name} (${person.relation})',
                    icon: Icons.call_rounded,
                    onPressed: _calling
                        ? null
                        : () async {
                            setState(() {
                              _calling = true;
                              _callError = null;
                            });
                            try {
                              await ref
                                  .read(speechViewModelProvider.notifier)
                                  .stop();
                              await ref
                                  .read(familyActionsProvider.notifier)
                                  .call(person);
                            } catch (e) {
                              if (mounted) {
                                setState(() => _callError = deviceError(e));
                              }
                            } finally {
                              if (mounted) setState(() => _calling = false);
                            }
                          }),
              ],
            ],
            const SizedBox(height: AppSpacing.base),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              ActionChip(
                  avatar: const Icon(Icons.volume_up_rounded),
                  label: const Text('Đọc màn hình'),
                  onPressed: widget.onRead),
              ActionChip(
                  avatar: const Icon(Icons.add_rounded),
                  label: const Text('Thêm lịch'),
                  onPressed: () => widget.onCreate('')),
            ]),
            Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: _text,
                      enabled: !state.busy,
                      maxLength: 500,
                      decoration: InputDecoration(
                          labelText: 'Bác muốn nói gì?',
                          suffixIcon: IconButton(
                              tooltip: 'Gửi câu nói',
                              onPressed: state.busy ? null : _send,
                              icon: const Icon(Icons.send_rounded))),
                      onSubmitted: (_) => _send()),
                ])),
          ])),
    ]);
  }
}

List<T> _prioritize<T>(List<T> items, String Function(T) name, String target) {
  final result = [...items];
  if (target.isNotEmpty) {
    int score(T item) =>
        name(item).toLowerCase().contains(target.toLowerCase()) ? 0 : 1;
    result.sort((a, b) => score(a).compareTo(score(b)));
  }
  return result;
}

class _AssistantTaskPanel extends ConsumerStatefulWidget {
  const _AssistantTaskPanel({required this.initialText, required this.onBack});
  final String initialText;
  final VoidCallback onBack;
  @override
  ConsumerState<_AssistantTaskPanel> createState() =>
      _AssistantTaskPanelState();
}

class _AssistantTaskPanelState extends ConsumerState<_AssistantTaskPanel> {
  final _text = TextEditingController();
  @override
  void initState() {
    super.initState();
    _text.text = widget.initialText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(voiceInputViewModelProvider.notifier).edit(widget.initialText);
      if (widget.initialText.isNotEmpty) {
        ref.read(voiceInputViewModelProvider.notifier).analyze();
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputViewModelProvider);
    final vm = ref.read(voiceInputViewModelProvider.notifier);
    final question = state.interpretation?.question;
    final result = state.interpretation;
    ref.listen(voiceInputViewModelProvider, (before, next) {
      final text =
          next.interpretation?.question != null ? next.followUp : next.text;
      if (_text.text != text) _text.text = text;
    });
    return ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          const Text(
              'Bác nói tên việc, ngày và giờ. Cháu sẽ đọc lại để Bác kiểm tra.'),
          const SizedBox(height: AppSpacing.base),
          if (question != null) Text(question),
          TextField(
              controller: _text,
              enabled: !state.busy,
              maxLength: 500,
              decoration: InputDecoration(
                  labelText: question == null
                      ? 'Câu nói của Bác'
                      : 'Bác trả lời thêm'),
              onChanged: question == null ? vm.edit : vm.editFollowUp),
          AppButton(
              label: 'Nói với cháu',
              icon: Icons.mic_rounded,
              busy: state.busy,
              onPressed: state.busy
                  ? null
                  : () async {
                      await vm.listen(followUp: question != null);
                      if (!mounted) return;
                      final current = ref.read(voiceInputViewModelProvider);
                      if (current.error == null &&
                          (question == null ? current.text : current.followUp)
                              .trim()
                              .isNotEmpty) {
                        await vm.analyze();
                      }
                    }),
          const SizedBox(height: AppSpacing.base),
          AppButton(
              label: 'Hiểu lời Bác nói',
              icon: Icons.auto_awesome_rounded,
              onPressed: state.busy ? null : vm.analyze),
          if (state.error != null) FieldMessage.error(state.error!),
          if (result?.ready == true) ...[
            const SizedBox(height: AppSpacing.base),
            VoiceTaskReview(draft: result!.draft),
            if (result.onDevice)
              const FieldMessage.hint(
                  'Cháu đang hiểu lời Bác trên điện thoại. Bác kiểm tra kỹ ngày, giờ nhé.'),
            if (state.conflict != null) FieldMessage.hint(state.conflict!),
            const SizedBox(height: AppSpacing.base),
            AppButton(
                label: 'Xác nhận thêm vào lịch',
                icon: Icons.check_rounded,
                onPressed: state.busy
                    ? null
                    : () async {
                        final writer = ref.read(voiceTaskWriterProvider);
                        final task = await vm.addToSchedule();
                        if (task == null || !context.mounted) return;
                        showUndoSnackbar(context,
                            title: 'Đã thêm: ${task.title}',
                            onUndo: () => writer.undo(task));
                        ref
                            .read(speechViewModelProvider.notifier)
                            .read('Đã thêm ${task.title} vào lịch của Bác.');
                      }),
          ],
          const SizedBox(height: AppSpacing.base),
          AppButton(
              label: 'Về trò chuyện',
              icon: Icons.chat_bubble_outline_rounded,
              kind: AppButtonKind.secondary,
              onPressed: state.busy ? null : widget.onBack),
        ]);
  }
}
