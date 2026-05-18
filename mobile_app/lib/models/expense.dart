class Expense {
  final int id;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
        category: json['category'] ?? '',
        date: DateTime.parse(json['date']),
        note: json['note'],
      );
}
