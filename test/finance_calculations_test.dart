import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thego_getters/core/utils/currency_formatter.dart';
import 'package:thego_getters/data/models/budget_model.dart';
import 'package:thego_getters/data/models/category_item.dart';
import 'package:thego_getters/data/models/debt_item.dart';
import 'package:thego_getters/data/models/transaction_item.dart';
import 'package:thego_getters/data/repositories/finance_repository.dart';
import 'package:thego_getters/data/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrencyFormatter Tests', () {
    test('formats whole uzbek som correctly with space thousands', () {
      expect(CurrencyFormatter.format(125000), "125 000 so'm");
      expect(CurrencyFormatter.format(1250000), "1 250 000 so'm");
      expect(CurrencyFormatter.format(500000, includeSymbol: false), "500 000");
    });

    test('compact formatting produces clean fintech labels', () {
      expect(CurrencyFormatter.formatCompact(500000), "500k");
      expect(CurrencyFormatter.formatCompact(1500000), "1.5M");
      expect(CurrencyFormatter.formatCompact(18000000), "18M");
      expect(CurrencyFormatter.formatCompact(250), "250");
    });

    test('safe parsing ignores non-digit characters and avoids float errors', () {
      expect(CurrencyFormatter.parse("1 250 000 so'm"), 1250000);
      expect(CurrencyFormatter.parse("  45,000 "), 45000);
      expect(CurrencyFormatter.parse(""), 0);
    });
  });

  group('Finance Ledger & Repository Operations', () {
    late LocalStorageService storageService;
    late FinanceRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = LocalStorageService(prefs);
      repository = FinanceRepository(storageService);
      // Start with empty transactions list for clean ledger calculation verification
      await storageService.saveTransactions([]);
      await storageService.saveDebts([]);
    });

    test('Add expense, add income, and verify ledger balance determinism', () async {
      // Set initial balance
      await repository.setInitialBalance(1000000);
      expect(repository.getInitialBalance(), 1000000);

      // Add expense
      final expenseTx = TransactionItem(
        id: 'tx_test_1',
        title: 'Tushlik',
        amount: 50000,
        categoryId: 'food',
        type: TransactionType.expense,
        dateTime: DateTime(2026, 10, 1),
      );
      await repository.addTransaction(expenseTx);

      // Add income
      final incomeTx = TransactionItem(
        id: 'tx_test_2',
        title: 'Frilans daromad',
        amount: 300000,
        categoryId: 'business',
        type: TransactionType.income,
        dateTime: DateTime(2026, 10, 2),
      );
      await repository.addTransaction(incomeTx);

      final list = repository.getTransactions();
      expect(list.length, 2);

      // Calculate balance: 1 000 000 - 50 000 + 300 000 = 1 250 000
      final expenses = list.where((t) => t.isExpense).fold<int>(0, (s, t) => s + t.amount);
      final incomes = list.where((t) => t.isIncome).fold<int>(0, (s, t) => s + t.amount);
      final calculated = repository.getInitialBalance() + incomes - expenses;

      expect(expenses, 50000);
      expect(incomes, 300000);
      expect(calculated, 1250000);
    });

    test('Edit transaction modifies values and preserves integrity', () async {
      final tx = TransactionItem(
        id: 'tx_edit_1',
        title: 'Krossovka',
        amount: 200000,
        categoryId: 'clothes',
        type: TransactionType.expense,
        dateTime: DateTime.now(),
      );
      await repository.addTransaction(tx);

      final updated = tx.copyWith(
        amount: 250000,
        note: 'Chegirmasiz xarid',
      );
      await repository.updateTransaction(updated);

      final item = repository.getTransactions().firstWhere((e) => e.id == 'tx_edit_1');
      expect(item.amount, 250000);
      expect(item.note, 'Chegirmasiz xarid');
    });

    test('Delete transaction removes it completely', () async {
      final tx = TransactionItem(
        id: 'tx_del_1',
        title: 'Vaqtinchalik xarajat',
        amount: 30000,
        categoryId: 'other',
        dateTime: DateTime.now(),
      );
      await repository.addTransaction(tx);
      expect(repository.getTransactions().any((t) => t.id == 'tx_del_1'), isTrue);

      await repository.deleteTransaction('tx_del_1');
      expect(repository.getTransactions().any((t) => t.id == 'tx_del_1'), isFalse);
    });
  });

  group('Debt System (Borrowed vs Lent) & Repayment Calculations', () {
    late LocalStorageService storageService;
    late FinanceRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = LocalStorageService(prefs);
      repository = FinanceRepository(storageService);
      await storageService.saveDebts([]);
    });

    test('Borrowed debt tracking: Akmal 500,000 so\'m', () async {
      final borrowed = DebtItem(
        id: 'debt_borrow_test',
        personName: 'Akmal',
        amount: 500000,
        date: DateTime.now(),
        type: DebtType.borrowed,
        status: DebtStatus.active,
      );
      await repository.addDebt(borrowed);

      expect(borrowed.isBorrowed, isTrue);
      expect(borrowed.remainingAmount, 500000);
      expect(borrowed.status, DebtStatus.active);
    });

    test('Partial repayment updates remaining amount and status', () async {
      final lent = DebtItem(
        id: 'debt_lent_test',
        personName: 'Javohir',
        amount: 350000,
        date: DateTime.now(),
        type: DebtType.lent,
        status: DebtStatus.active,
      );
      await repository.addDebt(lent);

      // Record partial payment of 150,000 so'm
      await repository.recordDebtPayment(
        debtId: 'debt_lent_test',
        paymentAmount: 150000,
        note: 'Karta orqali birinchi to\'lov',
      );

      final updated = repository.getDebts().firstWhere((d) => d.id == 'debt_lent_test');
      expect(updated.paidAmount, 150000);
      expect(updated.remainingAmount, 200000);
      expect(updated.status, DebtStatus.partiallyPaid);
      expect(updated.repayments.length, 1);
      expect(updated.repayments.first.amount, 150000);
    });

    test('Full repayment marks debt as returned', () async {
      final debt = DebtItem(
        id: 'debt_full_test',
        personName: 'Ali',
        amount: 200000,
        date: DateTime.now(),
        type: DebtType.lent,
        status: DebtStatus.active,
      );
      await repository.addDebt(debt);

      await repository.markDebtReturned('debt_full_test');

      final closed = repository.getDebts().firstWhere((d) => d.id == 'debt_full_test');
      expect(closed.remainingAmount, 0);
      expect(closed.status, DebtStatus.returned);
    });
  });

  group('Monthly Budget ("Smeta") Calculations', () {
    test('Budget consumption and remaining calculation', () {
      final budget = BudgetModel(
        totalMonthlyBudget: 3000000,
        categoryLimits: {
          'food': 700000,
          'transport': 300000,
        },
      );

      final int spent = 1850000;
      final int remaining = (budget.totalMonthlyBudget - spent).clamp(0, budget.totalMonthlyBudget);
      final double progress = spent / budget.totalMonthlyBudget;

      expect(remaining, 1150000);
      expect((progress * 100).toStringAsFixed(1), '61.7');
    });

    test('Category limit exceeded detection', () {
      const limit = 500000;
      const spent = 620000;
      final isExceeded = spent > limit;
      final excess = spent - limit;

      expect(isExceeded, isTrue);
      expect(excess, 120000);
    });
  });

  group('Export CSV Report Generation', () {
    test('generates valid non-empty CSV format', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final repo = FinanceRepository(storage);

      await repo.addTransaction(
        TransactionItem(
          id: 'tx_csv_1',
          title: 'Non va choy',
          amount: 15000,
          categoryId: 'food',
          type: TransactionType.expense,
          dateTime: DateTime(2026, 10, 3),
        ),
      );

      final csv = repo.generateCsvReport(
        includeExpenses: true,
        includeIncome: true,
        includeDebts: true,
      );

      expect(csv, contains('TRANZAKSIYALAR HISOBOTI'));
      expect(csv, contains('Non va choy'));
      expect(csv, contains('15000'));
    });
  });
}
