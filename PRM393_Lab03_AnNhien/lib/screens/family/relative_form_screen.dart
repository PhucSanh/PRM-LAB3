import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/contacts_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/family_view_model.dart';
import '../../viewmodels/relative_form_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/contact_row.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';

/// S12 Thêm người thân (`/family/add`) – F11, Hương. Dùng chung cho N09 Sửa người thân (bước 04).
///
/// **Một màn bố cục S12a** (người dùng chọn 04/11, DT-35): S12a `14:120` mới mở → S12 tự nhập `1:2215` đã điền
/// → S12e `14:196` lỗi (giữ tên + quan hệ). "Chọn từ danh bạ" mở bước danh bạ `1:2146` ngay trong màn; chọn
/// một người thì điền sẵn rồi về form. Từ chối quyền danh bạ: ở lại form, dòng ⓘ, vẫn tự nhập được.
/// Lưu xong: `FamilyViewModel.showAdded` (banner S09b) rồi về Gia đình. Đã nhập dở mà quay lại → hỏi trước.
class RelativeFormScreen extends ConsumerStatefulWidget {
  const RelativeFormScreen({super.key, this.personId});

  /// `null` = thêm mới.
  final String? personId;

  @override
  ConsumerState<RelativeFormScreen> createState() => _RelativeFormScreenState();
}

class _RelativeFormScreenState extends ConsumerState<RelativeFormScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _search = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Điền lại ô khi ViewModel đổi giá trị (chọn từ danh bạ, chèn khoảng trắng 4-3-3).
  void _sync(TextEditingController c, String value) {
    if (c.text == value) return;
    c.value = TextEditingValue(
        text: value, selection: TextSelection.collapsed(offset: value.length));
  }

  void _close() => context.canPop() ? context.pop() : context.go('/family');

  /// "‹ Gia đình" / Back hệ thống. Ở danh bạ → về form; đã nhập dở → hỏi trước (DT-35).
  Future<void> _leave() async {
    final vm =
        ref.read(relativeFormViewModelProvider(widget.personId).notifier);
    final data =
        switch (ref.read(relativeFormViewModelProvider(widget.personId))) {
      UiData(:final data) => data,
      _ => null,
    };
    if (data?.step == RelativeFormStep.contacts) {
      vm.closeContacts();
      return;
    }
    if (data == null || !data.dirty) {
      _close();
      return;
    }
    final discard = await showConfirmDialog<bool>(
      context,
      icon: AppIcons.alert,
      title: 'Bỏ người thân đang nhập?',
      message: 'Tên và số Bác vừa nhập sẽ không được lưu.',
      options: const [
        ConfirmOption(
            label: 'Ở lại nhập tiếp',
            icon: AppIcons.pencil,
            value: false,
            kind: AppButtonKind.primary),
        ConfirmOption(
            label: 'Bỏ, quay lại',
            icon: AppIcons.x,
            value: true,
            kind: AppButtonKind.dangerOutline),
      ],
    );
    if (discard == true && mounted) _close();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final vm =
        ref.read(relativeFormViewModelProvider(widget.personId).notifier);
    final saved = await vm.save();
    if (saved == null || !mounted) return;
    // TODO bước 04: chế độ sửa (N09) – Hoàn tác thay cho banner S09b.
    await ref.read(familyViewModelProvider.notifier).showAdded(saved);
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final provider = relativeFormViewModelProvider(widget.personId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    ref.listen(provider, (_, next) {
      if (next case UiData(:final data)) {
        _sync(_name, data.name);
        _sync(_phone, data.phone);
      }
    });
    if (state case UiData(:final data)
        when _name.text.isEmpty && data.name.isNotEmpty) {
      _sync(_name, data.name);
      _sync(_phone, data.phone);
    }

    final data = switch (state) {
      UiData(:final data) => data,
      _ => null,
    };
    final inContacts = data?.step == RelativeFormStep.contacts;

    return PopScope(
      canPop: !(inContacts || (data?.dirty ?? false)),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        // Danh bạ là bước con của form: nút về form ghi "Quay lại" (Figma "Gia đình", DT-35).
        appBar: AppBackBar(
            backLabel: inContacts ? 'Quay lại' : 'Gia đình', onBack: _leave),
        body: SafeArea(
          top: false,
          child: switch (state) {
            UiLoading() => const LoadingView(message: 'Đang mở người thân…'),
            UiError(:final message) => ErrorView(
                message: message,
                detail: 'Người thân của Bác vẫn còn, không bị mất.',
                onRetry: vm.retry,
              ),
            // TODO bước 04: câu Empty của N09 (DT).
            UiEmpty() => EmptyView(
                icon: AppIcons.user,
                title: 'Không tìm thấy người thân này.',
                action: AppButton(
                    label: 'Về Gia đình',
                    icon: AppIcons.tabFamily,
                    onPressed: () => context.go('/family')),
              ),
            UiData(:final data) => inContacts
                ? _ContactsStep(form: data, search: _search, vm: vm)
                : _FormStep(
                    form: data,
                    name: _name,
                    phone: _phone,
                    vm: vm,
                    onSave: _save),
          },
        ),
      ),
    );
  }
}

