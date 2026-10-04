import 'dart:math';

enum FinancialRiskLevel {
  safe, // Yashil: Barqaror
  caution, // Sariq: E'tibor
  danger, // Qizil: Xavfli
}

enum RadarAlertType {
  stable,
  warning,
  danger,
  goal,
}

class RadarAlert {
  final String id;
  final String title;
  final String description;
  final RadarAlertType type;
  final String? actionLabel;
  final String? actionRoute;

  const RadarAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.actionLabel,
    this.actionRoute,
  });
}

class WhatIfResult {
  final int scenarioAmount;
  final int currentBalance;
  final int postBalance;
  final int postRemainingBudget;
  final int postSafeToSpendToday;
  final int postRunwayDays;
  final FinancialRiskLevel riskLevel;
  final String consequenceMessage;
  final int safetyBuffer;

  const WhatIfResult({
    required this.scenarioAmount,
    required this.currentBalance,
    required this.postBalance,
    required this.postRemainingBudget,
    required this.postSafeToSpendToday,
    required this.postRunwayDays,
    required this.riskLevel,
    required this.consequenceMessage,
    required this.safetyBuffer,
  });

  bool get isSafe => riskLevel == FinancialRiskLevel.safe;
  bool get isCaution => riskLevel == FinancialRiskLevel.caution;
  bool get isDanger => riskLevel == FinancialRiskLevel.danger;
}

class FinancialHealthState {
  final int balance;
  final int safeToSpendToday;
  final int monthlyRemainingBudget;
  final int daysRemainingInMonth;
  final int runwayDays;
  final int dailyBurnRate;
  final int disciplineStreakDays;
  final FinancialRiskLevel riskLevel;
  final List<RadarAlert> radarAlerts;
  final int safetyBuffer;

  const FinancialHealthState({
    required this.balance,
    required this.safeToSpendToday,
    required this.monthlyRemainingBudget,
    required this.daysRemainingInMonth,
    required this.runwayDays,
    this.dailyBurnRate = 0,
    required this.disciplineStreakDays,
    required this.riskLevel,
    required this.radarAlerts,
    this.safetyBuffer = 500000,
  });

  static const FinancialHealthState initial = FinancialHealthState(
    balance: 0,
    safeToSpendToday: 0,
    monthlyRemainingBudget: 0,
    daysRemainingInMonth: 30,
    runwayDays: 30,
    dailyBurnRate: 0,
    disciplineStreakDays: 1,
    riskLevel: FinancialRiskLevel.safe,
    radarAlerts: [],
  );

  WhatIfResult simulateExpense(int amount) {
    if (amount <= 0) {
      return WhatIfResult(
        scenarioAmount: 0,
        currentBalance: balance,
        postBalance: balance,
        postRemainingBudget: monthlyRemainingBudget,
        postSafeToSpendToday: safeToSpendToday,
        postRunwayDays: runwayDays,
        riskLevel: riskLevel,
        consequenceMessage: 'Xarid summasini kiriting.',
        safetyBuffer: safetyBuffer,
      );
    }

    final postBal = balance - amount;
    final postBudget = monthlyRemainingBudget - amount;
    final postSafeDaily = max(0, (postBudget / daysRemainingInMonth).floor());

    // Calculate post runway
    final postRunway = max(0, postBal > 0 ? (postBal / max(1, (balance / max(1, runwayDays)))).floor() : 0);

    final FinancialRiskLevel calculatedRisk;
    final String message;

    if (postBudget < 0 || postBal < 0) {
      calculatedRisk = FinancialRiskLevel.danger;
      message = 'Ushbu xarid oylik byudjetingiz chegarasidan oshib, zaxirangizni xavfli zonaga tushiradi.';
    } else if (postBal < safetyBuffer || postBudget < safetyBuffer) {
      calculatedRisk = FinancialRiskLevel.caution;
      message = 'Ushbu xarid sizning xavfsizlik zaxirangizga yaqinlashtiradi, lekin reja ichida amalga oshirish mumkin.';
    } else {
      calculatedRisk = FinancialRiskLevel.safe;
      message = 'Bu xarid sizning oylik byudjetingiz va zaxirangiz uchun mutlaqo xavfsiz.';
    }

    return WhatIfResult(
      scenarioAmount: amount,
      currentBalance: balance,
      postBalance: postBal,
      postRemainingBudget: postBudget,
      postSafeToSpendToday: postSafeDaily,
      postRunwayDays: postRunway,
      riskLevel: calculatedRisk,
      consequenceMessage: message,
      safetyBuffer: safetyBuffer,
    );
  }
}
