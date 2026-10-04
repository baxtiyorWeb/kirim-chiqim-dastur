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
  final transactions = ref.watch(transactionsProvider);
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
  final activeGoalReserve = goals.isNotEmpty
      ? (totalGoalsAllocated > 0
          ? min(balance ~/ 5, totalGoalsAllocated)
          : min(balance ~/ 10, 300000))
      : 0;

  // 3. Safety buffer (Xavfsizlik zaxirasi)
  const int safetyBuffer = 500000;

  // 4. Monthly budget & remaining
  final monthlyLimit = dashboard.totalMonthlyLimit > 0
      ? dashboard.totalMonthlyLimit
      : budget.totalMonthlyBudget;
  final monthExpense = dashboard.monthExpense != 0
      ? dashboard.monthExpense
      : dashboard.totalExpense;
  final remainingBudget = max(0, monthlyLimit - monthExpense);

  // 5. Spendable cash (sarflash mumkin bo'lgan erkin mablag')
  // Transparent formula: balance - upcomingDebts - goalReserve - safetyBuffer
  int spendableCash = balance - totalBorrowedDue - activeGoalReserve - safetyBuffer;
  if (spendableCash <= 0 && balance > totalBorrowedDue) {
    // If safety buffer cannot be fully maintained, cautious remaining portion
    spendableCash = max(0, balance - totalBorrowedDue);
  } else if (spendableCash < 0) {
    spendableCash = 0;
  }

  // 6. Safe daily calculation: spendableCash / daysRemaining
  final int safeDaily = max(0, (spendableCash / daysRemaining).floor());

  // 7. Burn rate & Runway calculation
  final int dailyBurnRate = (monthExpense > 0 && now.day > 0)
      ? (monthExpense / now.day).round()
      : (balance > 0 ? (balance / 30.0).round() : 1);

  final int runwayDays = dailyBurnRate > 0
      ? (balance / dailyBurnRate).floor()
      : 99;

  // 8. Overall risk level
  final FinancialRiskLevel overallRisk;
  if (balance < 0 || (monthlyLimit > 0 && monthExpense > monthlyLimit)) {
    overallRisk = FinancialRiskLevel.danger;
  } else if (balance < safetyBuffer ||
      (monthlyLimit > 0 && (monthExpense / monthlyLimit) > 0.85)) {
    overallRisk = FinancialRiskLevel.caution;
  } else {
    overallRisk = FinancialRiskLevel.safe;
  }

  // 9. Radar alerts generation
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
        title: '🟡 Qarz majburiyati',
        description:
            'To‘lanishi kerak bo‘lgan jami qarz: ${CurrencyFormatter.format(totalBorrowedDue)}',
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
    goalsAllocation: activeGoalReserve,
    safetyBuffer: safetyBuffer,
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
