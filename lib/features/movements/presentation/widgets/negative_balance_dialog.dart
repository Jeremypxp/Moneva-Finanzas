import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/domain/balance_projection.dart';
import '../../../../core/formatting/money.dart';

/// Pide confirmación antes de registrar un gasto que deja el saldo total en
/// negativo.
///
/// Devuelve `true` solo si la persona elige explícitamente continuar. Cerrar
/// con la X, tocar fuera o pulsar «Cancelar» devuelve `false`.
Future<bool> showNegativeBalanceDialog(
  BuildContext context, {
  required PeriodProjection projection,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _NegativeBalanceDialog(projection: projection),
  );
  return confirmed ?? false;
}

class _NegativeBalanceDialog extends StatelessWidget {
  const _NegativeBalanceDialog({required this.projection});

  final PeriodProjection projection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FinanceColors>()!;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.warningSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: colors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Balance negativo',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.warningText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: Text(
        'Este gasto supera tus ingresos registrados. Si lo registras, tu '
        'saldo total quedará en '
        '${Money.format(projection.balanceCents)}. '
        'Verifica si falta registrar algún ingreso.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colors.warning,
            foregroundColor: Colors.white,
          ),
          child: const Text('Registrar gasto'),
        ),
      ],
    );
  }
}
