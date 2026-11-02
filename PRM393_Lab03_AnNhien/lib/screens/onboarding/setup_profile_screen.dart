import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_error.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/choice_group.dart';
import '../../widgets/form_parts.dart';
import '../../widgets/state_views.dart';
import '../../widgets/time_field.dart';

/// S02 Thiết lập hồ sơ (Bước 1/2) – chủ: Hương (F2). Route `/setup`.
/// Ba state Figma vẽ theo `OnboardingData.profileStage`: Xác nhận tên `1:58`,
/// Nhập lại tên `1:176`, Giới thiệu về Bác `1:103` (+ DLG-WakeTime `31:2`).
/// Loading / Error (+ Thử lại) khi đang nạp tên gợi ý; S02 không có Empty
/// (không có tên gợi ý thì Bác tự gõ tên).
class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  /// Chỉ giữ chữ đang gõ trong ô; giá trị thật nằm ở ViewModel.
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (ref.read(onboardingViewModelProvider) case UiData(:final data)) {
      _nameController.text = data.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    final saved =
        await ref.read(onboardingViewModelProvider.notifier).submitProfile();
    if (saved && mounted) context.go('/setup/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);
    // Mở ô nhập thì điền sẵn tên đang có (sửa từ tên gợi ý).
    ref.listen(onboardingViewModelProvider, (previous, next) {
      final was = switch (previous) {
        UiData(:final data) => data.profileStage,
        _ => null
      };
      if (next case UiData(:final data)
          when data.profileStage == ProfileStage.enterName &&
              was != ProfileStage.enterName) {
        _nameController.text = data.name;
      }
    });

    return Scaffold(
      appBar:
          AppBackBar(step: 'Bước 1/2', onBack: () => context.go('/welcome')),
      body: SafeArea(
        top: false,
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang mở hồ sơ của Bác…'),
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          // S02 không có Empty; giữ nhánh để `switch` đủ trường hợp.
          UiEmpty() => ErrorView(
              message: AppException.unknown.userMessage, onRetry: vm.load),
          UiData(:final data) => switch (data.profileStage) {
              ProfileStage.confirmName => _ConfirmName(data: data),
              ProfileStage.enterName =>
                _EnterName(data: data, controller: _nameController),
              ProfileStage.details =>
                _Details(data: data, onSubmit: _submitProfile),
            },
        },
      ),
    );
  }
}

/// Khung chung của 3 state: nội dung cuộn, căn giữa theo chiều dọc như Figma;
/// [footer] ghim ở đáy, luôn thấy (bàn phím mở thì Scaffold đẩy lên trên).
class _StageLayout extends StatelessWidget {
  const _StageLayout({required this.body, required this.footer});

  final List<Widget> body;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
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
                    for (final (i, child) in body.indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.xl),
                      child,
                    ],
                  ],
                ),
              ),
            ),
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
      );
}

/// Ô chỉ xem tên (Figma "Ô hiển thị tên (chỉ xem, không nhập)").
class _NameBox extends StatelessWidget {
  const _NameBox({required this.label, required this.name});
  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $name',
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldLabel(label, icon: AppIcons.user),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: AppRadius.mdAll,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.md),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

/// Figma `1:58` – "Bác là Lan, đúng không?".
class _ConfirmName extends ConsumerWidget {
  const _ConfirmName({required this.data});
  final OnboardingData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(onboardingViewModelProvider.notifier);
    return _StageLayout(
      body: [
        _Heading('Bác là ${data.name}, đúng không?'),
        _NameBox(label: 'Tên của Bác', name: data.name),
        const _Caption('Tên này lấy từ tài khoản Google của Bác.'),
      ],
      footer: [
        AppButton(
          label: 'Nhập lại tên',
          icon: AppIcons.pencil,
          kind: AppButtonKind.secondary,
          onPressed: vm.editName,
        ),
        AppButton(
          label: 'Đúng rồi',
          icon: AppIcons.check,
          onPressed: vm.confirmName,
        ),
      ],
    );
  }
}

/// Figma `1:176` – "Bác tên là gì?" (+ lỗi tên trống / quá dài).
class _EnterName extends ConsumerWidget {
  const _EnterName({required this.data, required this.controller});
  final OnboardingData data;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(onboardingViewModelProvider.notifier);
    return _StageLayout(
      body: [
        const _Heading('Bác tên là gì?'),
        AppTextField(
          label: 'Tên gọi',
          icon: AppIcons.user,
          controller: controller,
          errorText: data.nameError,
          hint: 'Lan, Sáu, Tư',
          onChanged: vm.setName,
          autofillHints: const [AutofillHints.givenName],
          textInputAction: TextInputAction.done,
        ),
        const _Caption('Bác gõ tên, hoặc nhờ con cháu giúp.'),
      ],
      footer: [
        AppButton(
          label: 'Tiếp tục',
          icon: AppIcons.arrowRight,
          onPressed: () {
            vm.setName(controller.text);
            vm.submitName();
          },
        ),
      ],
    );
  }
}

/// Figma `1:103` – "Giới thiệu về Bác": tên, cách gọi, giờ thức dậy.
class _Details extends ConsumerWidget {
  const _Details({required this.data, required this.onSubmit});
  final OnboardingData data;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(onboardingViewModelProvider.notifier);
    final failed = data.saveError != null;
    return _StageLayout(
      body: [
        const _Heading('Giới thiệu về Bác'),
        _NameBox(label: 'Bác là', name: data.name),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const FieldLabel('Bác muốn được gọi là', icon: Icons.favorite_border),
          const SizedBox(height: AppSpacing.md),
          ChoiceGroup<Honorific>(
            layout: ChoiceLayout.segmented,
            value: data.honorific,
            onChanged: vm.setHonorific,
            options: [
              for (final h in Honorific.values)
                ChoiceOption(value: h, label: h.label),
            ],
          ),
        ]),
        TimeField(
          label: 'Bác thức dậy lúc',
          icon: Icons.alarm,
          value: data.wakeTime,
          dialogTitle: 'Bác thường thức dậy lúc mấy giờ?',
          dialogIcon: Icons.alarm,
          onChanged: vm.setWakeTime,
        ),
      ],
      footer: [
        if (failed) FieldMessage.error(data.saveError!),
        AppButton(
          label: failed ? 'Thử lại' : 'Tiếp tục',
          icon: failed ? AppIcons.retry : AppIcons.arrowRight,
          busy: data.saving,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
