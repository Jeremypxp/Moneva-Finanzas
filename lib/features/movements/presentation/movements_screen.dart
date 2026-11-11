import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';
import '../../../core/formatting/dates.dart';
import '../../../core/formatting/money.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../categories/application/categories_providers.dart';
import '../application/movement_csv_exporter.dart';
import '../application/movements_providers.dart';
import '../domain/movement.dart';
import 'widgets/movement_filter_sheet.dart';
import 'widgets/movement_tile.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  final _scrollController = ScrollController();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 260) {
      return;
    }
    final history = ref.read(movementHistoryProvider).asData?.value;
    if (history == null || !history.hasMore || history.isLoadingMore) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    try {
      await ref.read(movementHistoryProvider.notifier).loadMore();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('No se pudieron cargar más movimientos.');
    }
  }

  Future<void> _exportCsv() async {
    if (_exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final exporter = MovementCsvExporter(
        ref.read(movementsRepositoryProvider),
      );
      final result = await exporter.export(ref.read(movementFilterProvider));
      if (!mounted) {
        return;
      }
      _showMessage(
        result.shareResult.status == ShareResultStatus.dismissed
            ? 'CSV generado con ${result.rowCount} movimientos. Puedes volver a compartirlo cuando quieras.'
            : 'CSV listo con ${result.rowCount} movimientos.',
      );
    } on NoMovementsToExportException {
      if (mounted) {
        _showMessage('No hay movimientos para exportar con estos filtros.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo exportar el CSV. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _confirmDelete(MovementWithCategory item) async {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Eliminar movimiento?'),
          content: Text(
            '${item.category.name} · ${Money.format(item.movement.amountCents)}\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: colors.expense),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(movementsRepositoryProvider).delete(item.movement.id);
      invalidateFinancialData(ref);
      if (mounted) {
        _showMessage('Movimiento eliminado.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo eliminar el movimiento.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(movementHistoryProvider);
    final filter = ref.watch(movementFilterProvider);
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    Category? filterCategory;
    for (final category in categories) {
      if (category.id == filter.categoryId) {
        filterCategory = category;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: _exporting ? null : _exportCsv,
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: _FilterBar(
              filter: filter,
              category: filterCategory,
              onTap: () => showMovementFilterSheet(context, ref),
              onClear:
                  filter.type != null ||
                      filter.categoryId != null ||
                      filter.preset != MovementPeriodPreset.currentMonth
                  ? () => ref.read(movementFilterProvider.notifier).clear()
                  : null,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _exporting
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
          Expanded(
            child: history.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              error: (error, stack) => AppErrorView(
                message: 'Hubo un problema al leer el historial local.',
                onRetry: () =>
                    ref.read(movementHistoryProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(movementHistoryProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                      children: [
                        AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Sin movimientos en este periodo',
                          message: 'Prueba con otro periodo o registra tu primer gasto o ingreso.',
                          actionLabel: 'Registrar movimiento',
                          onAction: () => context.push('/movimiento/nuevo'),
                        ),
                      ],
                    ),
                  );
                }

                final groups = _groupByDay(state.items);
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(movementHistoryProvider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: groups.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= groups.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _loadMore,
                                    child: const Text('Cargar más'),
                                  ),
                          ),
                        );
                      }
                      final group = groups[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DayGroup(
                          day: group.day,
                          items: group.items,
                          onEdit: (item) =>
                              context.push('/movimiento/${item.movement.id}'),
                          onDelete: _confirmDelete,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<({DateTime day, List<MovementWithCategory> items})> _groupByDay(
    List<MovementWithCategory> items,
  ) {
    final groups = <({DateTime day, List<MovementWithCategory> items})>[];
    for (final item in items) {
      final day = AppDates.dateOnly(item.movement.occurredOn);
      if (groups.isEmpty || groups.last.day != day) {
        groups.add((day: day, items: [item]));
      } else {
        groups.last.items.add(item);
      }
    }
    return groups;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.category,
    required this.onTap,
    this.onClear,
  });

  final MovementFilter filter;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = filter.type == null
        ? 'Todos'
        : filter.type == MovementType.expense
        ? 'Gastos'
        : 'Ingresos';
    final parts = <String>[filter.rangeLabel, typeLabel];
    if (category != null) {
      parts.add(category!.name);
    }

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      parts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Quitar filtros',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 19),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime day;
  final List<MovementWithCategory> items;
  final ValueChanged<MovementWithCategory> onEdit;
  final ValueChanged<MovementWithCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
          child: Row(
            children: [
              Text(
                AppDates.historyDayLabel(day),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outlineVariant,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  MovementTile(
                    item: items[index],
                    onTap: () => onEdit(items[index]),
                    onDelete: () => onDelete(items[index]),
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
