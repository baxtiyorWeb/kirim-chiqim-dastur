import 'dart:math';
import '../../utils/currency_formatter.dart';

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
  final int currentSafeToSpendToday;
  final int postSafeToSpendToday;
  final int postRunwayDays;
  final FinancialRiskLevel riskLevel;
  final String impactBadge;
  final String consequenceMessage;
  final String adviceMessage;
  final int safetyBuffer;
  final int safetyBufferImpact;
  final int goalsDelayDays;
  final int daysRemainingInMonth;

  const WhatIfResult({
    required this.scenarioAmount,
    required this.currentBalance,
    required this.postBalance,
    required this.postRemainingBudget,
    required this.currentSafeToSpendToday,
    required this.postSafeToSpendToday,
    required this.postRunwayDays,
    required this.riskLevel,
    required this.impactBadge,
    required this.consequenceMessage,
    required this.adviceMessage,
    required this.safetyBuffer,
    required this.safetyBufferImpact,
    required this.goalsDelayDays,
    required this.daysRemainingInMonth,
  });

  bool get isSafe => riskLevel == FinancialRiskLevel.safe;
  bool get isCaution => riskLevel == FinancialRiskLevel.caution;
  bool get isDanger => riskLevel == FinancialRiskLevel.danger;
}

class FinancialHealthState {
  final int balance;
  final int upcomingDebts; // Kelajakdagi to'lovlar
  final int debtMonthlyReserve; // Qarzlar uchun joriy oylik zaxira
  final int goalsAllocation; // Maqsadlar uchun ajratilgan
  final int safetyBuffer; // Xavfsizlik zaxirasi
  final int spendableAmount; // Sarflash mumkin bo'lgan erkin mablag'
  final int safeToSpendToday; // Kunlik hisoblangan me'yor
  final int monthlyRemainingBudget;
  final int daysRemainingInMonth;
  final int runwayDays;
  final int dailyBurnRate;
  final int evaluatedDecisionsCount; // Tekshirilgan moliyaviy qarorlar soni
  final FinancialRiskLevel riskLevel;
  final List<RadarAlert> radarAlerts;

  const FinancialHealthState({
    required this.balance,
    this.upcomingDebts = 0,
    this.debtMonthlyReserve = 0,
    this.goalsAllocation = 0,
    this.safetyBuffer = 500000,
    this.spendableAmount = 0,
    required this.safeToSpendToday,
    required this.monthlyRemainingBudget,
    required this.daysRemainingInMonth,
    required this.runwayDays,
    this.dailyBurnRate = 0,
    required this.evaluatedDecisionsCount,
    required this.riskLevel,
    required this.radarAlerts,
  });

  // Alias for backward compatibility
  int get disciplineStreakDays => evaluatedDecisionsCount;

