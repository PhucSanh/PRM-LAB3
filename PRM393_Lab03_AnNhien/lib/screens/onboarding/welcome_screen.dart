import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/display_settings.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/botanical_scene.dart';
import '../../widgets/choice_group.dart';

/// The reference's introduction composition, with functional paging and no timer.
/// Launch entry is public; the CTA goes through the existing account guards.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.launch = false});
  final bool launch;
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _fontOptions() {
    final vm = ref.read(onboardingViewModelProvider.notifier);
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Consumer(
            builder: (context, ref, _) => SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Cỡ chữ',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.base),
                          const Text('Đến giờ đi bộ rồi Bác ơi'),
                          const SizedBox(height: AppSpacing.base),
                          ChoiceGroup<AppFontScale>(
                              value: ref.watch(fontScaleProvider),
                              onChanged: vm.selectFontScale,
                              options: [
                                for (final scale in AppFontScale.values)
                                  ChoiceOption(
                                      value: scale,
                                      label: scale.label,
                                      previewScale: scale.factor),
                              ]),
                        ])))));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.launch) ref.watch(onboardingViewModelProvider);
    final theme = Theme.of(context);
    const descriptions = [
      'Lịch sinh hoạt và thói quen lành mạnh, giúp Bác an tâm mỗi ngày.',
      'Dành thời gian cho những điều mình yêu thích, theo nhịp riêng của Bác.',
      'Luôn gần bên gia đình, cùng sẻ chia và chăm sóc mỗi ngày.',
    ];
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Expanded(
          child: LayoutBuilder(
              builder: (context, box) => Stack(children: [
                    PageView(
                        controller: _pages,
                        onPageChanged: (page) => setState(() => _page = page),
                        children: [
                          for (var i = 0; i < descriptions.length; i++)
                            SingleChildScrollView(
                                child: Column(children: [
                              const SizedBox(height: AppSpacing.lg),
                              BotanicalScene(
                                  height: (box.maxHeight * .52).clamp(240, 360),
                                  welcome: i == 0,
                                  round: i != 0,
                                  branch: i != 1),
                              const SizedBox(height: AppSpacing.base),
                              ExcludeSemantics(
                                  child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color:
                                                  theme.colorScheme.primary)),
                                      child: Icon(Icons.spa_outlined,
                                          size: 22,
                                          color: theme.colorScheme.primary))),
                              const SizedBox(height: AppSpacing.sm),
                              Semantics(
                                  header: true,
                                  child: const Text('An Nhiên',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.welcomeWordmark)),
                              const SizedBox(height: AppSpacing.base),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.screen),
                                  child: Text('NHẸ NHÀNG MỖI NGÀY',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.welcomeTagline
                                          .copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant))),
                              const SizedBox(height: AppSpacing.lg),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xl),
                                  child: Text(descriptions[i],
                                      style: AppTypography.welcomeBody,
                                      textAlign: TextAlign.center)),
                              const SizedBox(height: AppSpacing.base),
                            ])),
                        ]),
                    if (!widget.launch)
                      Positioned(
                          right: AppSpacing.sm,
                          top: 0,
                          child: IconButton(
                              tooltip: 'Cỡ chữ',
                              onPressed: _fontOptions,
                              icon: const Icon(Icons.text_fields_rounded))),
                  ]))),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          Semantics(
              label: 'Giới thiệu ${i + 1} trên 3',
              selected: i == _page,
              child: InkResponse(
                  onTap: () => _pages.animateToPage(i,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOut),
                  child: SizedBox(
                      width: 36,
                      height: 40,
                      child: Center(
                          child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _page
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant)))))),
      ]),
      Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xl),
          child: FilledButtonTheme(
              data: FilledButtonThemeData(
                  style: theme.filledButtonTheme.style?.copyWith(
                textStyle:
                    const WidgetStatePropertyAll(AppTypography.welcomeAction),
                minimumSize: const WidgetStatePropertyAll(Size(56, 64)),
              )),
              child: AppButton(
                  label: 'Bắt đầu',
                  icon: AppIcons.arrowRight,
                  trailingIcon: true,
                  onPressed: () =>
                      context.go(widget.launch ? '/calendar' : '/setup')))),
    ])));
  }
}
