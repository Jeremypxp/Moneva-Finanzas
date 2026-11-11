import 'movement_type.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorValue,
    required this.sortOrder,
    required this.isDefault,
  });

  final int id;
  final String name;
  final MovementType type;

  /// Clave del icono, resuelta en la capa de presentación.
  final String icon;
  final int colorValue;
  final int sortOrder;
  final bool isDefault;
}
