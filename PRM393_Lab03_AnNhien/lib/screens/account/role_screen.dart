import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/account_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleViewModelProvider);
    final vm = ref.read(roleViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, actions: [
        IconButton(
            tooltip: 'Tài khoản',
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_rounded)),
      ]),
      body: SafeArea(
          child: switch (state) {
        UiLoading() => const LoadingView(),
        UiError(:final message) => ErrorView(
            message: message,
            onRetry: () => ref.invalidate(roleViewModelProvider)),
        UiEmpty() => const LoadingView(),
        UiData(:final data) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ai sẽ dùng An Nhiên?', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              Text('Chọn cách dùng phù hợp với mình.', style: text.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              Text('Bác', style: text.titleLarge),
              Text('Xem lịch và nhận lời nhắc mỗi ngày.',
                  style: text.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                  selected: data.role == UserRole.elder,
                  child: AppButton(
                    label: 'Tôi là Bác',
                    kind: AppButtonKind.secondary,
                    icon: data.role == UserRole.elder
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    onPressed:
                        data.busy ? null : () => vm.select(UserRole.elder),
                  )),
              const SizedBox(height: AppSpacing.xl),
              Text('Con cháu', style: text.titleLarge),
              Text('Cùng người thân sắp xếp lịch sinh hoạt.',
                  style: text.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                  selected: data.role == UserRole.caregiver,
                  child: AppButton(
                    label: 'Tôi là con cháu',
                    kind: AppButtonKind.secondary,
                    icon: data.role == UserRole.caregiver
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    onPressed:
                        data.busy ? null : () => vm.select(UserRole.caregiver),
                  )),
              if (data.message != null) ...[
                const SizedBox(height: AppSpacing.base),
                Semantics(
                    liveRegion: true,
                    child: Text(data.message!, style: text.bodyLarge)),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                  label: 'Tiếp tục',
                  icon: Icons.arrow_forward_rounded,
                  busy: data.busy,
                  onPressed: data.role == null ? null : vm.submit),
            ]),
          ),
      }),
    );
  }
}
