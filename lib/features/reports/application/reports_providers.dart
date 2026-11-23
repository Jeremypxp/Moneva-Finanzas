import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../domain/report_data.dart';

final reportPeriodProvider =
    NotifierProvider<ReportPeriodController, ReportPeriod>(
      ReportPeriodController.new,
    );

class ReportPeriodController extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.thisMonth;

  void select(ReportPeriod period) => state = period;
}

final reportProvider = AsyncNotifierProvider<ReportController, ReportData>(
  ReportController.new,
);

class ReportController extends AsyncNotifier<ReportData> {
  @override
  Future<ReportData> build() {
    final period = ref.watch(reportPeriodProvider);
    final range = period.rangeFor(DateTime.now());
    return ref
        .watch(reportsRepositoryProvider)
        .fetchReport(start: range.start, endExclusive: range.endExclusive);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado de la notificación semanal.
class _WeeklyNotificationSettings {
  bool enabled = false;
  int hour = 18;
}

final weeklyNotificationSettingsProvider =
    Provider<_WeeklyNotificationSettings>((ref) => _WeeklyNotificationSettings());

/// Reporte de la semana anterior, usado para comparaciones en los insights.
final previousWeekReportProvider =
    AsyncNotifierProvider<PreviousWeekReportController, ReportData?>(
  PreviousWeekReportController.new,
);

class PreviousWeekReportController
    extends AsyncNotifier<ReportData?> {
  @override
  Future<ReportData?> build() async {
    final now = DateTime.now();
    final currentWeek = ReportPeriod.thisWeek.rangeFor(now);
    final startOfCurrent = currentWeek.start;

    // Semana anterior: 7 días antes del inicio de la semana actual.
    final previousStart = startOfCurrent.subtract(const Duration(days: 7));
    final previousEnd = startOfCurrent;

    final data = await ref
        .watch(reportsRepositoryProvider)
        .fetchReport(start: previousStart, endExclusive: previousEnd);
    return data.isEmpty ? null : data;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
