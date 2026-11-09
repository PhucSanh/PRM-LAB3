import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'habit_widgets.dart';
import 'assistant_mascot.dart';

/// Minh hoạ màn "Nói để thêm việc": Bác nói một câu → cháu ghi thành một việc
/// trong lịch. Vừa là hình, vừa là ví dụ nên nói gì. Chỉ dùng màu của theme.
class VoiceExampleArt extends StatelessWidget {
  const VoiceExampleArt({super.key});

  static const sentence = 'Mai 8 giờ sáng tưới cây 15 phút';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final text = theme.textTheme;
    return Semantics(
      label: 'Ví dụ: Bác nói “$sentence”, cháu thêm việc Tưới cây vào lịch '
          'ngày mai lúc 8 giờ sáng.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.secondaryContainer, colors.surfaceContainerHigh],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Bác nói: bong bóng chat bên phải, kèm micro.
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.xl),
                        topRight: Radius.circular(AppRadius.xl),
                        bottomLeft: Radius.circular(AppRadius.xl),
                        bottomRight: Radius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base, vertical: AppSpacing.md),
                      child: Text('“$sentence”',
                          style: text.bodyLarge
                              ?.copyWith(color: colors.onPrimary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: AppSizes.icon,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: const Icon(AppIcons.mic),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            // Cháu ghi vào lịch.
            Row(children: [
              const AssistantMascot(size: AppSizes.icon),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text('Cháu ghi vào lịch',
                    style: text.titleSmall?.copyWith(color: colors.primary)),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.cardAll,
                boxShadow: [
                  BoxShadow(
                      color: colors.shadow.withValues(alpha: .06),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  Container(
                    width: AppSizes.habitIcon,
                    height: AppSizes.habitIcon,
                    decoration: BoxDecoration(
                        color: colors.primary, borderRadius: AppRadius.mdAll),
                    child: Icon(HabitStyle.iconOf('plant'),
                        color: colors.onPrimary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tưới cây', style: text.titleMedium),
                          Text('Ngày mai · 08:00 · 15 phút',
                              style: text.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ]),
                  ),
                  Icon(Icons.check_circle_rounded,
                      color: colors.primary, size: AppSizes.icon + 8),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
