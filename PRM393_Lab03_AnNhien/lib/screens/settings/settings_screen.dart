import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_settings.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/display_settings.dart';
import '../../viewmodels/account_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/nav_row.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/switch_row.dart';
import '../../widgets/undo_snackbar.dart';

/// S10 Cài đặt hiển thị (`/settings`, Figma `1:2325` + `1:2474` cuộn xuống) – F8, Sanh.
///
/// Vẽ `UiState<AppSettings>` của `SettingsViewModel`: Loading → `LoadingView`,
/// Error → `ErrorView` + "Thử lại", Data → nội dung. Không có Empty: cài đặt
/// luôn có giá trị (thiếu thì dùng mặc định), không có trạng thái "chưa có gì".
///
/// Đổi cỡ chữ / tương phản cao: cả app đổi ngay khi chạm. Mọi thay đổi hiện
/// Snackbar "Hoàn tác" (không tự tắt); lưu lỗi thì câu báo nhẹ nằm trong chính
/// Snackbar đó, giá trị vẫn giữ trên máy. Đăng xuất hỏi lại trước
/// (`signOutViewModelProvider` – F1, Hiếu).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    return Scaffold(
      appBar: const AppBackBar(),
      body: SafeArea(
        top: false,
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải cài đặt…'),
          // ViewModel không phát UiEmpty (xem chú thích đầu file); switch cần đủ nhánh.
          UiEmpty() => const LoadingView(message: 'Đang tải cài đặt…'),
          UiError(:final message) => ErrorView(
              message: message,
              detail: 'Cài đặt của Bác vẫn còn, không bị mất.',
              onRetry: ref.read(settingsViewModelProvider.notifier).retry,
            ),
          UiData(:final data) => _SettingsBody(settings: data),
        },
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(settingsViewModelProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    /// Hiện Snackbar Hoàn tác sau mỗi lần đổi (lưu lỗi: thêm câu báo nhẹ).
    void announce(SettingChange? change) {
      if (change == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      showUndoSnackbar(
        context,
        title: _changeTitle(change),
        subtitle: change.saveError,
        onUndo: () async {
          final error = await vm.undo(change);
          if (error != null) {
            messenger.showSnackBar(SnackBar(content: Text(error)));
          }
        },
      );
    }

    // Vạch ngăn giữa 2 công tắc: cách mỗi bên 16 (Figma), không số cứng.
    final divider =
        Divider(height: AppSpacing.xl, color: scheme.outlineVariant);

    // Không dùng ListView: màn ngắn, dựng hết một lần để TalkBack đọc đủ.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Tiêu đề đặt ở đầu nội dung (không trong app bar) để chữ ×2.0 không bị thu nhỏ (DT-28).
        Row(children: [
          Icon(AppIcons.settings, size: AppSizes.icon, color: scheme.onSurface),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text('Cài đặt hiển thị',
                  style: theme.textTheme.headlineMedium),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.base),
        SectionCard(
          icon: AppIcons.textSize,
          title: 'Cỡ chữ',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ChoiceGroup<AppFontScale>(
              value: settings.fontScale,
              onChanged: (scale) async =>
                  announce(await vm.setFontScale(scale)),
              options: [
                for (final scale in AppFontScale.values)
                  ChoiceOption(
                    value: scale,
                    label: scale.label,
                    previewScale: scale.factor,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            const _FontPreview(),
          ]),
        ),
        const SizedBox(height: AppSpacing.base),
        SectionCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SwitchRow(
              icon: AppIcons.contrast,
              title: 'Chữ và nền rõ hơn',
              subtitle: 'Tăng độ tương phản',
              value: settings.highContrast,
              onChanged: (on) async => announce(await vm.setHighContrast(on)),
            ),
            divider,
            SwitchRow(
              icon: AppIcons.volume,
              title: 'Đọc to nội dung',
              subtitle: 'Điện thoại đọc lời nhắc',
              value: settings.readAloud,
              onChanged: (on) async => announce(await vm.setReadAloud(on)),
            ),
            divider,
            SwitchRow(
              icon: AppIcons.vibrate,
              title: 'Rung khi có lời nhắc',
              subtitle: 'Kèm tiếng chuông',
              value: settings.vibrate,
              onChanged: (on) async => announce(await vm.setVibrate(on)),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.base),
        // S14 của Khang (F6); `?preview=true` = xem thử, không ghi gì (architecture.md mục 7.2).
        AppButton(
          label: 'Xem thử lời nhắc',
          icon: AppIcons.bellRing,
          kind: AppButtonKind.secondary,
          onPressed: () => context.push('/reminder/preview?preview=true'),
        ),
        const SizedBox(height: AppSpacing.betweenTargets),
        NavRow(
          icon: AppIcons.bookOpen,
          title: 'Cách dùng đơn giản',
          onTap: () => context.push('/settings/help'),
        ),
        const SizedBox(height: AppSpacing.betweenTargets),
        NavRow(
          icon: AppIcons.user,
          title: 'Thông tin của Bác',
          onTap: () => context.push('/settings/profile'),
        ),
        const SizedBox(height: AppSpacing.betweenTargets),
        NavRow(
          icon: AppIcons.bell,
          title: 'Lời nhắc',
          onTap: () => context.push('/settings/reminders'),
        ),
        const SizedBox(height: AppSpacing.betweenTargets),
        NavRow(
          icon: AppIcons.smartphone,
          title: 'Dữ liệu trên điện thoại',
          onTap: () => context.push('/settings/data'),
        ),
        const SizedBox(height: AppSpacing.xl),
        NavRow(
            icon: AppIcons.bell,
            title: 'Hộp thông báo',
            subtitle: 'Tin từ gia đình và hệ thống',
            onTap: () => context.push('/inbox')),
        const SizedBox(height: AppSpacing.betweenTargets),
        NavRow(
          icon: AppIcons.user,
          title: 'Tài khoản và ghép nối',
          subtitle: 'Kết nối với người thân',
          onTap: () => context.push('/account'),
        ),
        const SizedBox(height: AppSpacing.betweenTargets),
        const _SignOutButton(),
      ]),
    );
  }

  static String _changeTitle(SettingChange change) => switch (change) {
        FontScaleChange(:final to) => 'Đã đổi cỡ chữ sang ${to.label}.',
        HighContrastChange(:final to) =>
          to ? 'Đã bật chữ và nền rõ hơn.' : 'Đã tắt chữ và nền rõ hơn.',
        ReadAloudChange(:final to) =>
          to ? 'Đã bật đọc to nội dung.' : 'Đã tắt đọc to nội dung.',
        VibrateChange(:final to) =>
          to ? 'Đã bật rung khi có lời nhắc.' : 'Đã tắt rung khi có lời nhắc.',
      };
}

