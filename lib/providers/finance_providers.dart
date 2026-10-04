import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_item.dart';
import '../data/models/debt_item.dart';
import '../data/models/budget_model.dart';
import '../data/models/savings_goal.dart';
import '../data/models/dashboard_summary.dart';
import '../data/models/statistics_response.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/finance_repository.dart';
import '../data/services/local_storage_service.dart';

// Storage & Repository Providers
final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in ProviderScope');
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return FinanceRepository(storage);
});

// Theme Mode Notifier
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final repo = ref.read(financeRepositoryProvider);
    await repo.setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

// User Profile Notifier (Direct from /api/v1/auth/me)
class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final repo = ref.watch(financeRepositoryProvider);
    // Asynchronously fetch fresh profile if authenticated
    if (repo.isAuthenticated) {
      Future.microtask(() async {
        final profile = await repo.fetchProfile();
        state = profile;
      });
    }
    return repo.userProfile;
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    final profile = await repo.fetchProfile();
    state = profile;
  }

  Future<void> updateProfile({required String fullName, String? email}) async {
    final repo = ref.read(financeRepositoryProvider);
    final updated = await repo.updateProfile(fullName: fullName, email: email);
    state = updated;
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});

// Dashboard Summary Notifier (Direct from /api/v1/dashboard)
class DashboardSummaryNotifier extends Notifier<DashboardSummary> {
  @override
  DashboardSummary build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getDashboardSummary();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    final summary = await repo.fetchDashboard();
    state = summary;
  }
}

final dashboardSummaryProvider =
    NotifierProvider<DashboardSummaryNotifier, DashboardSummary>(() {
  return DashboardSummaryNotifier();
});

// Transactions Notifier (Real PostgreSQL List via /api/v1/transactions)
class TransactionsNotifier extends Notifier<List<TransactionItem>> {
  @override
  List<TransactionItem> build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getTransactions();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    final list = await repo.fetchTransactions();
    state = list;
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }

  Future<void> addTransaction(TransactionItem item) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addTransaction(item);
    state = repo.getTransactions();
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.updateTransaction(item);
    state = repo.getTransactions();
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteTransaction(id);
    state = repo.getTransactions();
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<TransactionItem>>(() {
  return TransactionsNotifier();
});

// Single Source of Truth Ledger Balance
final balanceProvider = Provider<int>((ref) {
  final dashboard = ref.watch(dashboardSummaryProvider);
  if (dashboard.balance != 0) {
    return dashboard.balance;
  }

  // Fallback to in-memory transaction sum if dashboard not yet retrieved
  final transactions = ref.watch(transactionsProvider);
  int net = 0;
  for (final t in transactions) {
    if (t.isExpense) {
      net -= t.amount;
    } else if (t.isIncome) {
      net += t.amount;
    }
  }
  return net;
});

// Debts Notifier (Real PostgreSQL via /api/v1/debts)
class DebtsNotifier extends Notifier<List<DebtItem>> {
  @override
  List<DebtItem> build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getDebts();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    final list = await repo.fetchDebts();
    state = list;
  }

  Future<void> addDebt(DebtItem debt) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addDebt(debt);
    state = repo.getDebts();
  }

  Future<void> updateDebt(DebtItem debt) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.updateDebt(debt);
    state = repo.getDebts();
  }

  Future<void> recordPayment({
    required String debtId,
    required int amount,
    String? note,
    bool linkTransaction = false,
  }) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.recordDebtPayment(
      debtId: debtId,
      paymentAmount: amount,
      note: note,
      linkTransaction: linkTransaction,
    );
    state = repo.getDebts();
    if (linkTransaction) {
      ref.read(transactionsProvider.notifier).refresh();
    }
  }

  Future<void> markAsReturned(String id) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.markDebtReturned(id);
    state = repo.getDebts();
  }

  Future<void> deleteDebt(String id) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteDebt(id);
    state = repo.getDebts();
  }
}

final debtsProvider = NotifierProvider<DebtsNotifier, List<DebtItem>>(() {
  return DebtsNotifier();
});

