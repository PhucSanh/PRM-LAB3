import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_card.dart';

/// N08 Cách dùng đơn giản (`/settings/help`, Figma `41:85`) – F8, Sanh.
/// Hướng dẫn 3 bước để người thân đọc cùng Bác.
///
/// Màn tĩnh: không tải dữ liệu nên không có Loading / Empty / Error, không
/// ViewModel (câu chữ cố định, không có logic). Nội dung cuộn được; 2 nút ghim
/// ở đáy (Figma "fixed-footer") nên luôn thấy dù chữ ×2.0.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _steps = [
    ('Chọn việc', 'Bác chọn việc quen thuộc.'),
    ('Nhắc nhẹ nhàng', 'An Nhiên nhắc Bác đúng giờ.'),
    (
      'Gần gũi người thân',
      'Con cháu gửi gợi ý lịch. Bác chọn nhận hoặc bỏ qua.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: const AppBackBar(),
      body: SafeArea(
        top: false,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Cách dùng đơn giản',
                          style: theme.textTheme.headlineMedium),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Ba bước nhẹ nhàng để bắt đầu mỗi ngày cùng An Nhiên.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.base),
                    for (final (i, (title, body)) in _steps.indexed) ...[
                      _StepCard(number: i + 1, title: title, body: body),
                      const SizedBox(height: AppSpacing.base),
                    ],
                    // Figma: thẻ nền xanh viền đậm; dùng SectionCard có sẵn (DT-31).
                    SectionCard(
                      icon: AppIcons.info,
                      title: 'Bác tự chọn nhận gợi ý lịch.',
                      child: Text('Việc chỉ vào lịch khi Bác bấm nhận.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                  ]),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.md, AppSpacing.screen, AppSpacing.md),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cùng đích với "Xem thử lời nhắc" ở S10 (S14 của Khang).
                    AppButton(
                      label: 'Thử lời nhắc',
                      icon: AppIcons.bellRing,
                      kind: AppButtonKind.secondary,
                      onPressed: () =>
                          context.push('/reminder/preview?preview=true'),
                    ),
                    const SizedBox(height: AppSpacing.betweenTargets),
                    AppButton(
                      label: 'Mở cài đặt',
                      icon: AppIcons.settings,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/settings'),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Một bước: số thứ tự trong vòng tròn + tiêu đề + câu giải thích (Figma `41:91`).
class _StepCard extends StatelessWidget {
  const _StepCard(
      {required this.number, required this.title, required this.body});

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      label: 'Bước $number: $title. $body',
      excludeSemantics: true,
      child: SectionCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: AppSizes.habitIcon,
            height: AppSizes.habitIcon,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$number',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(body,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}
