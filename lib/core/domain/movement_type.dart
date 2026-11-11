enum MovementType {
  expense('expense', 'Gasto'),
  income('income', 'Ingreso');

  const MovementType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  bool get isExpense => this == MovementType.expense;

  static MovementType fromDb(String value) {
    return MovementType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => MovementType.expense,
    );
  }
}