  static const FinancialHealthState initial = FinancialHealthState(
    balance: 0,
    upcomingDebts: 0,
    debtMonthlyReserve: 0,
    goalsAllocation: 0,
    safetyBuffer: 500000,
    spendableAmount: 0,
    safeToSpendToday: 0,
    monthlyRemainingBudget: 0,
    daysRemainingInMonth: 30,
    runwayDays: 30,
    dailyBurnRate: 0,
    evaluatedDecisionsCount: 3,
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
        currentSafeToSpendToday: safeToSpendToday,
        postSafeToSpendToday: safeToSpendToday,
        postRunwayDays: runwayDays,
        riskLevel: riskLevel,
        impactBadge: 'Xarid summasini kiriting',
        consequenceMessage: 'Rejalashtirgan xaridingiz oylik byudjetingizga qanday ta\'sir qilishini ko\'ring.',
        adviceMessage: 'Summani kiriting, ilova balansingiz va byudjetingizga asoslangan hisob-kitobni ko\'rsatadi.',
        safetyBuffer: safetyBuffer,
        safetyBufferImpact: 0,
        goalsDelayDays: 0,
        daysRemainingInMonth: daysRemainingInMonth,
      );
    }

    final postBal = balance - amount;
    final postBudget = monthlyRemainingBudget - amount;

    // Realistik hisob: qarzning 100% qismini kundalik xarajatdan bir kunda yechib tashlamaymiz!
    final int debtReserve = upcomingDebts > 0 && postBal > 0
        ? min((postBal * 0.2).round(), upcomingDebts)
        : 0;
    final int goalReserve = goalsAllocation > 0 && postBal > 0
        ? min((postBal * 0.1).round(), goalsAllocation)
        : 0;
    final int dynamicBuffer = postBal >= 2000000
        ? min(500000, (postBal * 0.08).round())
        : (postBal >= 500000 ? (postBal * 0.05).round() : 0);

    int postSpendable = postBal - debtReserve - goalReserve - dynamicBuffer;
    if (postSpendable < (postBal * 0.6).round()) {
      postSpendable = (postBal * 0.75).round();
    }
    if (postSpendable < 0) {
      postSpendable = max(0, postBal);
    }

    final postSafeDaily = max(0, (postSpendable / max(1, daysRemainingInMonth)).floor());

    // Calculate post runway
    final postRunway = max(
      0,
      postBal > 0
          ? (postBal / max(1, (balance / max(1, runwayDays)))).floor()
          : 0,
    );

    // Calculate safety buffer impact: how much buffer is breached
    final int bufferImpact = (postBal < safetyBuffer)
        ? min<int>(safetyBuffer, (safetyBuffer - max<int>(0, postBal)))
        : 0;

    // Calculate goal delay impact (N days of daily saving/spend equivalent)
    final dailyBase = max<int>(30000, safeToSpendToday);
    final int delayDays = min<int>(45, max<int>(1, (amount / dailyBase).round()));

    final FinancialRiskLevel calculatedRisk;
    final String badge;
    final String message;
    final String advice;

    final bool budgetExceeded = monthlyRemainingBudget > 0 && postBudget < 0;
    final bool balanceExceeded = postBal < 0;

    if (balanceExceeded || budgetExceeded) {
      calculatedRisk = FinancialRiskLevel.danger;
      badge = 'Katta xarajat';
      message = balanceExceeded
          ? 'Ushbu summa joriy balansingizdan yuqori.'
          : 'Bu xarajat oylik rejalashtirilgan byudjet limitidan oshib ketadi.';
      advice = 'Xaridni rejalashtirishda joriy mablag‘ qoldig‘i va majburiyatlarni inobatga oling.';
    } else if (postSafeDaily < (safeToSpendToday * 0.65) && safeToSpendToday > 0) {
      calculatedRisk = FinancialRiskLevel.caution;
      badge = 'Me\'yorni o‘zgartiradi';
      message = 'Xariddan so\'ng oy oxirigacha har kungi tavsiya etilgan xarajat kamayadi.';
      advice = 'Xariddan so\'ng qolgan kunlarga kunlik me\'yor taxminan ${CurrencyFormatter.format(postSafeDaily)} / kun bo\'ladi.';
    } else {
      calculatedRisk = FinancialRiskLevel.safe;
      badge = 'Me\'yor doirasida';
      message = 'Bu xarid sizning oylik byudjetingizga og\'irlik qilmaydi.';
      advice = 'Oylik rejangiz buzilmaydi, qolgan mablag‘ingiz oy oxirigacha yetadi.';
    }

    return WhatIfResult(
      scenarioAmount: amount,
      currentBalance: balance,
      postBalance: postBal,
      postRemainingBudget: postBudget,
      currentSafeToSpendToday: safeToSpendToday,
      postSafeToSpendToday: postSafeDaily,
      postRunwayDays: postRunway,
      riskLevel: calculatedRisk,
      impactBadge: badge,
      consequenceMessage: message,
      adviceMessage: advice,
      safetyBuffer: safetyBuffer,
      safetyBufferImpact: bufferImpact,
      goalsDelayDays: delayDays,
      daysRemainingInMonth: daysRemainingInMonth,
    );
  }
}
