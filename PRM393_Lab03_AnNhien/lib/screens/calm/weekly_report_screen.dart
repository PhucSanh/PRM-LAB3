import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/weekly_report_view_model.dart';
import '../../viewmodels/calm_feature_providers.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/form_parts.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyReportViewModelProvider);
    final date = ref.watch(calendarDateProvider);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return PopScope(
        canPop: !state.busy,
        child: Scaffold(
            appBar:
                AppBackBar.adaptive(context, onBack: state.busy ? () {} : null),
            body: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    children: [
                  const CalmPageHeader(
                      title: 'Lưu lịch tuần', art: true, actions: false),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                      'Từ ${monday.day}/${monday.month}/${monday.year} đến ${sunday.day}/${sunday.month}/${sunday.year}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.base),
                  const Text(
                      'PDF gồm các việc và trạng thái trong tuần đang xem. Bác chọn nơi lưu tệp ở bước tiếp theo.'),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.busy) ...[
                    LinearProgressIndicator(value: state.progress),
                    const SizedBox(height: AppSpacing.base)
                  ],
                  AppButton(
                      label: 'Tạo và lưu PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      busy: state.busy,
                      onPressed: () => ref
                          .read(weeklyReportViewModelProvider.notifier)
                          .export()),
                  const SizedBox(height: AppSpacing.base),
                  if (state.message != null) Text(state.message!),
                  if (state.error != null) FieldMessage.error(state.error!),
                ]))));
  }
}
