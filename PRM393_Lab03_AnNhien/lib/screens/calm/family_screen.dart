import '../../widgets/family_contact_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/relative.dart';
import '../../utils/app_error.dart';
import '../../viewmodels/pairing_view_model.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/account_view_model.dart';
import '../../viewmodels/calm_feature_providers.dart';
import '../../viewmodels/suggestion_inbox_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/state_views.dart';
import '../../widgets/suggestion_card.dart';
import '../../widgets/undo_snackbar.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key, this.caregiver = false});
  final bool caregiver;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final family = ref.watch(familyListProvider);
    final text = Theme.of(context).textTheme;
    final suggestions =
        caregiver ? null : ref.watch(suggestionInboxViewModelProvider);
    return Scaffold(
        body: SafeArea(
            child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        const CalmPageHeader(
            title: 'Gia đình',
            subtitle: 'Luôn gần nhau, dù ở bất cứ đâu.',
            art: true),
        const SizedBox(height: AppSpacing.lg),
        if (caregiver) ...[
          Text(
              profile.asData?.value?.pairedMomUid == null
                  ? 'Chưa kết nối với người thân'
                  : 'Đã kết nối với người thân',
              style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'Kết nối cho phép hỗ trợ lịch sinh hoạt theo quyền người thân đã đồng ý.',
              style: text.bodyMedium),
          const SizedBox(height: AppSpacing.base),
          AppButton(
              label: profile.asData?.value?.pairedMomUid == null
                  ? 'Kết nối ngay'
                  : 'Quản lý kết nối',
              icon: Icons.link_rounded,
              kind: AppButtonKind.secondary,
              onPressed: () => context.push('/caregiver/pair')),
        ] else
          AppButton(
              label: 'Kết nối gia đình',
              icon: Icons.link_rounded,
              kind: AppButtonKind.secondary,
              onPressed: () => context.push('/pairing/code')),
        const SizedBox(height: AppSpacing.lg),
        if (!caregiver)
          ref.watch(pairingLinksProvider).when(
                loading: () => const Text('Đang tải kết nối gia đình…'),
                error: (_, __) => TextButton.icon(
                    icon: const Icon(AppIcons.retry),
                    label: const Text('Thử tải lại kết nối'),
                    onPressed: () => ref.invalidate(pairingLinksProvider)),
                data: (links) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          links.isEmpty
                              ? 'Chưa kết nối với người thân.'
                              : 'Người thân đã kết nối',
                          style: text.titleMedium),
                      for (final link in links)
                        CalmListRow(
                            title: link.name,
                            subtitle: 'Được phép hỗ trợ lịch sinh hoạt',
                            icon: Icons.link_rounded),
                      const SizedBox(height: AppSpacing.lg),
                    ]),
              ),
        if (suggestions case UiError(:final message))
          ErrorView(
              message: message,
              onRetry: () =>
                  ref.read(suggestionInboxViewModelProvider.notifier).retry()),
        if (suggestions case UiData(:final data)) ...[
          for (final suggestion in data.pending)
            Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: SuggestionCard(
                    fromName: suggestion.fromName,
                    itemCount: suggestion.items.length,
                    onOpen: () => context.push(
                        '/today/suggestions/${Uri.encodeComponent(suggestion.id)}?from=family'))),
        ],
        Text('Danh bạ gia đình', style: text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
            'Thông tin liên hệ bạn đã lưu. Danh bạ không tự cấp quyền xem lịch.',
            style: text.bodyMedium),
        family.when(
          loading: () => const LoadingView(message: 'Đang tải người thân…'),
          error: (_, __) => ErrorView(
              message: 'Chưa thể tải danh bạ gia đình.',
              onRetry: () => ref.invalidate(familyListProvider)),
          data: (members) => members.isEmpty
              ? const EmptyView(
                  icon: AppIcons.tabFamily,
                  title: 'Chưa có người thân trong danh bạ.')
              : Column(children: [
                  for (final member in members) ...[
                    FamilyContactCard(
                        person: member,
                        onEdit: () => context.push(
                            '/family/${Uri.encodeComponent(member.id)}/edit')),
                    const SizedBox(height: AppSpacing.base),
                    const Divider(height: 1),
                  ]
                ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
            label: 'Thêm người thân',
            icon: Icons.person_add_rounded,
            onPressed: () => context.push('/family/add')),
      ],
    )));
  }
}

class FamilyEditorScreen extends ConsumerStatefulWidget {
  const FamilyEditorScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<FamilyEditorScreen> createState() => _FamilyEditorScreenState();
}