/// Tiêu đề màn có icon (Figma "Tiêu đề màn hình": icon 32 + chữ 30 đậm).
class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: AppSizes.icon, color: theme.colorScheme.primary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
          child: Semantics(
              header: true,
              child: Text(text, style: theme.textTheme.headlineMedium))),
    ]);
  }
}

/// S12a / S12 tự nhập / S12e.
class _FormStep extends StatelessWidget {
  const _FormStep({
    required this.form,
    required this.name,
    required this.phone,
    required this.vm,
    required this.onSave,
  });

  final RelativeForm form;
  final TextEditingController name;
  final TextEditingController phone;
  final RelativeFormViewModel vm;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.lg),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _ScreenTitle(
                icon: AppIcons.userPlus, text: 'Thêm người thân'),
            const SizedBox(height: AppSpacing.base),
            AppButton(
              label: 'Chọn từ danh bạ',
              icon: AppIcons.contact,
              kind: AppButtonKind.secondary,
              wrapLabel: true,
              onPressed: form.saving ? null : vm.pickFromContacts,
            ),
            if (form.contactsNotice != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                  liveRegion: true,
                  child: FieldMessage.hint(form.contactsNotice!)),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('hoặc tự nhập', style: muted, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Tên gọi',
              hint: 'Mai, Hùng',
              controller: name,
              errorText: form.nameError,
              onChanged: vm.setName,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            const FieldLabel('Là gì của Bác?'),
            const SizedBox(height: AppSpacing.sm),
            ChoiceGroup<String>(
              value: form.relation,
              onChanged: vm.setRelation,
              options: [
                for (final r in relativeRelations)
                  ChoiceOption(value: r, label: r)
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Số điện thoại',
              hint: '0912 345 678',
              controller: phone,
              errorText: form.phoneError,
              onChanged: vm.setPhone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
            ),
            if (form.hasInputError) ...[
              const SizedBox(height: AppSpacing.sm),
              const FieldMessage.hint(
                  'Bác chạm “Chọn từ danh bạ” ở trên cho nhanh.'),
            ],
            const SizedBox(height: AppSpacing.base),
            const FieldMessage.hint('Chỉ gửi tin khi Bác chọn gửi.'),
          ]),
        ),
      ),
      _SaveBar(form: form, onSave: onSave),
    ]);
  }
}

/// Nút chính "Lưu người thân" ghim đáy, luôn nằm trên bàn phím (Scaffold co lại khi bàn phím mở).
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.form, required this.onSave});

  final RelativeForm form;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.base,
            AppSpacing.screen, AppSpacing.base),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (form.saveError != null) ...[
                FieldMessage.error(form.saveError!),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                  label: 'Lưu người thân',
                  icon: AppIcons.save,
                  busy: form.saving,
                  onPressed: onSave),
            ]),
      ),
    );
  }
}

/// S12 "Chọn từ danh bạ" `1:2146`: ô "Tìm tên" + danh sách liên hệ. Không có nút ghim đáy.
class _ContactsStep extends StatelessWidget {
  const _ContactsStep(
      {required this.form, required this.search, required this.vm});

  final RelativeForm form;
  final TextEditingController search;
  final RelativeFormViewModel vm;

  static String _subtitle(PhoneContact c) {
    final phone = formatPhone(c.phone);
    return c.label == null || c.label!.isEmpty ? phone : '${c.label} · $phone';
  }

  @override
  Widget build(BuildContext context) {
    final Widget results;
    if (form.contactsLoading && form.contacts.isEmpty) {
      results = const LoadingView(message: 'Đang mở danh bạ…');
    } else if (form.contacts.isEmpty) {
      // Figma không vẽ (DT-35): danh bạ trống / tìm không thấy.
      results = EmptyView(
        icon: AppIcons.search,
        title: 'Không thấy tên này trong danh bạ',
        message: 'Bác thử tên khác hoặc tự nhập.',
        action: AppButton(
          label: 'Tự nhập',
          icon: AppIcons.pencil,
          kind: AppButtonKind.secondary,
          onPressed: vm.closeContacts,
        ),
      );
    } else {
      results =
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, c) in form.contacts.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.betweenTargets),
          ContactRow(
              name: c.name,
              subtitle: _subtitle(c),
              onTap: () => vm.selectContact(c)),
        ],
      ]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
      children: [
        const _ScreenTitle(icon: AppIcons.contact, text: 'Chọn từ danh bạ'),
        const SizedBox(height: AppSpacing.base),
        AppTextField(
          label: 'Tìm tên',
          placeholder: 'Nhập tên người thân',
          prefixIcon: AppIcons.search,
          controller: search,
          onChanged: vm.search,
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: AppSpacing.lg),
        results,
      ],
    );
  }
}
