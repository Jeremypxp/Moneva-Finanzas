import 'package:flutter/material.dart';

import '../../core/domain/category.dart';

const categoryIconChoices = <({String key, String label, IconData icon})>[
  (key: 'restaurant', label: 'Comida', icon: Icons.restaurant_rounded),
  (key: 'transport', label: 'Transporte', icon: Icons.directions_bus_rounded),
  (key: 'pets', label: 'Mascota', icon: Icons.pets_rounded),
  (key: 'home', label: 'Hogar', icon: Icons.home_rounded),
  (key: 'health', label: 'Salud', icon: Icons.medical_services_rounded),
  (key: 'services', label: 'Servicios', icon: Icons.bolt_rounded),
  (key: 'leisure', label: 'Ocio', icon: Icons.movie_rounded),
  (key: 'education', label: 'Educación', icon: Icons.school_rounded),
  (key: 'other', label: 'Otros', icon: Icons.inventory_2_rounded),
  (key: 'salary', label: 'Sueldo', icon: Icons.work_rounded),
  (key: 'freelance', label: 'Freelance', icon: Icons.laptop_mac_rounded),
  (key: 'sales', label: 'Ventas', icon: Icons.sell_rounded),
  (key: 'gift', label: 'Regalo', icon: Icons.card_giftcard_rounded),
  (key: 'other_income', label: 'Otros ingresos', icon: Icons.savings_rounded),
];

const categoryColorChoices = <int>[
  0xFF146B5A,
  0xFF2D7F9B,
  0xFF3F6F9E,
  0xFF5D5FA8,
  0xFF8A5A9E,
  0xFFB4435B,
  0xFFB95E43,
  0xFFC18A2D,
  0xFF6E7D3A,
  0xFF4A7C79,
  0xFF747C76,
];

IconData categoryIcon(String key) {
  for (final choice in categoryIconChoices) {
    if (choice.key == key) {
      return choice.icon;
    }
  }
  return Icons.category_rounded;
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({required this.category, this.size = 44, super.key});

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(categoryIcon(category.icon), size: size * 0.5, color: color),
    );
  }
}
