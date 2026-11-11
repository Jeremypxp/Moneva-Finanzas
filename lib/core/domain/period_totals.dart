class PeriodTotals {
  const PeriodTotals({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;

  static const empty = PeriodTotals(incomeCents: 0, expenseCents: 0);
}
