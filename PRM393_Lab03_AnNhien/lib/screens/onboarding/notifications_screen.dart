import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_error.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import 'onboarding_layout.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/icon_circle.dart';
import '../../widgets/state_views.dart';
import '../../widgets/time_field.dart';

/// S13 Cho phép nhắc việc (Bước 2/2, Figma `1:217`) + S13d Nhắc việc đang tắt
/// (`14:284`) – chủ: Hương (F2). Cùng route `/setup/notifications`, chọn theo
/// `OnboardingData.step`. Loading / Error (+ Thử lại) dùng chung với S02 (nạp
/// dữ liệu onboarding); không có Empty.
/// Cho phép → `/setup/try-reminder`; "Vẫn để sau" ở S13d → `/setup/first-task`.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Đã có quyền từ trước thì không hỏi lại (lần vào đầu).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await ref
          .read(onboardingViewModelProvider.notifier)
          .checkPermission();
      if (granted && mounted) context.go('/setup/try-reminder');
    });
  }

  Future<void> _allow() async {
    final result =
        await ref.read(onboardingViewModelProvider.notifier).allowReminders();
    if (result == PermissionResult.granted && mounted) {
      context.go('/setup/try-reminder');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);
    final denied = switch (state) {
      UiData(:final data) => data.step == OnboardingStep.notificationsDenied,
      _ => false,
    };
    return Scaffold(
      appBar: AppBackBar(
        step: 'Bước 2/2',
        onBack: denied ? vm.showReminderPrompt : () => context.go('/setup'),
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang mở…'),
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          UiEmpty() => ErrorView(
              message: AppException.unknown.userMessage, onRetry: vm.load),
          UiData(:final data) => denied
              ? _RemindersOff(
                  busy: data.saving,
                  onAllow: _allow,
                  onLater: () => context.go('/setup/first-task'),
                )
              : _AskReminders(
                  busy: data.saving,
                  onAllow: _allow,
                  onLater: vm.skipReminders,
                ),
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
      );
}

/// Figma `1:217` – giải thích trước khi điện thoại hỏi quyền (priming).
class _AskReminders extends StatelessWidget {
  const _AskReminders(
      {required this.busy, required this.onAllow, required this.onLater});

  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      body: const [
        Center(child: IconCircle(icon: AppIcons.bell)),
        _Heading('Cho phép nhắc việc'),
        // Câu dặn đặt trước thẻ ví dụ để luôn thấy trước khi điện thoại hỏi (DT-25).
        FieldMessage.hint('Khi điện thoại hỏi, Bác bấm "Cho phép".'),
        _ReminderPreview(),
      ],
      footer: [
        AppButton(
          label: 'Bật nhắc việc',
          icon: AppIcons.bell,
          busy: busy,
          onPressed: onAllow,
        ),
        AppButton(
          label: 'Để sau',
          icon: AppIcons.later,
          kind: AppButtonKind.secondary,
          onPressed: busy ? null : onLater,
        ),
      ],
    );
  }
}

/// Thẻ "Lời nhắc sẽ như thế này": giống một lời nhắc thật (Vận động · 9:30 sáng).
class _ReminderPreview extends StatelessWidget {
  const _ReminderPreview();

  static const _title = 'Đến giờ đi bộ rồi Bác ơi';
  static const _time = TimeOfDay(hour: 9, minute: 30);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: 'Ví dụ lời nhắc: $_title, ${speakTimeOfDay(_time)}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(AppIcons.bell,
                  size: AppSizes.icon, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Lời nhắc sẽ như thế này',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            HabitAccentCard(
              habitKey: 'move',
              child: Row(children: [
                const HabitBadge(habitKey: 'move'),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title, style: theme.textTheme.titleMedium),
                        Text(formatTimeOfDay(_time),
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: scheme.primary)),
                      ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Figma `14:284` – nói rõ hậu quả, cách bật lại, không trách Bác.
class _RemindersOff extends StatelessWidget {
  const _RemindersOff(
      {required this.busy, required this.onAllow, required this.onLater});

  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    return OnboardingLayout(
      body: [
        const Center(
          child:
              IconCircle(icon: Icons.notifications_off_outlined, danger: true),
        ),
        const _Heading('Nhắc việc đang tắt'),
        Text('Đến giờ điện thoại sẽ không đổ chuông.',
            style: body, textAlign: TextAlign.center),
        Text('Bác tự mở An Nhiên để xem việc.',
            style: body, textAlign: TextAlign.center),
        const FieldMessage.hint(
            'Muốn bật lại, Bác vào: Hôm nay › Cài đặt › Nhắc việc'),
      ],
      footer: [
        AppButton(
          label: 'Vẫn để sau',
          icon: AppIcons.arrowRight,
          kind: AppButtonKind.secondary,
          onPressed: busy ? null : onLater,
        ),
        AppButton(
          label: 'Bật nhắc việc',
          icon: AppIcons.bell,
          busy: busy,
          onPressed: onAllow,
        ),
      ],
    );
  }
}
