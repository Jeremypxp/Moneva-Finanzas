import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/category.dart';
import '../../../../core/domain/movement_type.dart';
import '../../../../core/formatting/dates.dart';
import '../../../../core/widgets/category_avatar.dart';
import '../../../categories/application/categories_providers.dart';
import '../../application/movements_providers.dart';
import '../../domain/movement.dart';

Future<void> showMovementFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _MovementFilterSheet(),
  );
}

class _MovementFilterSheet extends ConsumerStatefulWidget {
  const _MovementFilterSheet();

  @override
  ConsumerState<_MovementFilterSheet> createState() =>
      _MovementFilterSheetState();
}

class _MovementFilterSheetState extends ConsumerState<_MovementFilterSheet> {
  late MovementPeriodPreset _preset;
  late DateTime _start;
  late DateTime _endExclusive;
  MovementType? _type;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(movementFilterProvider);
    _preset = filter.preset;
    _start = filter.start;
    _endExclusive = filter.endExclusive;
    _type = filter.type;
    _categoryId = filter.categoryId;
  }

  Future<void> _selectPreset(MovementPeriodPreset preset) async {
    if (preset == MovementPeriodPreset.custom) {
      await _pickCustomRange();
      return;
    }
    final range = preset.rangeFor(DateTime.now());
    setState(() {
      _preset = preset;
      _start = range.start;
      _endExclusive = range.endExclusive;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = AppDates.today();
    final initialStart = _preset == MovementPeriodPreset.custom
        ? _start
        : DateTime(now.year, now.month, 1);
    final initialEnd = _preset == MovementPeriodPreset.custom
        ? DateTime(
            _endExclusive.year,
            _endExclusive.month,
            _endExclusive.day - 1,
          )
        : now;
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('es', 'PE'),
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(initialEnd) ? initialEnd : initialStart,
        end: initialEnd,
      ),
      helpText: 'Periodo del historial',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      fieldStartLabelText: 'Desde',
      fieldEndLabelText: 'Hasta',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _preset = MovementPeriodPreset.custom;
      _start = AppDates.dateOnly(picked.start);
      _endExclusive = AppDates.dateOnly(
        DateTime(picked.end.year, picked.end.month, picked.end.day + 1),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.asData?.value ?? const <Category>[];
    final availableCategories = _type == null
        ? categories
        : categories.where((category) => category.type == _type).toList();
    final selectedCategory = _categoryId == null
        ? null
        : categories
              .where((category) => category.id == _categoryId)
              .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtrar historial', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Elige el periodo, el tipo de movimiento y la categoría.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('Periodo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in MovementPeriodPreset.values)
                  ChoiceChip(
                    label: Text(preset.label),
                    selected: _preset == preset,
                    onSelected: (_) => _selectPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickCustomRange,
              borderRadius: BorderRadius.circular(14),
              child: Container(
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
                      Icons.date_range_rounded,
                      size: 19,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppDates.dateRange(_start, _endExclusive),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Cambiar',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tipo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _type == null,
                  onSelected: (_) => _setType(null),
                ),
                for (final type in MovementType.values)
                  ChoiceChip(
                    label: Text(
                      type == MovementType.expense ? 'Gastos' : 'Ingresos',
                    ),
                    selected: _type == type,
                    onSelected: (_) => _setType(type),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Categoría', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _categoryId,
                  isExpanded: true,
                  hint: const Text('Todas las categorías'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    for (final category in availableCategories)
                      DropdownMenuItem<int?>(
                        value: category.id,
                        child: Row(
                          children: [
                            CategoryAvatar(category: category, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                      if (value != null && _type == null) {
                        _type =
                            selectedCategory?.type ??
                            categories
                                .where((category) => category.id == value)
                                .firstOrNull
                                ?.type;
                      }
                    });
                  },
                ),
              ),
            ),
            if (categoriesAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No se pudieron cargar las categorías.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(movementFilterProvider.notifier).clear();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Restablecer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      final filter = MovementFilter(
                        preset: _preset,
                        start: _start,
                        endExclusive: _endExclusive,
                        type: _type,
                        categoryId: _categoryId,
                      );
                      ref
                          .read(movementFilterProvider.notifier)
                          .setFilter(filter);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setType(MovementType? type) {
    setState(() {
      _type = type;
      if (_categoryId != null) {
        final category = ref
            .read(categoriesProvider)
            .asData
            ?.value
            .where((category) => category.id == _categoryId)
            .firstOrNull;
        if (category != null && type != null && category.type != type) {
          _categoryId = null;
        }
      }
    });
  }
}
