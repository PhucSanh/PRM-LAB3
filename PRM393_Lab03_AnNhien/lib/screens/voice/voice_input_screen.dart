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
import '../../theme/app_spacing.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});
  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputViewModelProvider);
    final vm = ref.read(voiceInputViewModelProvider.notifier);
    ref.listen(voiceInputViewModelProvider, (_, next) {
      if (controller.text != next.text) {
        controller.value = TextEditingValue(
            text: next.text,
            selection: TextSelection.collapsed(offset: next.text.length));
      }
    });
    return Scaffold(
        appBar: AppBackBar.adaptive(context),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              const CalmPageHeader(
                  title: 'Nói để thêm việc',
                  subtitle:
                      'Bác nói tên việc, rồi kiểm tra lại trước khi đặt giờ.',
                  art: true,
                  actions: false),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                  label: state.text.isEmpty ? 'Bắt đầu nói' : 'Nói lại',
                  icon: Icons.mic_rounded,
                  busy: state.busy,
                  onPressed:
                      ref.watch(voiceInputEnabledProvider) ? vm.listen : null),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                  label: 'Tên việc Bác muốn làm',
                  controller: controller,
                  onChanged: vm.edit),
              if (state.error != null) FieldMessage.error(state.error!),
              const SizedBox(height: AppSpacing.base),
              if (state.text.trim().isNotEmpty)
                ReadAloudControl(text: state.text),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                  label: 'Dùng tên việc này',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: state.busy || state.text.trim().isEmpty
                      ? null
                      : () {
                          if (vm.confirm()) context.go('/today/add/time');
                        }),
              const SizedBox(height: AppSpacing.base),
              const Text(
                  'Chưa có việc nào được lưu. Bác sẽ chọn ngày, giờ và bấm Lưu ở bước tiếp theo.'),
            ])));
  }
}
