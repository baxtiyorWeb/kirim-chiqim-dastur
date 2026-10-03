import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_item.dart';
import '../models/debt_item.dart';
import '../models/budget_model.dart';
import '../models/savings_goal.dart';
import '../models/category_item.dart';
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
  }

  Future<void> updateTransaction(TransactionItem updatedItem) async {
    final list = _storage.getTransactions();
    final index = list.indexWhere((e) => e.id == updatedItem.id);
    if (index != -1) {
      list[index] = updatedItem.copyWith(updatedAt: DateTime.now());
      await _storage.saveTransactions(list);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final list = _storage.getTransactions();
    list.removeWhere((e) => e.id == id);
    await _storage.saveTransactions(list);
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
      list[index] = updatedDebt.copyWith(updatedAt: DateTime.now());
      await _storage.saveDebts(list);
    }
  }

  Future<void> recordDebtPayment({
    required String debtId,
    required int paymentAmount,
    String? note,
    bool linkTransaction = false,
  }) async {
    final list = _storage.getDebts();
    final index = list.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final debt = list[index];
    final newPaid = (debt.paidAmount + paymentAmount).clamp(0, debt.amount);
    final newStatus = newPaid >= debt.amount ? DebtStatus.returned : DebtStatus.partiallyPaid;

    final repayment = DebtRepayment(
      id: const Uuid().v4(),
      debtId: debtId,
      amount: paymentAmount,
      date: DateTime.now(),
      note: note,
    );

    final updatedRepayments = List<DebtRepayment>.from(debt.repayments)..add(repayment);

    final updatedDebt = debt.copyWith(
      paidAmount: newPaid,
      status: newStatus,
      repayments: updatedRepayments,
      updatedAt: DateTime.now(),
    );

    list[index] = updatedDebt;
    await _storage.saveDebts(list);

    // Optionally create an expense/income transaction if user wants ledger reflection
    if (linkTransaction) {
      final isExpense = debt.isBorrowed; // If I pay back what I borrowed, it's an expense; if they pay me back, it's income
      final tx = TransactionItem(
        id: const Uuid().v4(),
        title: debt.isBorrowed
            ? '${debt.personName} ga qarz qaytarildi'
            : '${debt.personName} dan qarz qaytarildi',
        amount: paymentAmount,
        categoryId: debt.isBorrowed ? 'other' : 'other_income',
        type: isExpense ? TransactionType.expense : TransactionType.income,
        dateTime: DateTime.now(),
        note: note ?? 'Qarz to\'lovi',
        debtId: debtId,
        personName: debt.personName,
      );
      await addTransaction(tx);
    }
  }

  Future<void> markDebtReturned(String debtId) async {
    final list = _storage.getDebts();
    final index = list.indexWhere((d) => d.id == debtId);
    if (index != -1) {
      final debt = list[index];
      final remaining = debt.remainingAmount;
      if (remaining > 0) {
        await recordDebtPayment(
          debtId: debtId,
          paymentAmount: remaining,
          note: 'To\'liq yopildi',
        );
      }
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

  Future<void> deleteGoal(String id) async {
    final list = _storage.getGoals();
    list.removeWhere((g) => g.id == id);
    await _storage.saveGoals(list);
  }

  // Initial Opening Balance
  int getInitialBalance() => _storage.initialBalance;
  Future<void> setInitialBalance(int balance) => _storage.setInitialBalance(balance);

  // Theme Mode
  ThemeMode getThemeMode() => _storage.themeMode;
  Future<void> setThemeMode(ThemeMode mode) => _storage.setThemeMode(mode);

  // Onboarding
  bool hasSeenOnboarding() => _storage.hasSeenOnboarding;
  Future<void> setHasSeenOnboarding(bool seen) => _storage.setHasSeenOnboarding(seen);

  // Reset / Clear Data
  Future<void> clearAllData() => _storage.clearAllData();

  // Export Data to CSV
  String generateCsvReport({
    DateTime? startDate,
    DateTime? endDate,
    bool includeExpenses = true,
    bool includeIncome = true,
    bool includeDebts = true,
  }) {
    final buffer = StringBuffer();

    if (includeExpenses || includeIncome) {
      buffer.writeln('--- TRANZAKSIYALAR HISOBOTI ---');
      buffer.writeln('ID,Sana,Kategoriya,Turi,Summa (so\'m),Nomi,Izoh,To\'lov usuli');

      final txList = getTransactions().where((t) {
        if (startDate != null && t.dateTime.isBefore(startDate)) return false;
        if (endDate != null && t.dateTime.isAfter(endDate)) return false;
        if (!includeExpenses && t.isExpense) return false;
        if (!includeIncome && t.isIncome) return false;
        return true;
      });

      for (final tx in txList) {
        final cat = CategoryItem.getById(tx.categoryId).name;
        final type = tx.isExpense ? 'Chiqim' : 'Kirim';
        final date = '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}-${tx.dateTime.day.toString().padLeft(2, '0')}';
        final cleanTitle = tx.title.replaceAll(',', ' ');
        final cleanNote = (tx.note ?? '').replaceAll(',', ' ');
        buffer.writeln('${tx.id},$date,$cat,$type,${tx.amount},$cleanTitle,$cleanNote,${tx.paymentMethod}');
      }
      buffer.writeln();
    }

    if (includeDebts) {
      buffer.writeln('--- QARZ DAFTARI HISOBOTI ---');
      buffer.writeln('ID,Shaxs,Telefon,Turi,Umumiy summa (so\'m),To\'langan (so\'m),Qolgan summa (so\'m),Holat,Sana,Izoh');

      final debtList = getDebts();
      for (final d in debtList) {
        final type = d.isBorrowed ? 'Olingan qarz' : 'Berilgan qarz';
        final date = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
        final cleanNote = (d.note ?? '').replaceAll(',', ' ');
        buffer.writeln('${d.id},${d.personName},${d.phoneNumber ?? ''},$type,${d.amount},${d.paidAmount},${d.remainingAmount},${d.status.label},$date,$cleanNote');
      }
    }

    return buffer.toString();
  }
}