// Budget Notifier (Real PostgreSQL via /api/v1/budget)
class BudgetNotifier extends Notifier<BudgetModel> {
  @override
  BudgetModel build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getBudget();
  }

  Future<void> refresh([String? yearMonth]) async {
    final repo = ref.read(financeRepositoryProvider);
    final budget = await repo.fetchBudget(yearMonth);
    state = budget;
  }

  Future<void> updateMonthlyBudget(int amount) async {
    final updated = state.copyWith(totalMonthlyBudget: amount);
    final repo = ref.read(financeRepositoryProvider);
    await repo.saveBudget(updated);
    state = updated;
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }

  Future<void> updateCategoryLimit(String categoryId, int limit) async {
    final newLimits = Map<String, int>.from(state.categoryLimits);
    newLimits[categoryId] = limit;
    final updated = state.copyWith(categoryLimits: newLimits);
    final repo = ref.read(financeRepositoryProvider);
    await repo.setCategoryLimit(categoryId, limit);
    state = updated;
  }

  Future<void> toggleBudget(bool enabled) async {
    final updated = state.copyWith(isEnabled: enabled);
    final repo = ref.read(financeRepositoryProvider);
    await repo.saveBudget(updated);
    state = updated;
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetModel>(() {
  return BudgetNotifier();
});

// Goals Notifier (Real PostgreSQL via /api/v1/goals)
class GoalsNotifier extends Notifier<List<SavingsGoal>> {
  @override
  List<SavingsGoal> build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getGoals();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    final list = await repo.fetchGoals();
    state = list;
  }

  Future<void> addGoal(SavingsGoal goal) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addGoal(goal);
    state = repo.getGoals();
  }

  Future<void> addDeposit(String goalId, int amount) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addGoalDeposit(goalId, amount);
    state = repo.getGoals();
  }

  Future<void> deleteGoal(String id) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteGoal(id);
    state = repo.getGoals();
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<SavingsGoal>>(() {
  return GoalsNotifier();
});

// Statistics Notifier (PostgreSQL aggregated calculations)
class StatisticsNotifier extends Notifier<StatisticsResponse> {
  String _currentPeriod = 'monthly';

  @override
  StatisticsResponse build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return StatisticsResponse.empty(_currentPeriod);
  }

  Future<void> setPeriod(String period) async {
    _currentPeriod = period;
    await refresh();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    final res = await repo.fetchStatistics(_currentPeriod);
    state = res;
  }
}

final statisticsProvider =
    NotifierProvider<StatisticsNotifier, StatisticsResponse>(() {
  return StatisticsNotifier();
});

// Selected Date Filter for Transactions screen
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setDate(DateTime date) => state = date;
  void nextMonth() => state = DateTime(state.year, state.month + 1, 1);
  void prevMonth() => state = DateTime(state.year, state.month - 1, 1);
}

final selectedDateFilterProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

// Derived Providers
final currentMonthExpensesProvider = Provider<int>((ref) {
  final dash = ref.watch(dashboardSummaryProvider);
  if (dash.monthExpense > 0) return dash.monthExpense;
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();
  return transactions
      .where((t) => t.isExpense && t.dateTime.year == now.year && t.dateTime.month == now.month)
      .fold<int>(0, (sum, t) => sum + t.amount);
});

class InitialBalanceNotifier extends Notifier<int> {
  @override
  int build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getInitialBalance();
  }

  Future<void> setInitialBalance(int amount) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.setInitialBalance(amount);
    state = amount;
  }
}

final initialBalanceProvider =
    NotifierProvider<InitialBalanceNotifier, int>(() {
  return InitialBalanceNotifier();
});

final totalExpensesProvider = Provider<int>((ref) {
  final dash = ref.watch(dashboardSummaryProvider);
  if (dash.totalExpense > 0) return dash.totalExpense;
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((t) => t.isExpense).fold<int>(0, (sum, t) => sum + t.amount);
});

final totalIncomeProvider = Provider<int>((ref) {
  final dash = ref.watch(dashboardSummaryProvider);
  if (dash.totalIncome > 0) return dash.totalIncome;
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((t) => t.isIncome).fold<int>(0, (sum, t) => sum + t.amount);
});

final categoryExpensesProvider = Provider<Map<String, int>>((ref) {
  final dash = ref.watch(dashboardSummaryProvider);
  if (dash.categoryExpenses.isNotEmpty) {
    return dash.categoryExpenses;
  }
  final transactions = ref.watch(transactionsProvider);
  final map = <String, int>{};
  for (final t in transactions) {
    if (t.isExpense) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
  }
  return map;
});

// Debts Summary Provider
class DebtsSummary {
  final int totalBorrowed;
  final int remainingBorrowed;
  final int totalLent;
  final int remainingLent;

  const DebtsSummary({
    required this.totalBorrowed,
    required this.remainingBorrowed,
    required this.totalLent,
    required this.remainingLent,
  });
}

final debtsSummaryProvider = Provider<DebtsSummary>((ref) {
  final debts = ref.watch(debtsProvider);
  int borrowedTotal = 0;
  int borrowedRemain = 0;
  int lentTotal = 0;
  int lentRemain = 0;

  for (final d in debts) {
    if (d.isBorrowed) {
      borrowedTotal += d.amount;
      borrowedRemain += d.remainingAmount;
    } else {
      lentTotal += d.amount;
      lentRemain += d.remainingAmount;
    }
  }

  return DebtsSummary(
    totalBorrowed: borrowedTotal,
    remainingBorrowed: borrowedRemain,
    totalLent: lentTotal,
    remainingLent: lentRemain,
  );
});
