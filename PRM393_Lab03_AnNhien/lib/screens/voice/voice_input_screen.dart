import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/device_access_view_model.dart';
import '../../widgets/app_back_bar.dart';
import '../calm/calendar_screen.dart' show calendarDayRoute;
import '../../widgets/assistant_bubble.dart';
import '../../viewmodels/daily_actions_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/undo_snackbar.dart';
import '../../widgets/voice_task_review.dart';
import '../../theme/app_spacing.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});
  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  final controller = TextEditingController();
  final followUp = TextEditingController();
  final _resultAnchor = GlobalKey();
  @override
  void dispose() {
    controller.dispose();
    followUp.dispose();
    super.dispose();
  }

  void _sync(TextEditingController target, String text) {
    if (target.text != text) {
      target.value = TextEditingValue(
          text: text, selection: TextSelection.collapsed(offset: text.length));
    }
  }

  Future<void> _analyze() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final change =
        await ref.read(voiceInputViewModelProvider.notifier).analyze();
    if (change == null || !mounted) return;
    final actions = ref.read(dailyActionsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    showUndoSnackbar(context, title: 'Đã đánh dấu xong: ${change.task.title}',
        onUndo: () async {
      try {
        await actions.undo(change);
      } catch (_) {
        if (messenger.mounted) {
          messenger.showSnackBar(const SnackBar(
              content: Text('Chưa hoàn tác được. Bác thử lại nhé.')));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputViewModelProvider);
    final vm = ref.read(voiceInputViewModelProvider.notifier);
    final enabled = ref.watch(voiceInputEnabledProvider);
    final result = state.interpretation;
    // Giữ bộ đọc to sống suốt màn: ViewModel tự đọc câu hỏi / đề xuất, nếu
    // không ai nghe thì provider autoDispose bị huỷ và cắt ngang giọng đọc.
    ref.listen(speechViewModelProvider, (_, __) {});
    ref.listen(voiceInputViewModelProvider, (previous, next) {
      _sync(controller, next.text);
      _sync(followUp, next.followUp);
      if (next.interpretation != previous?.interpretation &&
          next.interpretation != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final anchor = _resultAnchor.currentContext;
          if (mounted && anchor != null) {
            Scrollable.ensureVisible(anchor, alignment: 0);
          }
        });
      }
    });
    return Scaffold(
      appBar: AppBackBar.adaptive(context),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CalmPageHeader(
              title: result?.ready == true
                  ? 'Kiểm tra trước khi lưu'
                  : 'Lên lịch bằng giọng nói',
              subtitle: result?.ready == true
                  ? 'Cháu đã sắp xếp lời Bác thành lịch bên dưới. Đúng ý Bác chưa?'
                  : 'Bác nói điều muốn làm. Cháu giúp làm rõ rồi Bác quyết định lưu.',
              actions: false),
          const SizedBox(height: AppSpacing.lg),
          if (result?.ready != true) ...[
            AppTextField(
                label: 'Câu nói của Bác',
                controller: controller,
                maxLength: 500,
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                enabled: !state.busy,
                onChanged: vm.edit,
                hint: 'Mai 8 giờ sáng tưới cây trong 15 phút'),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: state.text.isEmpty ? 'Bắt đầu nói' : 'Nói lại từ đầu',
                icon: Icons.mic_rounded,
                kind: AppButtonKind.secondary,
                busy: state.busy && !state.interpreting,
                onPressed: enabled && !state.busy ? () => vm.listen() : null),
            const SizedBox(height: AppSpacing.md),
            if (!enabled)
              const FieldMessage.hint(
                  'Giọng nói đang tạm tắt. Bác có thể nhập lịch bằng tay.'),
            if (result == null)
              AppButton(
                  label: state.interpreting
                      ? 'Đang sắp xếp lịch…'
                      : 'Tạo lịch từ câu nói',
                  icon: Icons.auto_awesome_rounded,
                  busy: state.interpreting,
                  onPressed:
                      enabled && !state.busy && state.text.trim().isNotEmpty
                          ? _analyze
                          : null),
            const SizedBox(height: AppSpacing.sm),
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Thông tin được dùng để tạo lịch',
                    style: Theme.of(context).textTheme.bodySmall),
                children: const [
                  Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                          'Khi Bác chọn “Tạo lịch từ câu nói”, phần chữ và giờ bận trong 7 ngày tới được gửi tới Google Gemini để đề xuất lịch. Không gửi bản ghi âm hay tên các việc khác. Bác luôn kiểm tra trước khi lưu.'))
                ]),
          ],
          SizedBox(key: _resultAnchor, height: AppSpacing.base),
          if (state.reply != null) ...[
            if (state.addedDay != null)
              Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Đã thêm vào lịch',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                  'Bác có thể xem lịch hoặc nói thêm một việc khác.'),
                            ])),
                      ]))
            else
              AssistantReply(text: state.reply!),
            if (state.addedDay case final day?) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                  key: const Key('voice-open-day'),
                  label: 'Xem lịch ngày ${day.day}/${day.month}',
                  icon: Icons.calendar_month_rounded,
                  kind: AppButtonKind.secondary,
                  onPressed: () => context.go(calendarDayRoute(day))),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
          if (result?.question != null) ...[
            AssistantReply(text: result!.question!),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                label: 'Bác trả lời thêm',
                controller: followUp,
                maxLength: 500,
                minLines: 2,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                enabled: !state.busy,
                onChanged: vm.editFollowUp,
                hint: '8 giờ sáng ngày mai'),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Nói câu trả lời',
                icon: Icons.mic_rounded,
                kind: AppButtonKind.secondary,
                onPressed: enabled && !state.busy
                    ? () => vm.listen(followUp: true)
                    : null),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: state.interpreting
                    ? 'Đang sắp xếp lịch…'
                    : 'Gửi câu trả lời',
                icon: Icons.arrow_forward_rounded,
                busy: state.interpreting,
                onPressed:
                    enabled && !state.busy && state.followUp.trim().isNotEmpty
                        ? () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            vm.analyze();
                          }
                        : null),
          ],
          if (result?.ready == true) ...[
            VoiceTaskReview(draft: result!.draft),
            if (result.onDevice) ...[
              const SizedBox(height: AppSpacing.md),
              const FieldMessage.hint(
                  'Cháu đang hiểu lời Bác ngay trên điện thoại. Bác xem kỹ ngày, giờ nhé.'),
            ],
            if (state.conflict != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                  liveRegion: true, child: FieldMessage.error(state.conflict!)),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: state.adding
                    ? 'Đang thêm vào lịch…'
                    : 'Đúng rồi, thêm vào lịch',
                icon: Icons.check_rounded,
                busy: state.adding,
                onPressed: state.busy || state.conflict != null
                    ? null
                    : () async {
                        final draft = result.draft;
                        final writer = ref.read(voiceTaskWriterProvider);
                        final task = await vm.addToSchedule();
                        if (task == null || !context.mounted) return;
                        ref
                            .read(speechViewModelProvider.notifier)
                            .read('Đã thêm ${task.title} vào lịch của Bác.');
                        showUndoSnackbar(context,
                            title: 'Đã thêm: ${task.title}',
                            subtitle: '${draft.dateLabel} · ${draft.timeLabel}',
                            onUndo: () => writer.undo(task));
                      }),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Chưa đúng, nói lại',
                icon: Icons.mic_rounded,
                kind: AppButtonKind.secondary,
                onPressed: state.busy ? null : () => vm.listen()),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Xem và sửa trước khi lưu',
                icon: Icons.edit_rounded,
                kind: AppButtonKind.secondary,
                onPressed: state.busy
                    ? null
                    : () {
                        if (vm.confirmInterpretation()) {
                          context.go('/today/add/time');
                        }
                      }),
          ],
          if (result?.ready == true) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Câu nói của Bác',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
                state.utterances.isEmpty
                    ? state.text
                    : state.utterances.join('\n'),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            FieldMessage.error(state.error!),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
              label: 'Nhập lịch bằng tay',
              icon: Icons.edit_calendar_rounded,
              kind: AppButtonKind.secondary,
              onPressed: state.busy
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (vm.confirm()) context.go('/today/add/time');
                    }),
          const SizedBox(height: AppSpacing.base),
          const Text(
              'Chỉ lưu lịch sau khi Bác xác nhận. Bác có thể nói lại hoặc sửa thông tin trước khi lưu.'),
        ]),
      )),
    );
  }
}
