import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/display_settings.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/icon_circle.dart';

/// S01 Chào mừng – chọn cỡ chữ (Figma `1:2`) – chủ: Hương (F2).
///
/// Màn KHÔNG tải dữ liệu nên không vẽ Loading / Empty / Error: lựa chọn đang
/// hiện lấy từ `fontScaleProvider` (mặc định "Lớn"), có ngay khi mở màn. Cỡ chữ
/// đã lưu (nếu có) do `OnboardingViewModel.load` áp vào provider đó; lưu lỗi thì
/// ViewModel giữ lựa chọn trên máy, không chặn Bác.
/// Màn gốc nên không có nút Quay lại. "Bắt đầu" → `/setup` (S02).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Giữ ViewModel sống để nạp cỡ chữ đã lưu (state dùng tiếp ở S02, S13).
    ref.watch(onboardingViewModelProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 2 * AppSpacing.screen),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IconCircle(
                          icon: Icons.spa_outlined,
                          color: scheme.onPrimary,
                          background: scheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Chào mừng Bác!',
                            style: t.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.lg),
                        _PreviewCard(),
                        const SizedBox(height: AppSpacing.lg),
                        Row(children: [
                          Icon(Icons.text_fields,
                              size: AppSizes.icon, color: scheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text('Cỡ chữ', style: t.titleLarge),
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        ChoiceGroup<AppFontScale>(
                          value: fontScale,
                          onChanged: vm.selectFontScale,
                          options: [
                            for (final scale in AppFontScale.values)
                              ChoiceOption(
                                value: scale,
                                label: scale.label,
                                previewScale: scale.factor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Thanh nút cố định ở đáy (Figma "4. Fixed Footer Button"): luôn thấy dù chữ ×2.0.
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.md, AppSpacing.screen, AppSpacing.screen),
              child: AppButton(
                label: 'Bắt đầu',
                icon: AppIcons.arrowRight,
                onPressed: () => context.go('/setup'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Khung "Xem thử": câu mẫu vẽ theo cỡ chữ đang chọn (cả app đổi ngay khi chạm).
class _PreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Icon(AppIcons.view,
                  size: AppSizes.icon, color: scheme.onSurfaceVariant),
              Text('Xem thử',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Đến giờ đi bộ rồi Bác ơi',
              style: AppText.bodyLgStrong.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
