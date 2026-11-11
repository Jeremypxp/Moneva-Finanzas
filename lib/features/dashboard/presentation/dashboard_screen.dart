import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/domain/period_totals.dart';
import '../../../core/formatting/dates.dart';
import '../../../core/formatting/money.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../movements/application/movements_providers.dart';
import '../../movements/domain/movement.dart';
import '../../movements/presentation/widgets/movement_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(weeklyTotalsProvider);
    final recent = ref.watch(recentMovementsProvider);
    final range = ref.watch(weekRangeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weeklyTotalsProvider);
            ref.invalidate(recentMovementsProvider);
            try {
              await Future.wait([
                ref.read(weeklyTotalsProvider.future),
                ref.read(recentMovementsProvider.future),
              ]);
            } catch (_) {
              // El estado de error se muestra dentro de la pantalla.
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: const SliverToBoxAdapter(child: _Header()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _WeekSummaryCard(totals: totals, range: range),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Últimos movimientos',
                    actionLabel: 'Ver todos',
                    onAction: () => context.go('/movimientos'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _RecentMovements(recent: recent),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 120),
                sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final date = DateFormat("EEEE, d 'de' MMMM", 'es_PE').format(today);
    final capitalized = date.isEmpty
        ? date
        : '${date[0].toUpperCase()}${date.substring(1)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINANZAS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  Text(
                    capitalized,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Tu resumen', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Todo lo importante de tu semana, de un vistazo.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WeekSummaryCard extends ConsumerWidget {
  const _WeekSummaryCard({required this.totals, required this.range});

  final AsyncValue<PeriodTotals> totals;
  final ({DateTime start, DateTime endExclusive}) range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final data = totals.asData?.value ?? PeriodTotals.empty;
    final isNegative = data.balanceCents < 0;
    final gradient = isNegative
        ? const LinearGradient(
            colors: [Color(0xFF7F3D31), Color(0xFFB95E43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [colors.heroStart, colors.heroEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.heroStart.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'SEMANA ACTUAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (totals.isLoading && !totals.hasValue)
            const SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Money.format(data.balanceCents),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            AppDates.dateRange(range.start, range.endExclusive),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isNegative
                ? 'Los gastos superan a los ingresos esta semana.'
                : data.incomeCents == 0 && data.expenseCents == 0
                ? 'Aún no hay movimientos esta semana.'
                : 'Vas dentro de tu semana.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CardMetric(
                  icon: Icons.south_west_rounded,
                  label: 'Ingresos',
                  amount: Money.format(data.incomeCents),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _CardMetric(
                  icon: Icons.north_east_rounded,
                  label: 'Gastos',
                  amount: Money.format(data.expenseCents),
                ),
              ),
            ],
          ),
          if (totals.hasError) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(weeklyTotalsProvider),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'No se pudo actualizar. Reintentar',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.67),
                  fontSize: 11,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentMovements extends ConsumerWidget {
  const _RecentMovements({required this.recent});

  final AsyncValue<List<MovementWithCategory>> recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return recent.when(
      loading: () => const SurfaceCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
      error: (error, stack) => SurfaceCard(
        child: AppErrorView(
          message: 'Revisa tu almacenamiento local e inténtalo de nuevo.',
          onRetry: () => ref.invalidate(recentMovementsProvider),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return SurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu historial está vacío',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usa el botón Nuevo para registrar tu primer gasto o ingreso.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                MovementTile(
                  item: items[index],
                  showMenu: false,
                  onTap: () =>
                      context.push('/movimiento/${items[index].movement.id}'),
                ),
                if (index < items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}
