import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/formatting/dates.dart';
import '../../../core/formatting/money.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../application/reports_providers.dart';
import '../domain/report_data.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider);
    final period = ref.watch(reportPeriodProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar reporte',
            onPressed: () => ref.read(reportProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(reportProvider.notifier).refresh();
          } catch (_) {
            // El error se refleja en el estado del reporte.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            Text(
              'Entiende en qué se va tu dinero',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Compara tus ingresos y descubre tus categorías con más gasto.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in ReportPeriod.values) ...[
                    ChoiceChip(
                      label: Text(option.label),
                      selected: period == option,
                      onSelected: (_) => ref
                          .read(reportPeriodProvider.notifier)
                          .select(option),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            report.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              error: (error, stack) => SurfaceCard(
                child: AppErrorView(
                  message: 'No se pudo calcular el reporte.',
                  onRetry: () => ref.read(reportProvider.notifier).refresh(),
                ),
              ),
              data: (data) => _ReportContent(data: data),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  'Calculado en tu dispositivo con tus datos locales.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return SurfaceCard(
        child: AppEmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Sin datos en este periodo',
          message:
              'Registra movimientos o elige otro periodo para ver tu reporte.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppDates.dateRange(data.start, data.endExclusive),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Ingresos',
                      amount: data.incomeCents,
                      color: colors.income,
                      background: colors.incomeSoft,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(
                      label: 'Gastos',
                      amount: data.expenseCents,
                      color: colors.expense,
                      background: colors.expenseSoft,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.balanceCents >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 20,
                      color: data.balanceCents >= 0
                          ? colors.income
                          : colors.expense,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Balance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Money.format(data.balanceCents),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: data.balanceCents >= 0
                            ? colors.income
                            : colors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Gastos por categoría'),
        const SizedBox(height: 8),
        _BreakdownCard(
          items: data.expenseByCategory,
          emptyMessage: 'No registraste gastos en este periodo.',
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Ingresos por categoría'),
        const SizedBox(height: 8),
        _BreakdownCard(
          items: data.incomeByCategory,
          emptyMessage: 'No registraste ingresos en este periodo.',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.amount,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.items, required this.emptyMessage});

  final List<CategoryTotal> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return SurfaceCard(
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _BreakdownRow(item: items[index]),
            if (index < items.length - 1) const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item});

  final CategoryTotal item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(item.category.colorValue);
    final percentage = (item.share * 100).round();
    return Column(
      children: [
        Row(
          children: [
            CategoryAvatar(category: item.category, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(item.totalCents),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.share.clamp(0, 1),
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
