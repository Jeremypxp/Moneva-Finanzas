import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/domain/movement_type.dart';
import '../../../core/domain/period_totals.dart';
import '../../../core/formatting/dates.dart';
import '../../reports/application/reports_providers.dart';
import '../domain/movement.dart';

final movementFilterProvider =
    NotifierProvider<MovementFilterController, MovementFilter>(
      MovementFilterController.new,
    );

class MovementFilterController extends Notifier<MovementFilter> {
  @override
  MovementFilter build() => MovementFilter.initial();

  void setPreset(MovementPeriodPreset preset) {
    final range = preset.rangeFor(DateTime.now());
    state = state.withRange(preset, range.start, range.endExclusive);
  }

  void setCustomRange(DateTime start, DateTime endExclusive) {
    state = state.withRange(MovementPeriodPreset.custom, start, endExclusive);
  }

  void setType(MovementType? type) {
    state = state.withType(type);
  }

  void setCategory(int? categoryId) {
    state = state.withCategory(categoryId);
  }

  void setFilter(MovementFilter filter) {
    state = filter;
  }

  void clear() {
    state = MovementFilter.initial();
  }
}

class MovementHistoryState {
  const MovementHistoryState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<MovementWithCategory> items;
  final bool hasMore;
  final bool isLoadingMore;

  MovementHistoryState copyWith({
    List<MovementWithCategory>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MovementHistoryState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final movementHistoryProvider =
    AsyncNotifierProvider<MovementHistoryController, MovementHistoryState>(
      MovementHistoryController.new,
    );

class MovementHistoryController extends AsyncNotifier<MovementHistoryState> {
  static const pageSize = 50;

  @override
  Future<MovementHistoryState> build() async {
    final filter = ref.watch(movementFilterProvider);
    final page = await ref
        .watch(movementsRepositoryProvider)
        .fetchPage(filter: filter, limit: pageSize, offset: 0);
    return MovementHistoryState(items: page.items, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final filter = ref.read(movementFilterProvider);
      final page = await ref
          .read(movementsRepositoryProvider)
          .fetchPage(
            filter: filter,
            limit: pageSize,
            offset: current.items.length,
          );
      if (!ref.mounted) {
        return;
      }
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(int id) async {
    await ref.read(movementsRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final weekRangeProvider = Provider<({DateTime start, DateTime endExclusive})>((
  ref,
) {
  final now = DateTime.now();
  return (
    start: AppDates.startOfWeek(now),
    endExclusive: AppDates.endOfWeekExclusive(now),
  );
});

final weeklyTotalsProvider = StreamProvider<PeriodTotals>((ref) {
  final range = ref.watch(weekRangeProvider);
  return ref
      .watch(movementsRepositoryProvider)
      .watchTotals(start: range.start, endExclusive: range.endExclusive);
});

final recentMovementsProvider = StreamProvider<List<MovementWithCategory>>((
  ref,
) {
  return ref.watch(movementsRepositoryProvider).watchRecent(limit: 5);
});

/// Invalida los datos derivados tras crear, editar o eliminar un movimiento.
void invalidateFinancialData(WidgetRef ref) {
  ref.invalidate(movementHistoryProvider);
  ref.invalidate(reportProvider);
}
