import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_item.dart';
import '../data/models/debt_item.dart';
import '../data/models/budget_model.dart';
import '../data/models/savings_goal.dart';
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

// Transactions Notifier
class TransactionsNotifier extends Notifier<List<TransactionItem>> {
  @override
  List<TransactionItem> build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getTransactions();
  }

  Future<void> addTransaction(TransactionItem item) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addTransaction(item);
    state = repo.getTransactions();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.updateTransaction(item);
    state = repo.getTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteTransaction(id);
    state = repo.getTransactions();
  }
}

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<TransactionItem>>(() {
  return TransactionsNotifier();
});

// Initial Balance Notifier (Opening balance)
class InitialBalanceNotifier extends Notifier<int> {
  @override
  int build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getInitialBalance();
  }

  Future<void> setInitialBalance(int newBalance) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.setInitialBalance(newBalance);
    state = newBalance;
  }
}

final initialBalanceProvider = NotifierProvider<InitialBalanceNotifier, int>(() {
  return InitialBalanceNotifier();
});

// Single Source of Truth Ledger Balance
// Balance = Initial Balance + All Income - All Expense
final balanceProvider = Provider<int>((ref) {
  final initial = ref.watch(initialBalanceProvider);
  final transactions = ref.watch(transactionsProvider);

  int net = initial;
  for (final t in transactions) {
    if (t.isExpense) {
      net -= t.amount;
    } else if (t.isIncome) {
      net += t.amount;
    }
  }
  return net;
});

// Debts Notifier
class DebtsNotifier extends Notifier<List<DebtItem>> {
  @override
  List<DebtItem> build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getDebts();
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
      ref.invalidate(transactionsProvider);
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

// Budget Notifier
class BudgetNotifier extends Notifier<BudgetModel> {
  @override
  BudgetModel build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getBudget();
  }

  Future<void> updateMonthlyBudget(int amount) async {
    final updated = state.copyWith(totalMonthlyBudget: amount);
    final repo = ref.read(financeRepositoryProvider);
    await repo.saveBudget(updated);
    state = updated;
  }

  Future<void> updateCategoryLimit(String categoryId, int limit) async {
    final newLimits = Map<String, int>.from(state.categoryLimits);
    newLimits[categoryId] = limit;
    final updated = state.copyWith(categoryLimits: newLimits);
    final repo = ref.read(financeRepositoryProvider);
    await repo.saveBudget(updated);
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

// Goals Notifier
class GoalsNotifier extends Notifier<List<SavingsGoal>> {
  @override
  List<SavingsGoal> build() {
    final repo = ref.watch(financeRepositoryProvider);
    return repo.getGoals();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addGoal(goal);
    state = repo.getGoals();
  }

  Future<void> addDeposit(String goalId, int amount) async {
    final item = state.firstWhere((g) => g.id == goalId);
    final updated = item.copyWith(currentAmount: item.currentAmount + amount);
    final repo = ref.read(financeRepositoryProvider);
    await repo.updateGoal(updated);
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

// Selected Date Filter for Transactions screen (dynamic current month/year)
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setDate(DateTime date) {
    state = date;
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void prevMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }
}

final selectedDateFilterProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

// Derived Providers
final totalExpensesProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((t) => t.isExpense).fold<int>(0, (sum, t) => sum + t.amount);
});

final totalIncomeProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((t) => t.isIncome).fold<int>(0, (sum, t) => sum + t.amount);
});

final currentMonthExpensesProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final filterDate = ref.watch(selectedDateFilterProvider);
  return transactions
      .where((t) =>
          t.isExpense &&
          t.dateTime.month == filterDate.month &&
          t.dateTime.year == filterDate.year)
      .fold<int>(0, (sum, t) => sum + t.amount);
});

final currentMonthIncomeProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final filterDate = ref.watch(selectedDateFilterProvider);
  return transactions
      .where((t) =>
          t.isIncome &&
          t.dateTime.month == filterDate.month &&
          t.dateTime.year == filterDate.year)
      .fold<int>(0, (sum, t) => sum + t.amount);
});

final categoryExpensesProvider = Provider<Map<String, int>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final map = <String, int>{};
  for (final t in transactions) {
    if (t.isExpense) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
  }
  return map;
});

// Debts Summary
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
