import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/category_avatar.dart';
import '../application/categories_providers.dart';
import '../data/categories_repository.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categorías'),
          bottom: categoriesAsync.when(
            loading: () => null,
            error: (_, __) => null,
            data: (categories) => TabBar(
              controller: DefaultTabController.of(context),
              tabs: [
                Tab(
                  text: 'Gastos (${categories.where((category) => category.type == MovementType.expense).length})',
                ),
                Tab(
                  text: 'Ingresos (${categories.where((category) => category.type == MovementType.income).length})',
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddSheet(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva categoría'),
        ),
        body: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AppErrorView(
            message: 'No se pudieron leer las categorías locales.',
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
          data: (categories) {
            final expense = categories
                .where((category) => category.type == MovementType.expense)
                .toList();
            final income = categories
                .where((category) => category.type == MovementType.income)
                .toList();
            return TabBarView(
              controller: DefaultTabController.of(context),
              children: [
                _CategoryList(
                  categories: expense,
                  onDelete: (cat) => _delete(context, ref, cat),
                  onAdd: () => _openAddSheet(context, ref),
                  emptyTitle: 'Sin categorías de gasto',
                  ref: ref,
                ),
                _CategoryList(
                  categories: income,
                  onDelete: (cat) => _delete(context, ref, cat),
                  onAdd: () => _openAddSheet(context, ref),
                  emptyTitle: 'Sin categorías de ingreso',
                  ref: ref,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddCategorySheet(initialType: MovementType.expense),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Categoría creada.')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category category) async {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Se eliminará “${category.name}”. Solo es posible si no tiene '
          'movimientos asociados.',
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
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(categoriesRepositoryProvider).delete(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Categoría eliminada.')));
      }
    } on CategoryInUseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar la categoría.')),
          );
      }
    }
  }
}

Widget _buildCategoryTile(
  BuildContext context,
  WidgetRef ref,
  ThemeData theme,
  FinanceColors colors,
  Category cat,
  ValueChanged<Category> onDelete,
) {
  return ListTile(
    leading: CategoryAvatar(category: cat),
    title: Text(cat.name),
    subtitle: Text(
      cat.isDefault
          ? 'Categoría inicial'
          : 'Categoría personalizada',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    trailing: Wrap(
      spacing: 6,
      children: [
        if (cat.isNecessary)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.expense.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.expense.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Necesaria',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.expense,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        IconButton(
          tooltip: cat.isNecessary
              ? 'Marcar como no necesaria'
              : 'Marcar como necesaria',
          onPressed: () {
            try {
              ref.read(categoriesRepositoryProvider).updateNecessary(cat.id, !cat.isNecessary);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      !cat.isNecessary
                          ? '“${cat.name}” marcada como necesaria.'
                          : '“${cat.name}” ya no es necesaria.',
                    ),
                  ),
                );
            } catch (_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('No se pudo actualizar la categoría.')),
                );
            }
          },
          icon: Icon(
            cat.isNecessary
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 20,
            color: cat.isNecessary
                ? colors.expense
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!cat.isDefault)
          IconButton(
            tooltip: 'Eliminar categoría',
            onPressed: () => onDelete(cat),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 21,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    ),
  );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.onDelete,
    required this.onAdd,
    required this.emptyTitle,
    required this.ref,
  });

  final List<Category> categories;
  final ValueChanged<Category> onDelete;
  final VoidCallback onAdd;
  final String emptyTitle;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FinanceColors>()!;
    if (categories.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          AppEmptyState(
            icon: Icons.category_outlined,
            title: emptyTitle,
            message: 'Agrega una categoría para clasificar tus movimientos.',
            actionLabel: 'Crear categoría',
            onAction: onAdd,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var index = 0; index < categories.length; index++) ...[
                  _buildCategoryTile(
                    context,
                    ref,
                    theme,
                    colors,
                    categories[index],
                    onDelete,
                  ),
                  if (index < categories.length - 1)
                    const Divider(height: 1, indent: 70),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'No puedes eliminar una categoría que tenga movimientos. '
            'Cámbialos de categoría primero.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet({required this.initialType});

  final MovementType initialType;

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _nameController = TextEditingController();
  late MovementType _type;
  late String _icon;
  late int _color;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _icon = _type == MovementType.expense ? 'restaurant' : 'salary';
    _color = _type == MovementType.expense ? 0xFFB95E43 : 0xFF16805F;
    _nameController.addListener(() {
      if (_error != null) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(categoriesRepositoryProvider)
          .create(name: name, type: _type, icon: _icon, colorValue: _color);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on CategoryValidationException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'No se pudo crear la categoría. Inténtalo de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Text('Nueva categoría', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.expense,
                  label: Text('Gasto'),
                ),
                ButtonSegment(
                  value: MovementType.income,
                  label: Text('Ingreso'),
                ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: _saving
                  ? null
                  : (selection) {
                      setState(() {
                        _type = selection.first;
                        _icon = _type == MovementType.expense
                            ? 'restaurant'
                            : 'salary';
                        _color = _type == MovementType.expense
                            ? 0xFFB95E43
                            : 0xFF16805F;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_saving,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Transporte al trabajo',
              ),
            ),
            const SizedBox(height: 4),
            Text('Icono', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final choice in categoryIconChoices)
                  _IconChoice(
                    icon: choice.icon,
                    label: choice.label,
                    selected: _icon == choice.key,
                    color: Color(_color),
                    onTap: _saving
                        ? null
                        : () => setState(() => _icon = choice.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final value in categoryColorChoices)
                  _ColorChoice(
                    value: value,
                    selected: _color == value,
                    onTap: _saving
                        ? null
                        : () => setState(() => _color = value),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear categoría'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : const Color(0xFFF2F4EF),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Icon(icon, size: 21, color: selected ? color : Colors.black54),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(value);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
