import 'category_item.dart';

class TransactionItem {
  final String id;
  final String title;
  final int amount; // Whole Uzbek So'm integer minor unit
  final String categoryId;
  final TransactionType type;
  final DateTime dateTime;
  final String? note;
  final String paymentMethod; // 'cash', 'card', 'bank'
  final String? personName;
  final String? debtId;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.type = TransactionType.expense,
    required this.dateTime,
    this.note,
    this.paymentMethod = 'cash',
    this.personName,
    this.debtId,
    this.isRecurring = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? dateTime,
        updatedAt = updatedAt ?? dateTime;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  TransactionItem copyWith({
    String? id,
    String? title,
    int? amount,
    String? categoryId,
    TransactionType? type,
    DateTime? dateTime,
    String? note,
    String? paymentMethod,
    String? personName,
    String? debtId,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      personName: personName ?? this.personName,
      debtId: debtId ?? this.debtId,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'type': type.name,
      'transactionType': type.name,
      'dateTime': dateTime.toIso8601String(),
      'transactionDate': dateTime.toIso8601String(),
      'note': note,
      'paymentMethod': paymentMethod,
      'personName': personName,
      'debtId': debtId,
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isExpense': isExpense,
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final int parsedAmount = rawAmount is num ? rawAmount.round() : 0;

    TransactionType parsedType;
    final typeField = json['type'] ?? json['transactionType'];
    if (typeField != null) {
      final typeStr = typeField.toString().toLowerCase();
      parsedType = TransactionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => TransactionType.expense,
      );
    } else {
      final isExp = json['isExpense'] as bool? ?? true;
      parsedType = isExp ? TransactionType.expense : TransactionType.income;
    }

    final rawDateStr = json['dateTime'] ?? json['transactionDate'] ?? json['createdAt'];
    final date = DateTime.tryParse(rawDateStr?.toString() ?? '') ?? DateTime.now();

    return TransactionItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: parsedAmount,
      categoryId: json['categoryId'] as String? ?? 'other',
      type: parsedType,
      dateTime: date,
      note: json['note'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      personName: json['personName'] as String?,
      debtId: json['debtId'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? date
          : date,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? date
          : date,
    );
  }
}
