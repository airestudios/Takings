class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.amountMinor,
    required this.spentAt,
    required this.category,
    this.notes = '',
    this.recurringMonthly = false,
  });

  final String id;
  final String description;
  final int amountMinor;
  final DateTime spentAt;
  final String category;
  final String notes;
  final bool recurringMonthly;
}
