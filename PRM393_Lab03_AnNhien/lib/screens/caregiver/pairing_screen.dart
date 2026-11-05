import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/pairing_view_model.dart';
import '../../viewmodels/caregiver_schedule_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/caregiver_parts.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/botanical_scene.dart';
import '../../widgets/form_parts.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key, this.showCode = false});
  final bool showCode;
  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final controller = TextEditingController();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.showCode) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final vm = ref.read(pairingViewModelProvider.notifier);
    if (await vm.redeem(controller.text.trim()) && mounted) {
      ref.invalidate(pairedMomUidProvider);
      context.go('/caregiver/schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pairingViewModelProvider);
    final vm = ref.read(pairingViewModelProvider.notifier);
    final expires = state.code?.expiresAt.difference(DateTime.now());
    final expired = expires != null && expires.inSeconds <= 0;
    return CaregiverPage(
        title:
            widget.showCode ? 'Mã ghép nối của Bác' : 'Nhập mã từ máy của mẹ',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/account');
          }
        },
        footer: widget.showCode
            ? null
            : ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => AppButton(
                  label: 'Ghép nối',
                  icon: Icons.phonelink_rounded,
                  busy: state.busy,
                  wrapLabel: true,
                  onPressed: value.text.length == 6 ? _redeem : null,
                ),
              ),
        children: [
          const BotanicalScene(height: 160, round: true),
          Text(
              widget.showCode
                  ? 'Chỉ đưa mã cho người thân Bác cho phép xem và sửa lịch.'
                  : 'Mã gồm 6 số. Mã hết hạn sau 10 phút.',
              style: Theme.of(context).textTheme.bodyLarge),
          if (widget.showCode) ...[
            if (state.code != null)
              CaregiverInfoCard(children: [
                Semantics(
                    label:
                        'Mã ghép nối ${state.code!.code.split('').join(' ')}',
                    child: Text(state.code!.code,
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center)),
                Text(
                    expired
                        ? 'Mã đã hết hạn. Bác tạo mã mới nhé.'
                        : 'Còn ${expires!.inMinutes} phút ${expires.inSeconds % 60} giây',
                    style: Theme.of(context).textTheme.bodyLarge),
              ]),
            AppButton(
                label: state.code == null ? 'Tạo mã ghép nối' : 'Tạo mã mới',
                icon: Icons.phonelink_setup_rounded,
                busy: state.busy,
                wrapLabel: true,
                onPressed: () async {
                  final yes = await showConfirmDialog<bool>(context,
                      icon: Icons.family_restroom_rounded,
                      title: 'Cho người thân cùng xem và sửa lịch?',
                      message:
                          'Người nhập đúng mã có thể xem lịch và lập lịch giúp Bác. Mã chỉ dùng một lần trong 10 phút.',
                      options: const [
                        ConfirmOption(
                            label: 'Đồng ý, tạo mã',
                            icon: Icons.check_rounded,
                            value: true),
                        ConfirmOption(
                            label: 'Để sau',
                            icon: Icons.close_rounded,
                            value: false)
                      ]);
                  if (yes == true) await vm.createCode();
                }),
          ] else ...[
            AppTextField(
                label: 'Mã ghép nối',
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _redeem(),
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                hint: '123456',
                errorText: state.message),
            CaregiverInfoCard(children: [
              Row(children: [
                const Icon(Icons.phonelink_rounded),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Text('Trên máy của mẹ',
                        style: Theme.of(context).textTheme.titleLarge))
              ]),
              const Text(
                  'Mở Tài khoản → Mã ghép nối của Bác, rồi tạo mã mới. Không cần nhập số điện thoại.')
            ]),
          ],
          if (widget.showCode)
            ref.watch(pairingLinksProvider).when(
                  loading: () => const Text('Đang tải người thân đã ghép nối…'),
                  error: (e, st) => AppButton(
                      label: 'Thử tải lại người thân',
                      icon: Icons.refresh_rounded,
                      kind: AppButtonKind.secondary,
                      wrapLabel: true,
                      onPressed: () => ref.invalidate(pairingLinksProvider)),
                  data: (links) => Column(children: [
                    if (links.isEmpty)
                      const Text('Chưa có người thân nào ghép nối.'),
                    for (final link in links)
                      AppButton(
                          label: 'Ngưng ghép nối với ${link.name}',
                          icon: Icons.link_off_rounded,
                          kind: AppButtonKind.dangerOutline,
                          wrapLabel: true,
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final uid =
                                      ref.read(sessionProvider).value?.uid;
                                  if (uid == null) return;
                                  final yes = await showConfirmDialog<bool>(
                                      context,
                                      icon: Icons.link_off_rounded,
                                      title: 'Ngưng ghép nối với người thân?',
                                      message:
                                          'Người thân này không còn xem hoặc sửa lịch của Bác. Lịch đã lưu vẫn được giữ.',
                                      options: const [
                                        ConfirmOption(
                                            label: 'Giữ ghép nối',
                                            icon: Icons.close_rounded,
                                            value: false),
                                        ConfirmOption(
                                            label: 'Ngưng ghép nối',
                                            icon: Icons.link_off_rounded,
                                            value: true,
                                            kind: AppButtonKind.dangerOutline)
                                      ]);
                                  if (yes == true) {
                                    await vm.revoke(uid, link.uid);
                                  }
                                }),
                  ]),
                ),
          if (widget.showCode && state.message != null)
            FieldMessage.error(state.message!),
          if (!widget.showCode && ref.watch(pairedMomUidProvider) != null)
            AppButton(
                label: 'Xem lịch của mẹ',
                icon: Icons.calendar_month_rounded,
                kind: AppButtonKind.secondary,
                wrapLabel: true,
                onPressed: () => context.go('/caregiver/schedule')),
          if (!widget.showCode && ref.watch(pairedMomUidProvider) != null)
            AppButton(
                label: 'Ngưng ghép nối',
                icon: Icons.link_off_rounded,
                kind: AppButtonKind.dangerOutline,
                wrapLabel: true,
                onPressed: state.busy
                    ? null
                    : () async {
                        final mom = ref.read(pairedMomUidProvider),
                            child = ref.read(sessionProvider).value?.uid;
                        if (mom == null || child == null) return;
                        final yes = await showConfirmDialog<bool>(context,
                            icon: Icons.link_off_rounded,
                            title: 'Ngưng ghép nối với máy của mẹ?',
                            message:
                                'Con cháu không còn xem hoặc sửa lịch. Lịch đã lưu của mẹ vẫn được giữ.',
                            options: const [
                              ConfirmOption(
                                  label: 'Giữ ghép nối',
                                  icon: Icons.close_rounded,
                                  value: false),
                              ConfirmOption(
                                  label: 'Ngưng ghép nối',
                                  icon: Icons.link_off_rounded,
                                  value: true,
                                  kind: AppButtonKind.dangerOutline)
                            ]);
                        if (yes == true) await vm.revoke(mom, child);
                      }),
          const SizedBox(height: AppSpacing.base),
        ]);
  }
}
