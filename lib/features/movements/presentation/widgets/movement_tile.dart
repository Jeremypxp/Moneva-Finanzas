import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/formatting/money.dart';
import '../../../../core/widgets/category_avatar.dart';
import '../../domain/movement.dart';

class MovementTile extends StatelessWidget {
  const MovementTile({
    required this.item,
    required this.onTap,
    this.onDelete,
    this.showMenu = true,
    super.key,
  });

  final MovementWithCategory item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FinanceColors>()!;
    final movement = item.movement;
    final isExpense = movement.type.isExpense;
    final amountColor = isExpense ? colors.expense : colors.income;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            CategoryAvatar(category: item.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movement.note?.isNotEmpty == true
                        ? movement.note!
                        : movement.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              Money.formatSigned(movement.signedCents),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showMenu && onDelete != null)
              PopupMenuButton<String>(
                tooltip: 'Opciones del movimiento',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete!();
                  } else {
                    onTap();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
