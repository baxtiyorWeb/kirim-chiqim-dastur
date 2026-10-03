enum DebtStatus {
  active,
  returned,
  partiallyPaid;

  String get label {
    switch (this) {
      case DebtStatus.active:
        return 'Faol';
      case DebtStatus.returned:
        return 'Qaytarildi';
      case DebtStatus.partiallyPaid:
        return 'Qisman to\'langan';
    }
  }
}

class DebtItem {
  final String id;
  final String personName;
  final String? phoneNumber;
  final double amount;
  final double paidAmount;
  final DateTime date;
  final DateTime? dueDate;
  final DebtStatus status;
  final bool isBorrowed; // true = borrowed (Red), false = lent (Green)
  final String? note;

  const DebtItem({
    required this.id,
    required this.personName,
    this.phoneNumber,
    required this.amount,
    this.paidAmount = 0.0,
    required this.date,
    this.dueDate,
    this.status = DebtStatus.active,
    required this.isBorrowed,
    this.note,
  });

  double get remainingAmount => (amount - paidAmount).clamp(0, amount);

  DebtItem copyWith({
    String? id,
    String? personName,
    String? phoneNumber,
    double? amount,
    double? paidAmount,
    DateTime? date,
    DateTime? dueDate,
    DebtStatus? status,
    bool? isBorrowed,
    String? note,
  }) {
    return DebtItem(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      isBorrowed: isBorrowed ?? this.isBorrowed,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'paidAmount': paidAmount,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status.name,
      'isBorrowed': isBorrowed,
      'note': note,
    };
  }

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      id: json['id'] as String,
      personName: json['personName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DebtStatus.active,
      ),
      isBorrowed: json['isBorrowed'] as bool,
      note: json['note'] as String?,
    );
  }
}
