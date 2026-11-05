import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_item.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/display_settings.dart';
import '../../theme/app_theme.dart';
import '../app_back_bar.dart';
import '../botanical_scene.dart';
import '../velora_parts.dart';
import '../app_button.dart';
import '../app_text_field.dart';
import '../choice_group.dart';
import '../confirm_dialog.dart';
import '../form_parts.dart';
import '../habit_widgets.dart';
import '../icon_circle.dart';
import '../read_aloud_button.dart';
import '../state_views.dart';
import '../suggestion_card.dart';
import '../switch_row.dart';
import '../task_widgets.dart';
import '../time_field.dart';
import '../undo_snackbar.dart';

/// Trang xem thử mọi widget F0 với dữ liệu mẫu (chỉ ở bản debug, route `/dev/widgets`).
/// Hàng trên cùng đổi cỡ chữ (Vừa / Lớn / Rất lớn qua `fontScaleProvider`, "×2.0" chỉ trong trang này để thử trần
/// chữ hệ thống) và bật tương phản cao (`highContrastProvider`). Không dùng dữ liệu thật, không gọi service.
class WidgetGallery extends ConsumerStatefulWidget {
  const WidgetGallery({super.key, this.animate = true});

  /// `false` tắt mọi hoạt ảnh (vòng xoay chạy mãi) để test `pumpAndSettle` được.
  final bool animate;

  @override
  ConsumerState<WidgetGallery> createState() => _WidgetGalleryState();
}

/// Nhãn tiếng Việt cho 6 kiểu nút (R-LANG-01: không để chữ tiếng Anh trên giao diện, kể cả trang thử).
const _buttonKinds = [
  (AppButtonKind.primary, 'Nút chính'),
  (AppButtonKind.secondary, 'Nút viền'),
  (AppButtonKind.tonal, 'Nút nền nhạt'),
  (AppButtonKind.text, 'Nút chữ'),
  (AppButtonKind.danger, 'Xóa (nền đỏ)'),
  (AppButtonKind.dangerOutline, 'Xóa (viền đỏ)'),
];

class _WidgetGalleryState extends ConsumerState<WidgetGallery> {
  final _name = TextEditingController();
  String? _nameError;
  TimeOfDay? _time = const TimeOfDay(hour: 6, minute: 0);
  bool _vibrate = true;
  String _relation = 'con';
  String _honorific = 'ba';
  bool _speaking = false;
  bool _max = false; // xem thử ×2.0

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _showDone() => showConfirmDialog<bool>(
        context,
        icon: AppIcons.checkCircle,
        title: 'Bác đã đi bộ xong chưa?',
        details: const [ConfirmDetail(icon: AppIcons.clock, text: '9:30 sáng')],
        options: const [
          ConfirmOption(
              label: 'Đúng, đã xong',
              icon: AppIcons.checkCircle,
              value: true,
              kind: AppButtonKind.primary),
          ConfirmOption(label: 'Chưa, để sau', icon: AppIcons.x, value: false),
        ],
      );

