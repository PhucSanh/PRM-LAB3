import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/account_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/botanical_scene.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/state_views.dart';

class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleViewModelProvider);
    final vm = ref.read(roleViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Scaffold(
        body: SafeArea(
            child: switch (state) {
      UiLoading() => const LoadingView(),
      UiEmpty() => const LoadingView(),
      UiError(:final message) => ErrorView(
          message: message,
          onRetry: () => ref.invalidate(roleViewModelProvider)),
      UiData(:final data) => Column(children: [
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: IconButton.filledTonal(
                                tooltip: 'Tài khoản',
                                onPressed: () => context.push('/account'),
                                icon:
                                    const Icon(Icons.account_circle_outlined))),
                        const BotanicalScene(height: 112, branch: false),
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                            header: true,
                            child: Text('Ai sẽ dùng An Nhiên?',
                                style: text.headlineMedium)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Chọn cách dùng phù hợp với mình.',
                            style: text.bodyLarge),
                        const SizedBox(height: AppSpacing.lg),
                        IgnorePointer(
                            ignoring: data.busy,
                            child: ChoiceGroup<UserRole>(
                                value: data.role,
                                onChanged: vm.select,
                                options: const [
                                  ChoiceOption(
                                      value: UserRole.elder,
                                      label: 'Tôi là Bác',
                                      description:
                                          'Xem lịch và nhận lời nhắc mỗi ngày.',
                                      icon: Icons.spa_outlined),
                                  ChoiceOption(
                                      value: UserRole.caregiver,
                                      label: 'Tôi là con cháu',
                                      description:
                                          'Cùng người thân sắp xếp lịch sinh hoạt.',
                                      icon: Icons.favorite_border_rounded),
                                ])),
                        if (data.message != null) ...[
                          const SizedBox(height: AppSpacing.base),
                          Semantics(
                              liveRegion: true,
                              child:
                                  Text(data.message!, style: text.bodyLarge)),
                        ],
                      ]))),
          Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: AppButton(
                  label: 'Tiếp tục',
                  icon: Icons.arrow_forward_rounded,
                  busy: data.busy,
                  onPressed: data.role == null ? null : vm.submit)),
        ]),
    }));
  }
}