class _FamilyEditorScreenState extends ConsumerState<FamilyEditorScreen> {
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _relation = TextEditingController();
  bool _loaded = false, _dirty = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (ref.read(familyEditorProvider)) return;
    if (_dirty) {
      final leave = await showDialog<bool>(
          context: context,
          builder: (context) =>
              AlertDialog(title: const Text('Bỏ thay đổi chưa lưu?'), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Tiếp tục chỉnh sửa')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Bỏ thay đổi'))
              ]));
      if (leave != true) return;
    }
    if (mounted) {
      setState(() => _dirty = false);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/family');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyListProvider);
    final busy = ref.watch(familyEditorProvider);
    if (widget.id != null && !members.hasValue) {
      return Scaffold(
          appBar: AppBackBar.adaptive(context),
          body: members.hasError
              ? ErrorView(
                  message: 'Chưa thể tải người thân.',
                  onRetry: () => ref.invalidate(familyListProvider))
              : const LoadingView());
    }
    final person =
        members.asData?.value.where((m) => m.id == widget.id).firstOrNull;
    if (!_loaded) {
      _loaded = true;
      _name.text = person?.name ?? '';
      _phone.text = person?.phone ?? '';
      _relation.text = person?.relation ?? '';
    }
    return PopScope(
        canPop: !_dirty && !busy,
        onPopInvokedWithResult: (popped, _) {
          if (!popped && !busy) _leave();
        },
        child: Scaffold(
          appBar: AppBackBar.adaptive(context, onBack: _leave),
          body: SafeArea(
              child: widget.id != null && person == null
                  ? const EmptyView(
                      icon: AppIcons.tabFamily,
                      title: 'Người thân này không còn trong danh bạ.')
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      children: [
                          Text(
                              widget.id == null
                                  ? 'Thêm người thân'
                                  : 'Thông tin người thân',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                              label: 'Tên người thân',
                              controller: _name,
                              onChanged: (_) => setState(() => _dirty = true)),
                          const SizedBox(height: AppSpacing.base),
                          AppTextField(
                              label: 'Mối quan hệ',
                              controller: _relation,
                              hint: 'Con, cháu, bạn bè',
                              onChanged: (_) => setState(() => _dirty = true)),
                          const SizedBox(height: AppSpacing.base),
                          AppTextField(
                              label: 'Số điện thoại',
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => setState(() => _dirty = true)),
                          if (_error != null)
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.base),
                                child: Semantics(
                                    liveRegion: true,
                                    child: Text(_error!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error)))),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                              label: 'Lưu người thân',
                              icon: AppIcons.save,
                              busy: busy,
                              onPressed: () async {
                                try {
                                  final editor =
                                      ref.read(familyEditorProvider.notifier);
                                  final change = await editor.save(
                                      Relative(
                                          id: widget.id ??
                                              'contact-${DateTime.now().microsecondsSinceEpoch}',
                                          favorite: person?.favorite ?? false,
                                          name: _name.text.trim(),
                                          phone: _phone.text.trim(),
                                          relation: _relation.text.trim()),
                                      previous: person);
                                  if (context.mounted) {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    showUndoSnackbar(context,
                                        title: 'Đã lưu người thân',
                                        onUndo: () async {
                                      try {
                                        await editor.undoSave(change);
                                      } catch (_) {
                                        messenger.showSnackBar(const SnackBar(
                                            content: Text(
                                                'Chưa thể hoàn tác. Vui lòng thử lại.')));
                                      }
                                    });
                                    setState(() => _dirty = false);
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/family');
                                    }
                                  }
                                } catch (error) {
                                  if (mounted) {
                                    setState(() => _error = error
                                            is AppException
                                        ? error.userMessage
                                        : 'Chưa thể lưu người thân. Nội dung đã nhập vẫn được giữ lại.');
                                  }
                                }
                              }),
                        ])),
        ));
  }
}

/// Legacy share destination: copy an existing contact, without pretending SMS exists.
class FamilyContactScreen extends ConsumerWidget {
  const FamilyContactScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBackBar.adaptive(context,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/family')),
        body: SafeArea(
            child: ref.watch(familyListProvider).when(
                  loading: () => const LoadingView(),
                  error: (_, __) => ErrorView(
                      message: 'Chưa thể tải người thân.',
                      onRetry: () => ref.invalidate(familyListProvider)),
                  data: (members) {
                    final person = members.where((m) => m.id == id).firstOrNull;
                    if (person == null) {
                      return const EmptyView(
                          icon: AppIcons.tabFamily,
                          title: 'Người thân này không còn trong danh bạ.');
                    }
                    return ListView(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        children: [
                          CalmPageHeader(
                              title: person.name,
                              subtitle: person.relation,
                              actions: false,
                              art: true),
                          const SizedBox(height: AppSpacing.lg),
                          Text(person.phone,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.base),
                          const Text(
                              'Ứng dụng chưa hỗ trợ gửi tin nhắn. Bạn có thể sao chép số điện thoại để liên hệ bên ngoài ứng dụng.'),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                              label: 'Sao chép số điện thoại',
                              icon: Icons.copy_rounded,
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: person.phone));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Đã sao chép số điện thoại.')));
                                }
                              }),
                        ]);
                  },
                )),
      );
}
