import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';
import '../../../core/formatting/dates.dart';
import '../../../core/formatting/money.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../categories/application/categories_providers.dart';
import '../application/movements_providers.dart';
import '../domain/movement.dart';

class MovementFormScreen extends ConsumerStatefulWidget {
  const MovementFormScreen({this.movementId, super.key});

  final int? movementId;

  @override
  ConsumerState<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends ConsumerState<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();

  MovementType _type = MovementType.expense;
  int? _categoryId;
  DateTime _date = AppDates.today();
  bool _loading = false;
  bool _notFound = false;
  bool _saving = false;
  bool _deleting = false;
  bool _categoryError = false;
  Object? _loadError;

  bool get _isEditing => widget.movementId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loading = true;
      _loadMovement();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMovement() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final movement = await ref
          .read(movementsRepositoryProvider)
          .findById(widget.movementId!);
      if (!mounted) {
        return;
      }
      if (movement == null) {
        setState(() {
          _loading = false;
          _notFound = true;
        });
        return;
      }
      setState(() {
        _type = movement.type;
        _categoryId = movement.categoryId;
        _date = movement.occurredOn;
        _amountController.text = _editableAmount(movement.amountCents);
        _noteController.text = movement.note ?? '';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'PE'),
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: AppDates.today(),
      helpText: 'Fecha del movimiento',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (picked != null && mounted) {
      setState(() => _date = AppDates.dateOnly(picked));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    final categoryValid = _categoryId != null;
    if (!categoryValid) {
      setState(() => _categoryError = true);
    }
    if (!formValid || !categoryValid) {
      return;
    }

    final cents = Money.parseToCents(_amountController.text);
    if (cents == null) {
      return;
    }

    setState(() => _saving = true);
    final draft = MovementDraft(
      type: _type,
      amountCents: cents,
      categoryId: _categoryId!,
      occurredOn: _date,
      note: _noteController.text,
    );

    try {
      final repository = ref.read(movementsRepositoryProvider);
      if (_isEditing) {
        await repository.update(widget.movementId!, draft);
      } else {
        await repository.create(draft);
      }
      invalidateFinancialData(ref);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Movimiento actualizado.' : 'Movimiento guardado.',
            ),
          ),
        );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error is ArgumentError
                  ? '${error.message}'
                  : 'No se pudo guardar el movimiento. Inténtalo de nuevo.',
            ),
          ),
        );
    }
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).extension<FinanceColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Eliminar movimiento?'),
          content: const Text('Esta acción no se puede deshacer.'),
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

    setState(() => _deleting = true);
    try {
      await ref.read(movementsRepositoryProvider).delete(widget.movementId!);
      invalidateFinancialData(ref);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Movimiento eliminado.')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el movimiento.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = (categoriesAsync.asData?.value ?? const <Category>[])
        .where((category) => category.type == _type)
        .toList();
    final busy = _saving || _deleting;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar movimiento' : 'Nuevo movimiento'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar movimiento')),
        body: AppErrorView(
          message: 'No se pudo cargar este movimiento desde el almacenamiento local.',
          onRetry: _loadMovement,
        ),
      );
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movimiento')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded, size: 44),
                const SizedBox(height: 14),
                Text(
                  'Este movimiento ya no existe.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar movimiento' : 'Nuevo movimiento'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Eliminar movimiento',
              onPressed: busy ? null : _delete,
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              _isEditing
                  ? 'Ajusta los datos y guarda los cambios.'
                  : 'Completa lo esencial. Puedes editar el resto después.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.expense,
                  label: Text('Gasto'),
                  icon: Icon(Icons.south_west_rounded),
                ),
                ButtonSegment(
                  value: MovementType.income,
                  label: Text('Ingreso'),
                  icon: Icon(Icons.north_east_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: busy
                  ? null
                  : (selection) {
                      setState(() {
                        _type = selection.first;
                        _categoryId = null;
                        _categoryError = false;
                      });
                    },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _type == MovementType.expense
                    ? const Color(0xFFFBE7E1)
                    : const Color(0xFFE0F2EA),
                selectedForegroundColor: _type == MovementType.expense
                    ? const Color(0xFFC8543A)
                    : const Color(0xFF16805F),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
            const SizedBox(height: 22),
            _FieldLabel(label: 'Importe', hint: 'Obligatorio'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocus,
              autofocus: !_isEditing,
              enabled: !busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'S/  ',
                prefixStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                final cents = Money.parseToCents(value ?? '');
                if (cents == null) {
                  return 'Ingresa un importe válido mayor a S/ 0.00.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _FieldLabel(
              label: 'Categoría',
              hint: 'Obligatoria',
              actionLabel: 'Gestionar',
              onAction: busy ? null : () => context.push('/categorias'),
            ),
            const SizedBox(height: 10),
            if (categoriesAsync.isLoading && categoriesAsync.hasValue == false)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (categories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'No hay categorías de ${_type == MovementType.expense ? 'gasto' : 'ingreso'}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/categorias'),
                      child: const Text('Crear categoría'),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    _CategoryChoice(
                      category: category,
                      selected: _categoryId == category.id,
                      onTap: busy
                          ? null
                          : () {
                              setState(() {
                                _categoryId = category.id;
                                _categoryError = false;
                              });
                            },
                    ),
                ],
              ),
            if (_categoryError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Selecciona una categoría.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (categoriesAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'No se pudieron cargar las categorías.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Fecha', hint: 'Editable'),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: busy ? null : _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 19,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          DateFormat(
                            "EEEE, d 'de' MMMM 'de' yyyy",
                            'es_PE',
                          ).format(_date),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Nota', hint: 'Opcional'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              enabled: !busy,
              maxLength: 280,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Almuerzo con el equipo',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: FilledButton.icon(
            onPressed: busy ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _saving
                  ? 'Guardando…'
                  : _isEditing
                  ? 'Guardar cambios'
                  : 'Guardar movimiento',
            ),
          ),
        ),
      ),
    );
  }

  String _editableAmount(int cents) {
    final whole = cents ~/ 100;
    final decimals = (cents % 100).toString().padLeft(2, '0');
    return '$whole.$decimals';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(width: 8),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryAvatar(category: category, size: 28),
              const SizedBox(width: 7),
              Text(
                category.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
