import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/debt_item.dart';
import '../../../providers/finance_providers.dart';
import '../../utils/currency_formatter.dart';
import '../models/financial_health.dart';

/// Provider for tracking how many financial decisions/scenarios the user has tested
class EvaluatedDecisionsNotifier extends Notifier<int> {
  @override
  int build() {
    try {
      final storage = ref.watch(localStorageProvider);
      return storage.getEvaluatedDecisionsCount();
    } catch (_) {
      return 4;
    }
  }

  Future<void> recordDecision() async {
    try {
      final storage = ref.read(localStorageProvider);
      await storage.incrementEvaluatedDecisionsCount();
      state = state + 1;
    } catch (_) {
      state = state + 1;
    }
  }
}

final evaluatedDecisionsCountProvider =
    NotifierProvider<EvaluatedDecisionsNotifier, int>(() {
  return EvaluatedDecisionsNotifier();
});

final financialIntelligenceProvider = Provider<FinancialHealthState>((ref) {
  final balance = ref.watch(balanceProvider);
  final dashboard = ref.watch(dashboardSummaryProvider);
  final budget = ref.watch(budgetProvider);
  final debts = ref.watch(debtsProvider);
  final goals = ref.watch(goalsProvider);
  final decisionsCount = ref.watch(evaluatedDecisionsCountProvider);

  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = max(1, daysInMonth - now.day + 1);

  // 1. Debts obligations (kelajakdagi to'lovlar / yaqin qarzlar)
  final unpaidBorrowed = debts
      .where((d) => d.type == DebtType.borrowed && d.status != DebtStatus.returned)
      .toList();
  final totalBorrowedDue =
      unpaidBorrowed.fold<int>(0, (sum, d) => sum + d.remainingAmount);

  // 2. Goals allocation (maqsadlar uchun ajratilgan mablag')
  final totalGoalsAllocated =
      goals.fold<int>(0, (sum, g) => sum + g.currentAmount);

  // 3. Monthly budget & remaining
  final monthlyLimit = dashboard.totalMonthlyLimit > 0
      ? dashboard.totalMonthlyLimit
      : budget.totalMonthlyBudget;
  final monthExpense = dashboard.monthExpense != 0
      ? dashboard.monthExpense
      : dashboard.totalExpense;
  final remainingBudget = max(0, monthlyLimit - monthExpense);

  // 4. Operatsion pul fondi (Oylik byudjet va joriy naqd mablag' uyg'unligi)
  int operationalPool;
  if (monthlyLimit > 0 && remainingBudget > 0) {
    operationalPool = min(balance, remainingBudget);
  } else {
    operationalPool = balance;
  }
  if (operationalPool < 0) operationalPool = 0;

  // 5. Qarzlar uchun oylik zaxira (Soft debt reserve)
  // Butun qarz summasi bir kunda yechib tashlanmaydi! Kundalik yashash xarajati 0 bo'lib qolmasligi uchun
  // balansdan oqilona 15-20% qismi qarz to'lovlariga mo'ljallanadi.
  int debtMonthlyReserve = 0;
  if (totalBorrowedDue > 0 && operationalPool > 0) {
    debtMonthlyReserve = min((operationalPool * 0.2).round(), totalBorrowedDue);
  }

  // 6. Maqsadlar uchun zaxira
  int goalReserve = 0;
  if (totalGoalsAllocated > 0 && operationalPool > 0) {
    goalReserve = min((operationalPool * 0.1).round(), totalGoalsAllocated);
  }

  // 7. Xavfsizlik ehtiyot zaxirasi
  int dynamicBuffer = 0;
  if (operationalPool >= 2000000) {
    dynamicBuffer = min(500000, (operationalPool * 0.08).round());
  } else if (operationalPool >= 500000) {
    dynamicBuffer = (operationalPool * 0.05).round();
  }

  // 8. Kundalik sarf uchun erkin mablag' (Spendable cash)
  int spendableCash = operationalPool - debtMonthlyReserve - goalReserve - dynamicBuffer;
  if (spendableCash < (operationalPool * 0.6).round()) {
    spendableCash = (operationalPool * 0.75).round();
  }
  if (spendableCash <= 0 && balance > 0) {
    spendableCash = (balance * 0.8).round();
  }
  if (spendableCash < 0) {
    spendableCash = max(0, operationalPool);
  }

  // 9. Kunlik me'yor (Safe daily)
  int safeDaily = (spendableCash / daysRemaining).floor();
  if (safeDaily == 0 && balance > 0) {
    safeDaily = (balance / daysRemaining).floor();
  }

  // 10. Burn rate & Runway calculation
  final int dailyBurnRate = (monthExpense > 0 && now.day > 0)
      ? (monthExpense / now.day).round()
      : (balance > 0 ? (balance / 30.0).round() : 1);

  final int runwayDays = dailyBurnRate > 0
      ? (balance / dailyBurnRate).floor()
      : 99;

  // 11. Overall risk level
  final FinancialRiskLevel overallRisk;
  if (balance < 0 || (monthlyLimit > 0 && monthExpense > monthlyLimit)) {
    overallRisk = FinancialRiskLevel.danger;
  } else if (balance < dynamicBuffer ||
      (monthlyLimit > 0 && (monthExpense / monthlyLimit) > 0.85)) {
    overallRisk = FinancialRiskLevel.caution;
  } else {
    overallRisk = FinancialRiskLevel.safe;
  }

  // 12. Radar alerts generation
  final alerts = <RadarAlert>[];

  // A. Cashflow Alert
  if (runwayDays >= 25) {
    alerts.add(
      const RadarAlert(
        id: 'runway_stable',
        title: '🟢 Barqaror moliyaviy oqim',
        description:
            'Hozirgi xarajat sur’atida oylik zaxirangiz xavfsiz holatda saqlanmoqda.',
        type: RadarAlertType.stable,
      ),
    );
  } else if (runwayDays <= 14) {
    alerts.add(
      RadarAlert(
        id: 'runway_warning',
        title: '⚠️ Tezkor sarf tezligi',
        description:
            'Hozirgi xarajat sur’ati davom etsa, mablag‘ $runwayDays kunga yetishi mumkin.',
        type: RadarAlertType.warning,
      ),
    );
  }

  // B. Budget Status Alert
  if (monthlyLimit > 0) {
    final pct = ((monthExpense / monthlyLimit) * 100).round();
    if (pct > 90) {
      alerts.add(
        RadarAlert(
          id: 'budget_danger',
          title: '🔴 Byudjet chegarasi yaqin',
          description:
              'Oylik byudjetning $pct% qismi ishlatildi. Qoldiq: ${CurrencyFormatter.format(remainingBudget)}',
          type: RadarAlertType.danger,
          actionLabel: 'Byudjetni ko‘rish',
          actionRoute: '/budget',
        ),
      );
    } else {
      alerts.add(
        RadarAlert(
          id: 'budget_ok',
          title: '📊 Byudjet nazorat ostida',
          description:
              'Byudjetning $pct% qismi sarflandi. Qolgan limit: ${CurrencyFormatter.format(remainingBudget)}',
          type: RadarAlertType.stable,
          actionLabel: 'Toifalar',
          actionRoute: '/budget',
        ),
      );
    }
  }

  // C. Debts Alert
  final unpaidLent = debts
      .where((d) => d.type == DebtType.lent && d.status != DebtStatus.returned)
      .toList();

  if (unpaidBorrowed.isNotEmpty) {
    alerts.add(
      RadarAlert(
        id: 'debt_borrowed_alert',
        title: '🟡 Qarz majburiyati mavjud',
        description:
            'To‘lanishi kerak bo‘lgan qarz: ${CurrencyFormatter.format(totalBorrowedDue)}. Oylik rejangizda to‘lovlarni inobatga oling.',
        type: RadarAlertType.warning,
        actionLabel: 'Qarzlar',
        actionRoute: '/debts',
      ),
    );
  } else if (unpaidLent.isNotEmpty) {
    final totalLentDue =
        unpaidLent.fold<int>(0, (sum, d) => sum + d.remainingAmount);
    alerts.add(
      RadarAlert(
        id: 'debt_lent_alert',
        title: '💼 Qaytariladigan qarzlar',
        description:
            'Sizga qaytarilishi kutilayotgan mablag‘: ${CurrencyFormatter.format(totalLentDue)}',
        type: RadarAlertType.goal,
        actionLabel: 'Nazorat',
        actionRoute: '/debts',
      ),
    );
  }

  // D. Product-Native Decision Metric (Replacing artificial streak)
  alerts.add(
    RadarAlert(
      id: 'decision_metric_alert',
      title: '💡 $decisionsCount ta moliyaviy qaror hisoblandi',
      description: decisionsCount > 0
          ? 'Bu oy $decisionsCount ta xarid oldindan hisoblab chiqildi va ongli qaror qabul qilindi.'
          : 'Xarajat qilishdan avval oylik me\'yorga ta\'sirini tekshirib ko\'ring.',
      type: RadarAlertType.stable,
    ),
  );

  return FinancialHealthState(
    balance: balance,
    upcomingDebts: totalBorrowedDue,
    debtMonthlyReserve: debtMonthlyReserve,
    goalsAllocation: goalReserve,
    safetyBuffer: dynamicBuffer,
    spendableAmount: spendableCash,
    safeToSpendToday: safeDaily,
    monthlyRemainingBudget: remainingBudget,
    daysRemainingInMonth: daysRemaining,
    runwayDays: runwayDays,
    dailyBurnRate: dailyBurnRate,
    evaluatedDecisionsCount: decisionsCount,
    riskLevel: overallRisk,
    radarAlerts: alerts,
  );
});
