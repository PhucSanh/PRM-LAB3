import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/firebase_demo_entry.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';
import '../../widgets/time_field.dart';
import '../../widgets/undo_snackbar.dart';

/// N06 Thông tin của Bác – sửa hồ sơ (`/settings/profile`, Figma `38:187`) – F8, Sanh.
/// Cuối màn giữ lối vào khu demo Firebase của Hiếu (F10, `FirebaseDemoEntry`).
///
/// Vẽ `UiState<ProfileForm>`: Loading → `LoadingView`, Error → `ErrorView` +
/// "Thử lại", Data → form. Không có Empty: hồ sơ luôn có sau khi đăng nhập +
/// onboarding (thiếu cách gọi / giờ thức dậy thì dùng mặc định như S02).
///
/// "Lưu thông tin" → Snackbar Hoàn tác rồi về màn trước. Rời màn khi còn thay
/// đổi chưa lưu (Hủy, Quay lại, cử chỉ back) → hỏi lại kiểu N14.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Chỉ giữ chữ đang gõ; giá trị thật nằm ở ViewModel.
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileViewModelProvider);
    // ViewModel sống suốt app (để Hoàn tác chạy được sau khi rời màn):
    // mở lại màn thì nạp lại, bỏ form cũ.
    if (state is! UiLoading<ProfileForm>) {
      Future.microtask(ref.read(profileViewModelProvider.notifier).load);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _dirty => switch (ref.read(profileViewModelProvider)) {
        UiData(:final data) => data.dirty,
        _ => false,
      };

  void _close() => context.canPop() ? context.pop() : context.go('/settings');

  /// Hủy / Quay lại / back hệ thống: còn thay đổi chưa lưu thì hỏi trước.
  Future<void> _leave() async {
    if (!_dirty) {
      _close();
      return;
    }
    final discard = await showConfirmDialog<bool>(
      context,
      icon: AppIcons.alert,
      title: 'Bác chưa lưu thay đổi',
      message: 'Nếu rời đi bây giờ, những gì Bác vừa sửa sẽ mất.',
      options: const [
        ConfirmOption(
          label: 'Ở lại sửa',
          icon: AppIcons.pencil,
          value: false,
          kind: AppButtonKind.primary,
        ),
        ConfirmOption(
          label: 'Bỏ thay đổi',
          icon: AppIcons.x,
          value: true,
          kind: AppButtonKind.dangerOutline,
        ),
      ],
    );
    if (discard != true || !mounted) return;
    ref.read(profileViewModelProvider.notifier).discard();
    _close();
  }

  Future<void> _save() async {
    final vm = ref.read(profileViewModelProvider.notifier);
    final saved = await vm.save();
    if (saved == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    showUndoSnackbar(
      context,
      title: 'Đã lưu thông tin của Bác.',
      onUndo: () async {
        final error = await vm.undo(saved);
        if (error != null) {
          messenger.showSnackBar(SnackBar(content: Text(error)));
        }
      },
    );
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final vm = ref.read(profileViewModelProvider.notifier);
    // Nạp xong / Bỏ thay đổi / Hoàn tác / lưu (tên đã gọn khoảng trắng):
    // điền lại ô tên khi giá trị khác chữ đang gõ.
    ref.listen(profileViewModelProvider, (_, next) {
      if (next case UiData(:final data)
          when data.displayName != _nameController.text) {
        _nameController.text = data.displayName;
      }
    });
    if (state case UiData(:final data)
        when _nameController.text.isEmpty && data.displayName.isNotEmpty) {
      _nameController.text = data.displayName;
    }
    final dirty = state is UiData<ProfileForm> && state.data.dirty;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBackBar.adaptive(context, onBack: _leave),
        body: SafeArea(
          top: false,
          child: switch (state) {
            UiLoading() =>
              const LoadingView(message: 'Đang mở thông tin của Bác…'),
            UiError(:final message) => ErrorView(
                message: message,
                detail: 'Thông tin của Bác vẫn còn, không bị mất.',
                onRetry: vm.retry,
              ),
            // ViewModel không phát UiEmpty (xem chú thích đầu file); switch cần đủ nhánh.
            UiEmpty() =>
              const LoadingView(message: 'Đang mở thông tin của Bác…'),
            UiData(:final data) => _ProfileForm(
                form: data,
                nameController: _nameController,
                onSave: _save,
                onCancel: _leave,
              ),
          },
        ),
      ),
    );
  }
}

class _ProfileForm extends ConsumerWidget {
  const _ProfileForm({
    required this.form,
    required this.nameController,
    required this.onSave,
    required this.onCancel,
  });

  final ProfileForm form;
  final TextEditingController nameController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(profileViewModelProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.lg),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(
              header: true,
              child: Text('Thông tin của Bác',
                  style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Bác đổi lại khi cần nhé.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Tên Bác',
              icon: AppIcons.user,
              controller: nameController,
              errorText: form.nameError,
              hint: 'Lan',
              onChanged: vm.changeName,
              autofillHints: const [AutofillHints.givenName],
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            const FieldLabel('An Nhiên gọi Bác là', icon: AppIcons.smile),
            const SizedBox(height: AppSpacing.sm),
            ChoiceGroup<Honorific>(
              layout: ChoiceLayout.segmented,
              value: form.honorific,
              onChanged: vm.changeHonorific,
              options: [
                for (final h in Honorific.values)
                  ChoiceOption(value: h, label: h.label),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Đang chọn: ${form.honorific.label}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            const SizedBox(height: AppSpacing.lg),
            TimeField(
              label: 'Bác thức dậy lúc',
              icon: AppIcons.sunrise,
              value: form.wakeTime,
              dialogTitle: 'Bác thường thức dậy lúc mấy giờ?',
              dialogIcon: AppIcons.sunrise,
              onChanged: vm.changeWakeTime,
            ),
            const SizedBox(height: AppSpacing.sm),
            const FieldMessage.hint('Để nhắc việc đúng giờ cho Bác.'),
            const SizedBox(height: AppSpacing.base),
            // Figma: hộp nền xanh; chưa có widget hộp lưu ý → dòng ⓘ (DT-29, như DT-25).
            const FieldMessage.hint('Việc đã lưu vẫn giữ giờ cũ.'),
            const SizedBox(height: AppSpacing.xl),
            // Khu demo Firebase của Hiếu (F10) – giữ ở cuối N06.
            FirebaseDemoEntry(
                onOpen: () => context.push('/settings/firebase-demo')),
            const SizedBox(height: AppSpacing.betweenTargets),
            if (form.saveError != null) FieldMessage.error(form.saveError!),
            AppButton(
              label: 'Hủy',
              icon: AppIcons.x,
              kind: AppButtonKind.secondary,
              onPressed: form.saving ? null : onCancel,
            ),
          ]),
        ),
      ),
      // Thanh nút cố định ở đáy (Figma "fixed-footer"): luôn thấy, kể cả khi bàn phím mở.
      DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
              AppSpacing.screen, AppSpacing.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppButton(
              label: 'Lưu thông tin',
              icon: AppIcons.save,
              busy: form.saving,
              onPressed: onSave,
            ),
          ]),
        ),
      ),
    ]);
  }
}
