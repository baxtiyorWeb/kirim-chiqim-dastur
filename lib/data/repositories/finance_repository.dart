import '../models/transaction_item.dart';
import '../models/debt_item.dart';
import '../models/budget_model.dart';
import '../models/savings_goal.dart';
import '../services/local_storage_service.dart';

class FinanceRepository {
  final LocalStorageService _storage;

  FinanceRepository(this._storage);

  // Transactions
  List<TransactionItem> getTransactions() => _storage.getTransactions();

  Future<void> addTransaction(TransactionItem item) async {
    final list = _storage.getTransactions();
    list.insert(0, item);
    await _storage.saveTransactions(list);

    // Update balance
    final currentBalance = _storage.balance;
    if (item.isExpense) {
      await _storage.setBalance(currentBalance - item.amount);
    } else {
      await _storage.setBalance(currentBalance + item.amount);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final list = _storage.getTransactions();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = list[index];
      list.removeAt(index);
      await _storage.saveTransactions(list);

      // Revert balance
      final currentBalance = _storage.balance;
      if (item.isExpense) {
        await _storage.setBalance(currentBalance + item.amount);
      } else {
        await _storage.setBalance(currentBalance - item.amount);
      }
    }
  }

  // Debts
  List<DebtItem> getDebts() => _storage.getDebts();

  Future<void> addDebt(DebtItem debt) async {
    final list = _storage.getDebts();
    list.insert(0, debt);
    await _storage.saveDebts(list);
  }

  Future<void> updateDebt(DebtItem updatedDebt) async {
    final list = _storage.getDebts();
    final index = list.indexWhere((d) => d.id == updatedDebt.id);
    if (index != -1) {
      list[index] = updatedDebt;
      await _storage.saveDebts(list);
    }
  }

  Future<void> deleteDebt(String id) async {
    final list = _storage.getDebts();
    list.removeWhere((d) => d.id == id);
    await _storage.saveDebts(list);
  }

  // Budget
  BudgetModel getBudget() => _storage.getBudget();

  Future<void> saveBudget(BudgetModel budget) async {
    await _storage.saveBudget(budget);
  }

  // Goals
  List<SavingsGoal> getGoals() => _storage.getGoals();

  Future<void> addGoal(SavingsGoal goal) async {
    final list = _storage.getGoals();
    list.add(goal);
    await _storage.saveGoals(list);
  }

  Future<void> updateGoal(SavingsGoal updated) async {
    final list = _storage.getGoals();
    final index = list.indexWhere((g) => g.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      await _storage.saveGoals(list);
    }
  }

  // Balance
  double getBalance() => _storage.balance;

  Future<void> setBalance(double balance) async {
    await _storage.setBalance(balance);
  }

  // Onboarding
  bool hasSeenOnboarding() => _storage.hasSeenOnboarding;
  Future<void> setHasSeenOnboarding(bool seen) => _storage.setHasSeenOnboarding(seen);
}
