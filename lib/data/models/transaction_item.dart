class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime dateTime;
  final String? note;
  final bool isExpense;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.dateTime,
    this.note,
    this.isExpense = true,
  });

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? dateTime,
    String? note,
    bool? isExpense,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'dateTime': dateTime.toIso8601String(),
      'note': note,
      'isExpense': isExpense,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      note: json['note'] as String?,
      isExpense: json['isExpense'] as bool? ?? true,
    );
  }
}
