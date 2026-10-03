enum DebtType {
  borrowed, // Olingan qarz - Men olganman (Akmalga qarzim bor)
  lent;     // Berilgan qarz - Men berganman (Javohir menga qarzdor)

  String get label {
    switch (this) {
      case DebtType.borrowed:
        return 'Olingan qarz';
      case DebtType.lent:
        return 'Berilgan qarz';
    }
  }
}

enum DebtStatus {
  active,
  partiallyPaid,
  returned;

  String get label {
    switch (this) {
      case DebtStatus.active:
        return 'Qaytarilmagan';
      case DebtStatus.partiallyPaid:
        return 'Qisman to\'langan';
      case DebtStatus.returned:
        return 'Qaytarildi';
    }
  }
}

class DebtRepayment {
  final String id;
  final String debtId;
  final int amount;
  final DateTime date;
  final String? note;

  const DebtRepayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtRepayment.fromJson(Map<String, dynamic> json) {
    return DebtRepayment(
      id: json['id'] as String? ?? '',
      debtId: json['debtId'] as String? ?? '',
      amount: (json['amount'] as num?)?.round() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
    );
  }
}

class DebtItem {
  final String id;
  final String personName;
  final String? phoneNumber;
  final int amount; // Whole Uzbek So'm
  final int paidAmount;
  final DateTime date;
  final DateTime? dueDate;
  final DebtStatus status;
  final DebtType type;
  final String? note;
  final List<DebtRepayment> repayments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtItem({
    required this.id,
    required this.personName,
    this.phoneNumber,
    required this.amount,
    this.paidAmount = 0,
    required this.date,
    this.dueDate,
    this.status = DebtStatus.active,
    required this.type,
    this.note,
    this.repayments = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? date,
        updatedAt = updatedAt ?? date;

  bool get isBorrowed => type == DebtType.borrowed;
  int get remainingAmount => (amount - paidAmount).clamp(0, amount);
  double get progressPercentage => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  DebtItem copyWith({
    String? id,
    String? personName,
    String? phoneNumber,
    int? amount,
    int? paidAmount,
    DateTime? date,
    DateTime? dueDate,
    DebtStatus? status,
    DebtType? type,
    String? note,
    List<DebtRepayment>? repayments,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      type: type ?? this.type,
      note: note ?? this.note,
      repayments: repayments ?? this.repayments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'type': type.name,
      'isBorrowed': isBorrowed, // backward compatibility
      'note': note,
      'repayments': repayments.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final int parsedAmount = rawAmount is num ? rawAmount.round() : 0;
    final rawPaid = json['paidAmount'];
    final int parsedPaid = rawPaid is num ? rawPaid.round() : 0;

    DebtType parsedType;
    if (json.containsKey('type') && json['type'] != null) {
      final typeStr = json['type'].toString().toLowerCase();
      parsedType = DebtType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => DebtType.borrowed,
      );
    } else {
      final isBorrowed = json['isBorrowed'] as bool? ?? true;
      parsedType = isBorrowed ? DebtType.borrowed : DebtType.lent;
    }

    final date = DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();

    List<DebtRepayment> parsedRepayments = [];
    if (json['repayments'] is List) {
      parsedRepayments = (json['repayments'] as List)
          .map((r) => DebtRepayment.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return DebtItem(
      id: json['id'] as String? ?? '',
      personName: json['personName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      amount: parsedAmount,
      paidAmount: parsedPaid,
      date: date,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DebtStatus.active,
      ),
      type: parsedType,
      note: json['note'] as String?,
      repayments: parsedRepayments,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? date
          : date,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? date
          : date,
    );
  }
}
