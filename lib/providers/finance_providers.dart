import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

// Transactions Notifier
class TransactionsNotifier extends StateNotifier<List<TransactionItem>> {
  final FinanceRepository _repo;

  TransactionsNotifier(this._repo) : super(_repo.getTransactions());

  Future<void> addTransaction(TransactionItem item) async {
    await _repo.addTransaction(item);
    state = _repo.getTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    state = _repo.getTransactions();
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<TransactionItem>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return TransactionsNotifier(repo);
});

// Balance Notifier
class BalanceNotifier extends StateNotifier<double> {
  final FinanceRepository _repo;

  BalanceNotifier(this._repo) : super(_repo.getBalance());

  Future<void> setBalance(double newBalance) async {
    await _repo.setBalance(newBalance);
    state = newBalance;
  }

  void refresh() {
    state = _repo.getBalance();
  }
}

final balanceProvider = StateNotifierProvider<BalanceNotifier, double>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return BalanceNotifier(repo);
});

// Debts Notifier
class DebtsNotifier extends StateNotifier<List<DebtItem>> {
  final FinanceRepository _repo;

  DebtsNotifier(this._repo) : super(_repo.getDebts());

  Future<void> addDebt(DebtItem debt) async {
    await _repo.addDebt(debt);
    state = _repo.getDebts();
  }

  Future<void> updateDebt(DebtItem debt) async {
    await _repo.updateDebt(debt);
    state = _repo.getDebts();
  }

  Future<void> markAsReturned(String id) async {
    final item = state.firstWhere((d) => d.id == id);
    final updated = item.copyWith(
      status: DebtStatus.returned,
      paidAmount: item.amount,
    );
    await updateDebt(updated);
  }

  Future<void> recordPayment(String id, double additionalPaid) async {
    final item = state.firstWhere((d) => d.id == id);
    final newPaid = (item.paidAmount + additionalPaid).clamp(0.0, item.amount);
    final newStatus = newPaid >= item.amount ? DebtStatus.returned : DebtStatus.partiallyPaid;
    final updated = item.copyWith(
      paidAmount: newPaid,
      status: newStatus,
    );
    await updateDebt(updated);
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
    state = _repo.getDebts();
  }
}

final debtsProvider = StateNotifierProvider<DebtsNotifier, List<DebtItem>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return DebtsNotifier(repo);
});

// Budget Notifier
class BudgetNotifier extends StateNotifier<BudgetModel> {
  final FinanceRepository _repo;

  BudgetNotifier(this._repo) : super(_repo.getBudget());

  Future<void> updateMonthlyBudget(double amount) async {
    final updated = state.copyWith(totalMonthlyBudget: amount);
    await _repo.saveBudget(updated);
    state = updated;
  }

  Future<void> updateCategoryLimit(String categoryId, double limit) async {
    final newLimits = Map<String, double>.from(state.categoryLimits);
    newLimits[categoryId] = limit;
    final updated = state.copyWith(categoryLimits: newLimits);
    await _repo.saveBudget(updated);
    state = updated;
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetModel>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return BudgetNotifier(repo);
});

// Goals Notifier
class GoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  final FinanceRepository _repo;

  GoalsNotifier(this._repo) : super(_repo.getGoals());

  Future<void> addGoal(SavingsGoal goal) async {
    await _repo.addGoal(goal);
    state = _repo.getGoals();
  }

  Future<void> addDeposit(String goalId, double amount) async {
    final item = state.firstWhere((g) => g.id == goalId);
    final updated = item.copyWith(currentAmount: item.currentAmount + amount);
    await _repo.updateGoal(updated);
    state = _repo.getGoals();
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<SavingsGoal>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return GoalsNotifier(repo);
});

// Selected Date Filter for Transactions screen
final selectedDateFilterProvider = StateProvider<DateTime>((ref) => DateTime(2025, 9, 24));

// Derived Providers
final totalExpensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final expenses = transactions.where((t) => t.isExpense);
  return expenses.fold<double>(0.0, (sum, t) => sum + t.amount);
});

final categoryExpensesProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final map = <String, double>{};
  for (final t in transactions) {
    if (t.isExpense) {
      map[t.categoryId] = (map[t.categoryId] ?? 0.0) + t.amount;
    }
  }
  return map;
});

// Debts Summary
class DebtsSummary {
  final double totalBorrowed;
  final double remainingBorrowed;
  final double totalLent;
  final double remainingLent;

  const DebtsSummary({
    required this.totalBorrowed,
    required this.remainingBorrowed,
    required this.totalLent,
    required this.remainingLent,
  });
}

final debtsSummaryProvider = Provider<DebtsSummary>((ref) {
  final debts = ref.watch(debtsProvider);
  double borrowedTotal = 0;
  double borrowedRemain = 0;
  double lentTotal = 0;
  double lentRemain = 0;

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
