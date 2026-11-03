import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_card.dart';

/// N20 Dữ liệu trên điện thoại (`/settings/data`, Figma `52:2`) – F8, Sanh.
/// Nói rõ dữ liệu của Bác nằm ở đâu. Câu chữ đổi cho đúng Lab 3 (lịch lưu trên
/// Firestore theo tài khoản Google, có offline persistence, người thân đã ghép
/// nối mới đọc được) – người dùng duyệt 04/11, xem DT-30.
///
/// Màn tĩnh: không tải dữ liệu nên không có Loading / Empty / Error, không
/// ViewModel (câu chữ cố định, không có logic). Nội dung cuộn được; nút
/// "Về Cài đặt" ghim ở đáy (Figma "fixed-footer").
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  static const _facts = [
    (
      AppIcons.smartphone,
      'Dùng được khi mất mạng',
      'Mất mạng, Bác vẫn xem được lịch đã tải về máy.',
    ),
    (
      AppIcons.info,
      'Đổi điện thoại vẫn còn lịch',
      'Bác đăng nhập lại là thấy lịch cũ.',
    ),
    (
      AppIcons.info,
      'Chia sẻ do Bác quyết định',
      'Chỉ người thân Bác đã ghép nối mới xem được lịch.',
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
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(AppIcons.smartphone,
                              size: AppSizes.icon, color: scheme.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text('Dữ liệu trên điện thoại',
                                  style: theme.textTheme.headlineMedium),
                            ),
                          ),
                        ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Lịch của Bác được lưu trên tài khoản Google của Bác.',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    for (final (icon, title, body) in _facts) ...[
                      const SizedBox(height: AppSpacing.base),
                      SectionCard(
                        icon: icon,
                        title: title,
                        child: Text(body,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                    ],
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
              child: AppButton(
                label: 'Về Cài đặt',
                icon: AppIcons.chevronLeft,
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/settings'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
