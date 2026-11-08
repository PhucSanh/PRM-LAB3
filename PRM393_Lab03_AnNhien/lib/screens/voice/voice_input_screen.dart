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
import '../../widgets/voice_example_art.dart';
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
            Scrollable.ensureVisible(anchor, alignment: 0.05);
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
          const CalmPageHeader(
              title: 'Nói để thêm việc',
              subtitle:
                  'Bác nói tên việc, ngày, giờ và làm trong bao lâu. Bác cũng có thể nói “Tôi làm xong rồi” để cháu đánh dấu và báo việc tiếp theo.',
              actions: false),
          const SizedBox(height: AppSpacing.lg),
          const VoiceExampleArt(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
              label: state.text.isEmpty ? 'Bắt đầu nói' : 'Nói lại từ đầu',
              icon: Icons.mic_rounded,
              kind: AppButtonKind.secondary,
              busy: state.busy && !state.interpreting,
              onPressed: enabled && !state.busy ? () => vm.listen() : null),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
              label: 'Câu nói của Bác',
              controller: controller,
              maxLength: 500,
              enabled: !state.busy,
              onChanged: vm.edit,
              hint: 'Mai 8 giờ sáng tưới cây trong 15 phút, mỗi ngày'),
          const SizedBox(height: AppSpacing.base),
          if (!enabled)
            const FieldMessage.hint(
                'Nhập giọng nói đang tạm tắt. Bác có thể gõ tên việc và nhập lịch bằng tay.'),
          const Text(
              'Khi Bác bấm “Hiểu lời Bác nói”, phần chữ, giờ thức dậy và các giờ đã có việc trong 7 ngày tới (không kèm tên việc) được gửi tới Google Gemini để hiểu ý Bác. Bản ghi âm không được gửi đi.'),
          const SizedBox(height: AppSpacing.lg),
          if (result == null)
            AppButton(
                label: state.interpreting
                    ? 'Đang hiểu lời Bác…'
                    : 'Hiểu lời Bác nói',
                icon: Icons.auto_awesome_rounded,
                busy: state.interpreting,
                onPressed:
                    enabled && !state.busy && state.text.trim().isNotEmpty
                        ? _analyze
                        : null),
          SizedBox(key: _resultAnchor, height: AppSpacing.base),
          if (state.reply != null) ...[
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
                    ? 'Đang hiểu lời Bác…'
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
                label: state.adding ? 'Đang thêm vào lịch…' : 'Thêm vào lịch',
                icon: Icons.check_rounded,
                busy: state.adding,
                onPressed: state.busy || state.conflict != null
                    ? null
                    : () async {
                        final draft = result.draft;
                        final writer = ref.read(voiceTaskWriterProvider);
                        final task = await vm.addToSchedule();
                        if (task == null || !context.mounted) return;
                        showUndoSnackbar(context,
                            title: 'Đã thêm: ${task.title}',
                            subtitle:
                                'Ngày ${draft.dateLabel}, lúc ${draft.timeLabel}. Bác nói tiếp việc khác được.',
                            onUndo: () => writer.undo(task));
                      }),
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
              'Việc chỉ được lưu khi Bác bấm “Thêm vào lịch”, hoặc bấm Lưu ở bước nhập tay. Lưu xong vẫn có nút Hoàn tác.'),
        ]),
      )),
    );
  }
}
