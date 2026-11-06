import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import 'device_access_view_model.dart';
import 'calm_feature_providers.dart';

class WeeklyReportState {
  const WeeklyReportState(
      {this.busy = false, this.progress = 0, this.message, this.error});
  final bool busy;
  final double progress;
  final String? message, error;
}

class WeeklyReportViewModel extends Notifier<WeeklyReportState> {
  @override
  WeeklyReportState build() => const WeeklyReportState();
  Future<void> export() async {
    if (state.busy) return;
    state = const WeeklyReportState(busy: true);
    try {
      String? uri;
      await for (final progress in ref
          .read(reportServiceProvider)
          .exportWeek(ref.read(calendarDateProvider))) {
        if (!ref.mounted) return;
        uri = progress.downloadUrl ?? uri;
        state = WeeklyReportState(busy: true, progress: progress.fraction);
      }
      if (ref.mounted) {
        state = WeeklyReportState(
            message: uri == null
                ? 'Đã hủy lưu. Lịch của Bác không thay đổi.'
                : 'Đã lưu PDF tại nơi Bác chọn.');
      }
    } catch (e, st) {
      if (!ref.mounted) return;
      state = WeeklyReportState(error: deviceError(e));
      try {
        await ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'export_week');
      } catch (_) {}
    }
  }
}

final weeklyReportViewModelProvider =
    NotifierProvider.autoDispose<WeeklyReportViewModel, WeeklyReportState>(
        WeeklyReportViewModel.new);
