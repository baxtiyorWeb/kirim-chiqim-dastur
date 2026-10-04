class SavingsGoal {
  final String id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;
  final String emoji;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.emoji = '🎯',
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get remainingAmount => (targetAmount - currentAmount).clamp(0, targetAmount);

  bool get isCompleted => currentAmount >= targetAmount;

  SavingsGoal copyWith({
    String? id,
    String? title,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
    String? emoji,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toUtc().toIso8601String(),
      'emoji': emoji,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['targetAmount'];
    final rawCurrent = json['currentAmount'];
    return SavingsGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetAmount: rawTarget is num ? rawTarget.round() : 0,
      currentAmount: rawCurrent is num ? rawCurrent.round() : 0,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      emoji: json['emoji'] as String? ?? '🎯',
    );
  }
}