  void _showDelete() => showConfirmDialog<bool>(
        context,
        icon: Icons.delete_outline_rounded,
        danger: true,
        title: 'Xóa việc “Đi bộ quanh công viên”?',
        message: 'Chỉ thay đổi lần này. Những ngày khác giữ nguyên.',
        options: const [
          ConfirmOption(
              label: 'Không xóa, giữ lại',
              icon: AppIcons.check,
              value: false,
              kind: AppButtonKind.primary),
          ConfirmOption(
              label: 'Xóa khỏi lịch',
              icon: Icons.delete_outline_rounded,
              value: true,
              kind: AppButtonKind.danger),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(fontScaleProvider);
    final highContrast = ref.watch(highContrastProvider);
    final media = MediaQuery.of(context);

    final body =
        ListView(padding: const EdgeInsets.all(AppSpacing.screen), children: [
      _Section('Phong cách VELORA v2', [
        const BotanicalScene(height: 260, welcome: true),
        VeloraFeaturedCard(
            eyebrow: 'THƯ VIỆN THÓI QUEN',
            title: 'Một nhịp sống an nhiên',
            label: 'Xem thói quen',
            onPressed: () => context.push('/activities?section=habits')),
        const BotanicalScene(height: 240, round: true, branch: false),
      ]),
      _Section('Chữ rõ · TYPE-01 v1.1.0', [
        for (final caregiver in [false, true])
          Theme(
            data: highContrast
                ? AppTheme.highContrast(caregiver: caregiver)
                : AppTheme.light(caregiver: caregiver),
            child: Builder(builder: (context) {
              final text = Theme.of(context).textTheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(caregiver ? 'Người thân' : 'Người cao tuổi',
                      style: text.headlineMedium),
                  Text('Đi bộ cùng gia đình', style: text.titleMedium),
                  Text('Giữ nhịp sinh hoạt mỗi ngày.', style: text.bodyLarge),
                  Text('Nội dung hướng dẫn và lỗi cần đọc rõ.',
                      style: text.bodyMedium),
                  Text('Thông tin phụ', style: text.bodySmall),
                  const AppTextField(
                      label: 'Tên hoạt động',
                      hint: 'Đi bộ nhẹ nhàng',
                      errorText: 'Vui lòng nhập tên hoạt động.'),
                  AppButton(
                      label: 'Lưu hoạt động cùng gia đình',
                      icon: AppIcons.save,
                      onPressed: () {}),
                ],
              );
            }),
          ),
      ]),
      _Section('Nút (AppButton)', [
        for (final (kind, label) in _buttonKinds)
          AppButton(
              label: label, icon: AppIcons.save, kind: kind, onPressed: () {}),
        AppButton(
            label: 'Đang lưu',
            icon: AppIcons.save,
            busy: true,
            onPressed: () {}),
        const AppButton(
            label: 'Chưa bấm được', icon: AppIcons.lock, onPressed: null),
      ]),
      _Section('Thanh trên (AppBackBar)', [
        _BarPreview(AppBackBar.adaptive(
          context,
        )),
        _BarPreview(AppBackBar.adaptive(context, step: 'Bước 1/2')),
        _BarPreview(AppBackBar.adaptive(context,
            backLabel: 'Hôm nay',
            trailing: AppBarEditButton(onPressed: () {}))),
        Text('Bottom nav (AppShell): xem ở 4 tab của app.',
            style: Theme.of(context).textTheme.bodyMedium),
      ]),
      _Section('Hộp thoại · Snackbar', [
        AppButton(
            label: 'Mở hộp Đã xong',
            icon: AppIcons.view,
            kind: AppButtonKind.secondary,
            onPressed: _showDone),
        AppButton(
            label: 'Mở hộp Xóa việc',
            icon: AppIcons.view,
            kind: AppButtonKind.secondary,
            onPressed: _showDelete),
        AppButton(
          label: 'Mở hộp chọn giờ',
          icon: AppIcons.clock,
          kind: AppButtonKind.secondary,
          onPressed: () => showTimeWheel(context, initial: _time),
        ),
        AppButton(
          label: 'Hiện Hoàn tác',
          icon: AppIcons.view,
          kind: AppButtonKind.secondary,
          onPressed: () => showUndoSnackbar(context,
              title: 'Đã ghi: Đi bộ xong lúc 9:42 sáng.', onUndo: () {}),
        ),
        const Center(child: IconCircle(icon: AppIcons.checkCircle)),
      ]),
      _Section('Trạng thái (Loading / Empty / Error)', [
        const _StatePreview(LoadingView(
            message: 'Đang lưu việc…', hint: 'Không cần bấm gì thêm')),
        _StatePreview(EmptyView(
          icon: Icons.event_available_rounded,
          title: 'Hôm nay chưa có việc nào',
          message: 'Bắt đầu nhẹ nhàng với một việc nhỏ.',
          action: AppButton(
              label: 'Thêm việc đầu tiên',
              icon: Icons.add_rounded,
              onPressed: () {}),
        )),
        _StatePreview(ErrorView(
          title: 'Chưa lưu được',
          message: 'Chưa thể lưu trên điện thoại.',
          detail: 'Nội dung đang nhập vẫn được giữ lại.',
          onRetry: () {},
        )),
      ]),
      _Section('Form', [
        AppTextField(
          label: 'Tên việc',
          icon: AppIcons.pencil,
          hint: 'Đi bộ buổi sáng',
          controller: _name,
          errorText: _nameError,
          onChanged: (_) => setState(() => _nameError = null),
        ),
        AppButton(
          label: 'Thử báo lỗi',
          icon: AppIcons.alert,
          kind: AppButtonKind.text,
          onPressed: () =>
              setState(() => _nameError = 'Bác chưa nhập tên việc.'),
        ),
        TimeField(
            label: 'Bác thức dậy lúc',
            value: _time,
            onChanged: (t) => setState(() => _time = t)),
        SwitchRow(
          title: 'Rung khi có lời nhắc',
          subtitle: 'Kèm tiếng chuông',
          icon: AppIcons.bell,
          value: _vibrate,
          onChanged: (v) => setState(() => _vibrate = v),
        ),
        const FieldLabel('Bác muốn được gọi là'),
        ChoiceGroup<String>(
          layout: ChoiceLayout.segmented,
          value: _honorific,
          onChanged: (v) => setState(() => _honorific = v),
          options: const [
            ChoiceOption(value: 'ong', label: 'Ông'),
            ChoiceOption(value: 'ba', label: 'Bà')
          ],
        ),
        const FieldLabel('Là gì của Bác?'),
        ChoiceGroup<String>(
          value: _relation,
          onChanged: (v) => setState(() => _relation = v),
          options: const [
            ChoiceOption(value: 'con', label: 'Con'),
            ChoiceOption(value: 'chau', label: 'Cháu'),
            ChoiceOption(
                value: 'khac', label: 'Khác', description: 'Bạn bè, hàng xóm'),
          ],
        ),
      ]),
      _Section('Nội dung', [
        SuggestionCard(
          fromName: 'Mai',
          itemCount: 2,
          previewTitles: const ['Đi bộ với cô Tám', 'Gọi điện cho Mai'],
          onOpen: () {},
          onDismiss: () {},
        ),
        NextTaskCard(
          time: const TimeOfDay(hour: 9, minute: 30),
          title: 'Đi bộ quanh công viên',
          habitKey: 'move',
          durationMinutes: 20,
          onDone: () {},
          onLater: () {},
          onSkip: () {},
          onTap: () {},
        ),
        for (final (i, status) in TaskStatus.values.indexed)
          TaskRow(
            time: TimeOfDay(hour: 6 + 3 * i, minute: i.isOdd ? 30 : 0),
            title: 'Việc mẫu ${i + 1}',
            habitKey: const ['tea', 'move', 'downshift', 'family'][i],
            status: status,
            onTap: () {},
          ),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          for (final k in const [
            'move',
            'purpose',
            'downshift',
            'eighty',
            'plant',
            'tea',
            'belong',
            'family',
            'tribe'
          ])
            HabitBadge(habitKey: k),
        ]),
        HabitTile(
            habitKey: 'plant',
            description: HabitStyle.descriptionOf('plant'),
            onTap: () {}),
        HabitTile(
            habitKey: 'move',
            name: 'Đi bộ nhẹ nhàng',
            selected: true,
            onTap: () {}),
        ReadAloudButton(
            speaking: _speaking,
            onPressed: () => setState(() => _speaking = !_speaking)),
      ]),
    ]);

    return Scaffold(
      // Mở thẳng trang này (không có màn trước) thì "Quay lại" về Hôm nay.
      appBar: AppBackBar.adaptive(context,
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/today')),
      body: Column(children: [
        _DisplayBar(
          fontScale: fontScale,
          max: _max,
          highContrast: highContrast,
          onScale: (s) {
            setState(() => _max = false);
            ref.read(fontScaleProvider.notifier).set(s);
          },
          onMax: () => setState(() => _max = true),
          onContrast: (v) => ref.read(highContrastProvider.notifier).set(v),
        ),
        Expanded(
          child: TickerMode(
            enabled: widget.animate,
            child: _max
                ? MediaQuery(
                    data: media.copyWith(
                        textScaler: const TextScaler.linear(maxTextScale)),
                    child: body)
                : body,
          ),
        ),
      ]),
    );
  }
}

