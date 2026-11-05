import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/botanical_scene.dart';

/// Khung chung các màn onboarding F2 (S02, S13, N01–N03, N04–N18): nội dung
/// cuộn được + thanh nút ghim ở đáy (luôn thấy khi chữ ×2.0; bàn phím mở thì
/// `Scaffold` đẩy lên). Chỉ ghép widget có sẵn, không thay widget F0.
/// Nếu màn khác cần cùng khung, nhờ Sanh (F0) đưa vào `lib/widgets/`.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.body,
    required this.footer,
    this.gap = AppSpacing.base,
    this.centered = false,
  });

  final List<Widget> body;
  final List<Widget> footer;

  /// Khoảng cách giữa các khối nội dung.
  final double gap;

  /// Căn giữa theo chiều dọc khi nội dung ngắn hơn màn (S02 theo Figma).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BotanicalScene(height: 100, branch: false),
        SizedBox(height: gap),
        for (final (i, child) in body.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          child,
        ],
      ],
    );
    return Column(children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: centered
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - 2 * AppSpacing.screen),
                    child: Center(child: content),
                  )
                : content,
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border:
              Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md,
              AppSpacing.screen, AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, child) in footer.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.betweenTargets),
                child,
              ],
            ],
          ),
        ),
      ),
    ]);
  }
}
