import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/relative.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/family_view_model.dart';
import '../../viewmodels/suggestion_inbox_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/nav_row.dart';
import '../../widgets/relative_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_banner.dart';

/// S09 Gia đình (`/family`, tab 4; Figma `1:1993`) + state S09b vừa thêm người thân (`26:2`) – F11, Hương.
///
/// Vẽ `UiState<FamilyList>` của `FamilyViewModel`: Loading → `LoadingView`, Error → `ErrorView` + "Thử lại",
/// Empty → `EmptyView` "Thêm số điện thoại con cháu" (Figma không vẽ, DT-34), Data → danh sách.
/// Hàng "Gợi ý từ Mai · 2 việc" đọc `suggestionInboxViewModelProvider` (F12 – Sanh); đang tải / lỗi / không có
/// gợi ý thì không chiếm chỗ. Banner S09b mất khi Bác rời tab hoặc mở màn khác (DT-34).
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router != _router) {
      _router?.routerDelegate.removeListener(_onLocationChanged);
      _router = router?..routerDelegate.addListener(_onLocationChanged);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onLocationChanged);
    super.dispose();
  }

  /// Rời tab Gia đình hoặc mở S12 / S17 / N09 → tắt banner S09b.
  void _onLocationChanged() {
    // Route trên cùng (push S12 / S17 / N09 không đổi `uri`, chỉ thêm match).
    final config = _router?.routerDelegate.currentConfiguration;
    final path = config == null || config.isEmpty ? null : config.last.matchedLocation;
    if (path != null && path != '/family') {
      ref.read(familyViewModelProvider.notifier).dismissAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyViewModelProvider);
    final vm = ref.read(familyViewModelProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải người thân…'),
          UiError(:final message) => ErrorView(
              message: message,
              detail: 'Người thân của Bác vẫn còn, không bị mất.',
              onRetry: vm.retry,
            ),
          UiEmpty() => const _EmptyFamily(),
          UiData(:final data) => _FamilyBody(data: data),
        },
      ),
    );
  }
}

/// Tiêu đề "Gia đình" (+ câu phụ theo state – người dùng chọn 04/11: S09 không có câu phụ).
class _Header extends StatelessWidget {
  const _Header({this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
          header: true,
          child: Text('Gia đình', style: theme.textTheme.headlineMedium)),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    ]);
  }
}

/// Hàng "Gợi ý từ Mai" / "2 việc" (Figma S09 `1:1999`) → G03 của F12. Không có gợi ý chờ thì không chiếm chỗ.
class _SuggestionRow extends ConsumerWidget {
  const _SuggestionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(suggestionInboxViewModelProvider);
    final card = switch (inbox) {
      UiData(:final data) => data.pendingCard,
      _ => null,
    };
    if (card == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: NavRow(
        icon: AppIcons.suggestion,
        title: 'Gợi ý từ ${card.fromName}',
        subtitle: '${card.items.length} việc',
        onTap: () => context.push('/today/suggestions/${card.id}?from=family'),
      ),
    );
  }
}

class _FamilyBody extends ConsumerWidget {
  const _FamilyBody({required this.data});

  final FamilyList data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(familyViewModelProvider.notifier);
    final added = data.justAdded;

    Future<void> call(Relative r) async {
      final error = await vm.call(r);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }

    // Câu phụ theo state (Figma): S09 không có, S09b "Bác chọn điều muốn kể cho con".
    // TODO bước 04: N21 "Người thân của Bác" + banner "… đã được xóa" / "Hoàn tác".
    final subtitle = added != null ? 'Bác chọn điều muốn kể cho con' : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, AppSpacing.lg),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Header(subtitle: subtitle),
            if (added != null) ...[
              const SizedBox(height: AppSpacing.base),
              StatusBanner(
                icon: AppIcons.save,
                title: 'Đã thêm ${relativeTitle(added)}',
                message: 'Bác có thể gọi hoặc nhắn tin ngay.',
              ),
            ],
            const _SuggestionRow(),
            for (final r in data.relatives) ...[
              const SizedBox(height: AppSpacing.betweenTargets),
              RelativeCard(
                key: ValueKey('relative-${r.id}'),
                name: r.name,
                relation: relationText(r),
                highlighted: r.id == added?.id,
                openHint: 'Sửa thông tin ${r.name}',
                onOpen: () => context.push('/family/${r.id}/edit'),
                onCall: () => call(r),
                onMessage: () => context.push('/family/${r.id}/share'),
              ),
            ],
          ]),
        ),
      ),
      const _AddButtonBar(),
    ]);
  }
}

/// Nút chính "Thêm người thân" ghim trên bottom nav (Figma `1:2065`).
class _AddButtonBar extends StatelessWidget {
  const _AddButtonBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.base),
      child: AppButton(
        label: 'Thêm người thân',
        icon: AppIcons.userPlus,
        onPressed: () => context.push('/family/add'),
      ),
    );
  }
}

/// Chưa có người thân (Figma không vẽ – handoff S09: Empty "Thêm số điện thoại con cháu"; DT-34).
class _EmptyFamily extends StatelessWidget {
  const _EmptyFamily();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Header(),
          _SuggestionRow(),
        ]),
      ),
      Expanded(
        child: EmptyView(
          icon: AppIcons.userPlus,
          title: 'Thêm số điện thoại con cháu',
          action: AppButton(
            label: 'Thêm người thân',
            icon: AppIcons.userPlus,
            onPressed: () => context.push('/family/add'),
          ),
        ),
      ),
    ]);
  }
}
