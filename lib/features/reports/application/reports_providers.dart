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