/// Khung "Xem thử" (Figma `1:2368`): câu mẫu vẽ theo cỡ chữ đang dùng của cả app.
class _FontPreview extends StatelessWidget {
  const _FontPreview();

  static const sample = 'Đi bộ 20 phút lúc 9:30 sáng';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      label: 'Xem thử: $sample',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: scheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(children: [
            Icon(AppIcons.view, size: AppSizes.icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                sample,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Nút Đăng xuất (đề bắt buộc; Figma S10 không vẽ – DT-28). Hỏi lại, nói rõ hậu quả.
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(signOutViewModelProvider);
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (action.message != null) ...[
        Semantics(
          liveRegion: true,
          child: Text(action.message!, style: text.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.base),
      ],
      AppButton(
        label: 'Đăng xuất',
        icon: AppIcons.logout,
        kind: AppButtonKind.dangerOutline,
        busy: action.busy,
        onPressed: () => _confirmSignOut(context, ref),
      ),
    ]);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog<bool>(
      context,
      icon: AppIcons.logout,
      title: 'Bác muốn đăng xuất?',
      // Câu ngắn để 2 nút vẫn nằm trong màn 800 dp ở cỡ chữ "Lớn".
      message: 'Bác sẽ cần đăng nhập lại. Lịch đã lưu vẫn còn.',
      details: const [
        ConfirmDetail(
          icon: AppIcons.info,
          text: 'Việc chưa kịp lưu lên mạng sẽ bị xoá.',
        ),
      ],
      options: const [
        ConfirmOption(
          label: 'Ở lại',
          icon: AppIcons.x,
          value: false,
          kind: AppButtonKind.primary,
        ),
        ConfirmOption(
          label: 'Đăng xuất',
          icon: AppIcons.logout,
          value: true,
          kind: AppButtonKind.dangerOutline,
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(signOutViewModelProvider.notifier).signOut();
    if (!context.mounted) return;
    // `redirect` trong router đang tạm tắt nên S10 tự về A01; bật lại cũng an toàn.
    if (ref.read(signOutViewModelProvider).message == null) {
      context.go('/sign-in');
    }
  }
}
