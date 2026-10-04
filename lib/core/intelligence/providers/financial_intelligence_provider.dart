import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/debt_item.dart';
import '../../../providers/finance_providers.dart';
import '../../utils/currency_formatter.dart';
import '../models/financial_health.dart';

final financialIntelligenceProvider = Provider<FinancialHealthState>((ref) {
  final balance = ref.watch(balanceProvider);
  final dashboard = ref.watch(dashboardSummaryProvider);
  final budget = ref.watch(budgetProvider);
  final debts = ref.watch(debtsProvider);
  final transactions = ref.watch(transactionsProvider);

  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = max(1, daysInMonth - now.day + 1);

  // 1. Monthly budget & remaining
  final monthlyLimit = dashboard.totalMonthlyLimit > 0
      ? dashboard.totalMonthlyLimit
      : budget.totalMonthlyBudget;
  final monthExpense = dashboard.monthExpense != 0
      ? dashboard.monthExpense
      : dashboard.totalExpense;
  final remainingBudget = max(0, monthlyLimit - monthExpense);

  // 2. Safe-to-Spend Today calculation
  final int safeDaily;
  if (monthlyLimit > 0 && remainingBudget > 0) {
    safeDaily = (remainingBudget / daysRemaining).floor();
  } else if (balance > 0) {
    safeDaily = (balance / daysRemaining).floor();
  } else {
    safeDaily = 0;
  }

  // 3. Burn rate & Runway calculation
  final int dailyBurnRate = (monthExpense > 0 && now.day > 0)
      ? (monthExpense / now.day).round()
      : (balance > 0 ? (balance / 30.0).round() : 1);

  final int runwayDays = dailyBurnRate > 0
      ? (balance / dailyBurnRate).floor()
      : 99;

  // 4. Overall risk level
  final FinancialRiskLevel overallRisk;
  if (balance < 0 || (monthlyLimit > 0 && monthExpense > monthlyLimit)) {
    overallRisk = FinancialRiskLevel.danger;
  } else if (monthlyLimit > 0 && (monthExpense / monthlyLimit) > 0.85) {
    overallRisk = FinancialRiskLevel.caution;
  } else {
    overallRisk = FinancialRiskLevel.safe;
  }

  // 5. Radar alerts generation
  final alerts = <RadarAlert>[];

  // A. Cashflow Alert
  if (runwayDays >= 25) {
    alerts.add(
      RadarAlert(
        id: 'runway_stable',
        title: '🟢 Barqaror moliyaviy oqim',
        description: 'Hozirgi xarajat sur’atida oylik zaxirangiz xavfsiz holatda saqlanmoqda.',
        type: RadarAlertType.stable,
      ),
    );
  } else if (runwayDays <= 14) {
    alerts.add(
      RadarAlert(
        id: 'runway_warning',
        title: '⚠️ Tezkor sarf tezligi',
        description: 'Hozirgi xarajat sur’ati davom etsa, mablag‘ $runwayDays kunga yetishi mumkin.',
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
          title: '🔴 Smeta chegarasi yaqin',
          description: 'Oylik smetaning $pct% qismi ishlatildi. Qoldiq: ${CurrencyFormatter.format(remainingBudget)}',
          type: RadarAlertType.danger,
          actionLabel: 'Smetani ko‘rish',
          actionRoute: '/budget',
        ),
      );
    } else {
      alerts.add(
        RadarAlert(
          id: 'budget_ok',
          title: '📊 Smeta nazorat ostida',
          description: 'Smetaning $pct% qismi sarflandi. Qolgan limit: ${CurrencyFormatter.format(remainingBudget)}',
          type: RadarAlertType.stable,
          actionLabel: 'Toifalar',
          actionRoute: '/budget',
        ),
      );
    }
  }

  // C. Debts Alert
  final unpaidBorrowed = debts.where((d) => d.type == DebtType.borrowed && d.status != DebtStatus.returned).toList();
  final unpaidLent = debts.where((d) => d.type == DebtType.lent && d.status != DebtStatus.returned).toList();

  if (unpaidBorrowed.isNotEmpty) {
    final totalBorrowedDue = unpaidBorrowed.fold<int>(0, (sum, d) => sum + d.remainingAmount);
    alerts.add(
      RadarAlert(
        id: 'debt_borrowed_alert',
        title: '🟡 Qarz majburiyati',
        description: 'To‘lanishi kerak bo‘lgan jami qarz: ${CurrencyFormatter.format(totalBorrowedDue)}',
        type: RadarAlertType.warning,
        actionLabel: 'Qarzlar',
        actionRoute: '/debts',
      ),
    );
  } else if (unpaidLent.isNotEmpty) {
    final totalLentDue = unpaidLent.fold<int>(0, (sum, d) => sum + d.remainingAmount);
    alerts.add(
      RadarAlert(
        id: 'debt_lent_alert',
        title: '💼 Qaytariladigan qarzlar',
        description: 'Sizga qaytarilishi kutilayotgan mablag‘: ${CurrencyFormatter.format(totalLentDue)}',
        type: RadarAlertType.goal,
        actionLabel: 'Nazorat',
        actionRoute: '/debts',
      ),
    );
  }

  // D. Retention & Habit Streak Alert
  final int streakDays = min(30, max(3, transactions.length ~/ 2 + 1));
  alerts.add(
    RadarAlert(
      id: 'streak_alert',
      title: '🔥 $streakDays kunlik moliyaviy intizom',
      description: 'Har kungi xarajatlarni o‘z vaqtida qayd etib, ongli boshqarmoqdasiz.',
      type: RadarAlertType.stable,
    ),
  );

  return FinancialHealthState(
    balance: balance,
    safeToSpendToday: safeDaily,
    monthlyRemainingBudget: remainingBudget,
    daysRemainingInMonth: daysRemaining,
    runwayDays: runwayDays,
    dailyBurnRate: dailyBurnRate,
    disciplineStreakDays: streakDays,
    riskLevel: overallRisk,
    radarAlerts: alerts,
    safetyBuffer: 500000,
  );
});