/// Hàng đổi cỡ chữ + tương phản. Cỡ chữ của chính hàng này giữ ×1.0 để luôn bấm được.
class _DisplayBar extends StatelessWidget {
  const _DisplayBar({
    required this.fontScale,
    required this.max,
    required this.highContrast,
    required this.onScale,
    required this.onMax,
    required this.onContrast,
  });

  final AppFontScale fontScale;
  final bool max;
  final bool highContrast;
  final ValueChanged<AppFontScale> onScale;
  final VoidCallback onMax;
  final ValueChanged<bool> onContrast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery.withNoTextScaling(
      child: Material(
        color: scheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              for (final s in AppFontScale.values)
                ChoiceChip(
                  label: Text('${s.label} ×${s.factor}'),
                  selected: !max && fontScale == s,
                  onSelected: (_) => onScale(s),
                ),
              ChoiceChip(
                  label: const Text('×$maxTextScale'),
                  selected: max,
                  onSelected: (_) => onMax()),
            ]),
            SwitchRow(
                title: 'Tương phản cao',
                value: highContrast,
                onChanged: onContrast),
          ]),
        ),
      ),
    );
  }
}

/// Một nhóm widget: tiêu đề + các widget cách nhau 20 dp.
class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
            header: true,
            child:
                Text(title, style: Theme.of(context).textTheme.headlineSmall)),
        for (final child in children) ...[
          const SizedBox(height: AppSpacing.betweenTargets),
          child
        ],
      ]),
    );
  }
}

/// AppBar đặt giữa trang (cao đúng `preferredSize`).
class _BarPreview extends StatelessWidget {
  const _BarPreview(this.bar);

  final PreferredSizeWidget bar;

  @override
  Widget build(BuildContext context) {
    final preview =
        bar is AppBackBar ? (bar as AppBackBar).adapt(context) : bar;
    return DecoratedBox(
      decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: SizedBox(height: preview.preferredSize.height, child: preview),
    );
  }
}

/// Màn trạng thái đặt trong khung có viền (các view này tự căn giữa + cuộn nên cần chiều cao cố định).
class _StatePreview extends StatelessWidget {
  const _StatePreview(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppRadius.cardAll,
      ),
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6, child: child),
    );
  }
}
