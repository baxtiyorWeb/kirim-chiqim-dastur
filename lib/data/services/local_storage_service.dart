import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';
import '../models/debt_item.dart';
import '../models/budget_model.dart';
import '../models/savings_goal.dart';

class LocalStorageService {
  static const String _transactionsKey = 'app_transactions';
  static const String _debtsKey = 'app_debts';
  static const String _budgetKey = 'app_budget';
  static const String _goalsKey = 'app_goals';
  static const String _balanceKey = 'app_balance';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  bool get hasSeenOnboarding => _prefs.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_hasSeenOnboardingKey, value);
  }

  double get balance => _prefs.getDouble(_balanceKey) ?? 750000.0;

  Future<void> setBalance(double value) async {
    await _prefs.setDouble(_balanceKey, value);
  }

  // Transactions
  List<TransactionItem> getTransactions() {
    final raw = _prefs.getString(_transactionsKey);
    if (raw == null) return _defaultTransactions;
    try {
      final List decoded = jsonDecode(raw) as List;
      return decoded.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultTransactions;
    }
  }

  Future<void> saveTransactions(List<TransactionItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_transactionsKey, encoded);
  }

  // Debts
  List<DebtItem> getDebts() {
    final raw = _prefs.getString(_debtsKey);
    if (raw == null) return _defaultDebts;
    try {
      final List decoded = jsonDecode(raw) as List;
      return decoded.map((e) => DebtItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultDebts;
    }
  }

  Future<void> saveDebts(List<DebtItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_debtsKey, encoded);
  }

  // Budget
  BudgetModel getBudget() {
    final raw = _prefs.getString(_budgetKey);
    if (raw == null) return BudgetModel.defaultBudget();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return BudgetModel.fromJson(decoded);
    } catch (_) {
      return BudgetModel.defaultBudget();
    }
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final encoded = jsonEncode(budget.toJson());
    await _prefs.setString(_budgetKey, encoded);
  }

  // Goals
  List<SavingsGoal> getGoals() {
    final raw = _prefs.getString(_goalsKey);
    if (raw == null) return _defaultGoals;
    try {
      final List decoded = jsonDecode(raw) as List;
      return decoded.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultGoals;
    }
  }

  Future<void> saveGoals(List<SavingsGoal> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_goalsKey, encoded);
  }

  // Default seeded data matching reference design
  static final List<TransactionItem> _defaultTransactions = [
    TransactionItem(
      id: 'tx_1',
      title: 'Nonushta',
      amount: 28000,
      categoryId: 'food',
      dateTime: DateTime.now().subtract(const Duration(minutes: 75)),
      note: 'Qahva va kruassan',
    ),
    TransactionItem(
      id: 'tx_2',
      title: 'Avtobus',
      amount: 12000,
      categoryId: 'transport',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      note: 'Shahar bo\'ylab safar',
    ),
    TransactionItem(
      id: 'tx_3',
      title: 'Do\'kon',
      amount: 85000,
      categoryId: 'home',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      note: 'Uy uchun tozalik vositalari',
    ),
    TransactionItem(
      id: 'tx_4',
      title: 'Kiyim',
      amount: 120000,
      categoryId: 'clothes',
      dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      note: 'Yangi futbolka va paypoqlar',
    ),
    TransactionItem(
      id: 'tx_5',
      title: 'Shifokor',
      amount: 50000,
      categoryId: 'health',
      dateTime: DateTime.now().subtract(const Duration(days: 4, hours: 8)),
      note: 'Profilaktik ko\'rik',
    ),
    TransactionItem(
      id: 'tx_6',
      title: 'Tushlik (Kafe)',
      amount: 492000,
      categoryId: 'food',
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      note: 'Jamoaviy biznes tushlik',
    ),
    TransactionItem(
      id: 'tx_7',
      title: 'Taksi xizmati',
      amount: 218000,
      categoryId: 'transport',
      dateTime: DateTime.now().subtract(const Duration(days: 7)),
      note: 'Aeroportga borish',
    ),
    TransactionItem(
      id: 'tx_8',
      title: 'Kommunal to\'lovlar',
      amount: 315000,
      categoryId: 'home',
      dateTime: DateTime.now().subtract(const Duration(days: 10)),
      note: 'Elektr energiyasi va gaz',
    ),
    TransactionItem(
      id: 'tx_9',
      title: 'Kutubxona & Kitoblar',
      amount: 100000,
      categoryId: 'other',
      dateTime: DateTime.now().subtract(const Duration(days: 14)),
      note: 'Shaxsiy rivojlanish kitobi',
    ),
  ];

  static final List<DebtItem> _defaultDebts = [
    DebtItem(
      id: 'debt_1',
      personName: 'Akmal',
      phoneNumber: '+998 90 123 45 67',
      amount: 500000,
      paidAmount: 0,
      date: DateTime.now().subtract(const Duration(days: 12)),
      dueDate: DateTime.now().add(const Duration(days: 10)),
      status: DebtStatus.active,
      isBorrowed: true, // Red: Borrowed from Akmal
      note: 'Mashina ta\'miri uchun olingan',
    ),
    DebtItem(
      id: 'debt_2',
      personName: 'Ali',
      phoneNumber: '+998 93 987 65 43',
      amount: 300000,
      paidAmount: 0,
      date: DateTime.now().subtract(const Duration(days: 6)),
      dueDate: DateTime.now().add(const Duration(days: 15)),
      status: DebtStatus.active,
      isBorrowed: false, // Green: Lent to Ali
      note: 'Do\'stimga berilgan qarz',
    ),
    DebtItem(
      id: 'debt_3',
      personName: 'Dilshod',
      phoneNumber: '+998 97 555 12 34',
      amount: 250000,
      paidAmount: 100000,
      date: DateTime.now().subtract(const Duration(days: 20)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
      status: DebtStatus.partiallyPaid,
      isBorrowed: false, // Lent to Dilshod
      note: '100 000 so\'m qaytardi, 150 000 so\'m qoldi',
    ),
  ];

  static final List<SavingsGoal> _defaultGoals = [
    SavingsGoal(
      id: 'goal_1',
      title: 'Yangi MacBook M3',
      targetAmount: 18000000,
      currentAmount: 12500000,
      deadline: DateTime(2026, 12, 31),
      emoji: '💻',
    ),
    SavingsGoal(
      id: 'goal_2',
      title: 'Sayohat (Dubay)',
      targetAmount: 10000000,
      currentAmount: 4200000,
      deadline: DateTime(2026, 11, 15),
      emoji: '✈️',
    ),
    SavingsGoal(
      id: 'goal_3',
      title: 'Favqulodda xavfsizlik jamg\'armasi',
      targetAmount: 15000000,
      currentAmount: 15000000,
      deadline: DateTime(2026, 8, 30),
      emoji: '🛡️',
    ),
  ];
}
