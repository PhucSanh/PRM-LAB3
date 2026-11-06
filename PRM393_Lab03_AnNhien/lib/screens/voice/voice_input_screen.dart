import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/device_access_view_model.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/read_aloud_control.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputViewModelProvider);
    final vm = ref.read(voiceInputViewModelProvider.notifier);
    final enabled = ref.watch(voiceInputEnabledProvider);
    final result = state.interpretation;
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
                  'Bác nói tên việc, ngày và giờ. Cháu sẽ đọc lại để Bác kiểm tra.',
              art: true,
              actions: false),
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
              hint: 'Mai lúc 8 giờ sáng nhắc bác tưới cây, mỗi ngày'),
          const SizedBox(height: AppSpacing.base),
          if (!enabled)
            const FieldMessage.hint(
                'Nhập giọng nói đang tạm tắt. Bác có thể gõ tên việc và nhập lịch bằng tay.'),
          const Text(
              'Khi Bác bấm “Hiểu lời Bác nói”, phần chữ sẽ được gửi tới Groq để hiểu ngày, giờ. Bản ghi âm không được gửi tới Groq bởi ứng dụng.'),
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
                        ? () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            vm.analyze();
                          }
                        : null),
          SizedBox(key: _resultAnchor, height: AppSpacing.base),
          if (result?.question != null) ...[
            Semantics(
                liveRegion: true,
                child: Text(result!.question!,
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: AppSpacing.md),
            ReadAloudControl(text: result.question!),
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
            const SizedBox(height: AppSpacing.md),
            ReadAloudControl(text: result.draft.reviewText),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Dùng lịch này',
                icon: Icons.check_rounded,
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
              'Chưa có việc nào được lưu. Bác sẽ kiểm tra ngày, giờ và bấm Lưu ở bước tiếp theo.'),
        ]),
      )),
    );
  }
}
