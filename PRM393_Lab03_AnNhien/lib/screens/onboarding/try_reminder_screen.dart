import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/try_reminder_view_model.dart';
import '../../widgets/app_back_bar.dart';
import 'onboarding_layout.dart';
import '../../widgets/app_button.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/task_widgets.dart';

/// N01 Thử lời nhắc (`31:68`) · N02 hỏi đã nhận chưa (`31:170`) · N03 Chưa nhận
/// lời nhắc (`31:218`) – chủ: Hương (F2). Cùng route `/setup/try-reminder`, vẽ
/// theo `TryReminderState.phase`. Màn không tải dữ liệu nên không có Loading /
/// Empty; lỗi gửi thử hiện ngay trên nút "Thử lại".
/// Đi tiếp (đã nhận / "Dùng lịch trước" / "Để sau") → `/setup/first-task`.
class TryReminderScreen extends ConsumerWidget {
  const TryReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tryReminderViewModelProvider);
    final vm = ref.read(tryReminderViewModelProvider.notifier);
    void next() => context.go('/setup/first-task');

    final atStart = switch (state.phase) {
      TryReminderPhase.idle ||
      TryReminderPhase.sending ||
      TryReminderPhase.received =>
        true,
      _ => false,
    };
    return Scaffold(
      appBar: AppBackBar.adaptive(
        context,
        onBack:
            atStart ? () => context.go('/setup/notifications') : vm.backToStart,
      ),
      body: SafeArea(
        top: false,
        child: switch (state.phase) {
          TryReminderPhase.waitingAnswer => _AskReceived(
              onYes: () async {
                await vm.answer(true);
                if (context.mounted) next();
              },
              onNo: () => vm.answer(false),
            ),
          TryReminderPhase.notReceived => _NotReceived(
              sending: state.sending, onRetry: vm.retry, onSkip: next),
          _ => _Start(state: state, onSend: vm.sendTest, onLater: next),
        },
      ),
    );
  }
}

/// Tiêu đề + câu phụ đầu màn.
class _Header extends StatelessWidget {
  const _Header(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineMedium)),
      const SizedBox(height: AppSpacing.xs),
      Text(subtitle,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

/// Thẻ trắng viền nhạt bọc một nhóm nội dung.
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child:
          Padding(padding: const EdgeInsets.all(AppSpacing.base), child: child),
    );
  }
}

/// Một dòng icon + câu (chữ thường, không đậm).
class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ExcludeSemantics(
        child:
            Icon(icon, size: AppSizes.icon, color: theme.colorScheme.primary),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
    ]);
  }
}

/// N01 – giải thích, thẻ mẫu, nút "Gửi thử". Lỗi gửi: câu lỗi + nút "Thử lại".
class _Start extends StatelessWidget {
  const _Start(
      {required this.state, required this.onSend, required this.onLater});

  final TryReminderState state;
  final VoidCallback onSend;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failed = state.error != null;
    return OnboardingLayout(
      body: [
        const _Header('Thử lời nhắc',
            'Bác có thể gửi thử để nghe chuông và xem lời nhắc hiện trên máy.'),
        _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(AppIcons.bell,
                      size: AppSizes.icon, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text('Lời nhắc thử',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.primary)),
                  ),
                ]),
                Text('Mẫu xem trước',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const TaskRow(
              time: TimeOfDay(hour: 9, minute: 30),
              title: 'Đi bộ nhẹ nhàng',
              habitKey: 'move',
            ),
          ]),
        ),
        const FieldMessage.hint(
            'Bác thử chuông; việc này không thêm vào lịch.'),
        const _Card(
          child: Column(children: [
            _IconLine(
                AppIcons.volume, 'Chuông sẽ reo nhẹ để Bác kiểm tra âm lượng.'),
            SizedBox(height: AppSpacing.md),
            _IconLine(
                AppIcons.bell, 'Bác có thể thử chuông bất cứ khi nào muốn.'),
          ]),
        ),
      ],
      footer: [
        if (failed) FieldMessage.error(state.error!),
        AppButton(
          label: failed ? 'Thử lại' : 'Gửi thử',
          icon: failed ? AppIcons.retry : Icons.notifications_active_rounded,
          busy: state.sending,
          onPressed: onSend,
        ),
        AppButton(
          label: 'Để sau',
          icon: AppIcons.later,
          kind: AppButtonKind.text,
          onPressed: state.sending ? null : onLater,
        ),
      ],
    );
  }
}

/// N02 – lời nhắc thử đã gửi, hỏi Bác đã nhận được chưa.
class _AskReceived extends StatelessWidget {
  const _AskReceived({required this.onYes, required this.onNo});

  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      body: const [
        _Header('Đã gửi lời nhắc thử', 'Bác đã nhận được chưa?'),
        _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FieldLabel('Lời nhắc có hiện lên', icon: AppIcons.bell),
            Divider(height: AppSpacing.xl),
            FieldLabel('Chuông hoặc rung có phát',
                icon: Icons.notifications_active_rounded),
            Divider(height: AppSpacing.xl),
            FieldLabel('Chữ trong lời nhắc có dễ đọc',
                icon: Icons.text_fields_rounded),
          ]),
        ),
        FieldMessage.hint('Bác có thể xem lại sau.'),
      ],
      footer: [
        AppButton(
          label: 'Đã nhận được',
          icon: AppIcons.arrowRight,
          onPressed: onYes,
        ),
        AppButton(
          label: 'Chưa nhận được',
          icon: Icons.notifications_off_rounded,
          kind: AppButtonKind.secondary,
          onPressed: onNo,
        ),
      ],
    );
  }
}

/// N03 – 3 chỗ cần kiểm tra, "Thử lại" hoặc dùng lịch luôn.
class _NotReceived extends StatelessWidget {
  const _NotReceived(
      {required this.sending, required this.onRetry, required this.onSkip});

  final bool sending;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  static const _steps = [
    (AppIcons.bell, 'Kiểm tra quyền', 'Cho phép An Nhiên gửi lời nhắc.'),
    (
      Icons.smartphone_rounded,
      'Kiểm tra âm lượng',
      'Tăng âm lượng; tắt Không làm phiền.'
    ),
    (AppIcons.retry, 'Thử lại', 'Chạm nút bên dưới để thử lại.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingLayout(
      body: [
        const _Header('Chưa nhận lời nhắc', 'Bác cùng kiểm tra 3 chỗ nhé.'),
        for (final (i, (icon, title, detail)) in _steps.indexed)
          _Card(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FieldLabel('${i + 1}. $title', icon: icon),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: AppSizes.icon + AppSpacing.sm),
                    child: Text(detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ]),
          ),
      ],
      footer: [
        AppButton(
          label: 'Thử lại',
          icon: AppIcons.retry,
          busy: sending,
          onPressed: onRetry,
        ),
        AppButton(
          label: 'Dùng lịch trước',
          icon: AppIcons.arrowRight,
          kind: AppButtonKind.secondary,
          onPressed: sending ? null : onSkip,
        ),
      ],
    );
  }
}
