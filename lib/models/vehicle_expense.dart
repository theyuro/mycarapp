enum VehicleExpenseCategory {
  insurance('Seguro'),
  cooperative('Cooperativa'),
  financing('Financiamento'),
  consortium('Consórcio'),
  other('Outra despesa');

  const VehicleExpenseCategory(this.label);
  final String label;
}

enum ExpenseFrequency {
  monthly('Mensal'),
  yearly('Anual'),
  once('Pagamento único');

  const ExpenseFrequency(this.label);
  final String label;
}

class VehicleExpense {
  const VehicleExpense({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.category,
    required this.amount,
    required this.firstDueDate,
    required this.frequency,
    this.totalInstallments,
    this.notes,
    this.active = true,
  });

  final String id;
  final String vehicleId;
  final String title;
  final VehicleExpenseCategory category;
  final double amount;
  final DateTime firstDueDate;
  final ExpenseFrequency frequency;
  final int? totalInstallments;
  final String? notes;
  final bool active;

  bool occursIn(DateTime month) {
    if (!active) return false;
    final target = DateTime(month.year, month.month);
    final start = DateTime(firstDueDate.year, firstDueDate.month);
    if (target.isBefore(start)) return false;
    final difference =
        (target.year - start.year) * 12 + target.month - start.month;
    return switch (frequency) {
      ExpenseFrequency.once => difference == 0,
      ExpenseFrequency.yearly => difference % 12 == 0,
      ExpenseFrequency.monthly =>
        totalInstallments == null || difference < totalInstallments!,
    };
  }

  int? installmentIn(DateTime month) {
    if (frequency != ExpenseFrequency.monthly || !occursIn(month)) return null;
    final difference =
        (month.year - firstDueDate.year) * 12 +
        month.month -
        firstDueDate.month;
    return difference + 1;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'title': title,
    'category': category.name,
    'amount': amount,
    'firstDueDate': firstDueDate.toIso8601String(),
    'frequency': frequency.name,
    if (totalInstallments != null) 'totalInstallments': totalInstallments,
    if (notes != null) 'notes': notes,
    'active': active,
  };

  factory VehicleExpense.fromJson(Map<String, dynamic> json) => VehicleExpense(
    id: json['id'] as String,
    vehicleId: json['vehicleId'] as String,
    title: json['title'] as String,
    category: VehicleExpenseCategory.values.byName(json['category'] as String),
    amount: (json['amount'] as num).toDouble(),
    firstDueDate: DateTime.parse(json['firstDueDate'] as String),
    frequency: ExpenseFrequency.values.byName(json['frequency'] as String),
    totalInstallments: (json['totalInstallments'] as num?)?.toInt(),
    notes: json['notes'] as String?,
    active: json['active'] as bool? ?? true,
  );
}
