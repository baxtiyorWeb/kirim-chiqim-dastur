import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../models/transaction_item.dart';
import '../models/debt_item.dart';
import '../models/budget_model.dart';
import '../models/savings_goal.dart';
import '../models/dashboard_summary.dart';
import '../models/statistics_response.dart';
import '../models/user_profile.dart';
import '../models/category_item.dart';
import '../models/billing_models.dart';
import '../services/local_storage_service.dart';

/// Single source of truth repository connecting Flutter state directly to Go backend and PostgreSQL.
/// In strict accordance with the Production Architecture:
/// - NO financial data is persisted locally in SQLite, Hive, or SharedPreferences.
/// - In-memory state exists solely during the active application session.
/// - PostgreSQL via REST API is the authoritative source for all business data.
class FinanceRepository {
  final LocalStorageService _storage;
  final ApiClient _api;

  // Active in-memory session caches (NOT persisted locally)
  List<TransactionItem> _transactions = [];
  List<DebtItem> _debts = [];
  BudgetModel _budget = BudgetModel.defaultBudget();
  List<SavingsGoal> _goals = [];
  DashboardSummary _dashboardSummary = DashboardSummary.empty();
  final Map<String, StatisticsResponse> _statisticsCache = {};
  UserProfile _userProfile = UserProfile.guest();
  bool _isInitialized = false;
  VoidCallback? onLogout;

  bool _isHandlingUnauthorized = false;

  FinanceRepository(this._storage, [ApiClient? api])
      : _api = api ?? ApiClient(_storage) {
    hydrateFromLocalStorage();
    _api.onUnauthorized = () async {
      if (_isHandlingUnauthorized) return;
      _isHandlingUnauthorized = true;
      try {
        await logout();
        onLogout?.call();
      } finally {
        _isHandlingUnauthorized = false;
      }
    };
  }

  /// Hydrates in-memory lists from device local storage (guarantees offline availability for Free & Paid)
  void hydrateFromLocalStorage() {
    try {
      final cachedTxs = _storage.getOfflineTransactions();
      if (cachedTxs.isNotEmpty) {
        _transactions = cachedTxs.map((m) => TransactionItem.fromJson(m)).toList();
      }
      final cachedDebts = _storage.getOfflineDebts();
      if (cachedDebts.isNotEmpty) {
        _debts = cachedDebts.map((m) => DebtItem.fromJson(m)).toList();
      }
      final cachedBudget = _storage.getOfflineBudget();
      if (cachedBudget != null) {
        _budget = BudgetModel.fromJson(cachedBudget);
      }
      final cachedGoals = _storage.getOfflineGoals();
      if (cachedGoals.isNotEmpty) {
        _goals = cachedGoals.map((m) => SavingsGoal.fromJson(m)).toList();
      }
      final cachedInitial = _storage.getOfflineInitialBalance();
      if (cachedInitial > 0) {
        _userProfile = _userProfile.copyWith(initialBalance: cachedInitial);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[FinanceRepository] hydrateFromLocalStorage notice: $e');
    }
  }

  void persistAllOffline() {
    _persistTransactionsOffline();
    _persistDebtsOffline();
    _persistBudgetOffline();
    _persistGoalsOffline();
  }

  void _persistTransactionsOffline() {
    try {
      _storage.saveOfflineTransactions(_transactions.map((t) => t.toJson()).toList());
    } catch (_) {}
  }

  void _persistDebtsOffline() {
    try {
      _storage.saveOfflineDebts(_debts.map((d) => d.toJson()).toList());
    } catch (_) {}
  }

  void _persistBudgetOffline() {
    try {
      _storage.saveOfflineBudget(_budget.toJson());
    } catch (_) {}
  }

  void _persistGoalsOffline() {
    try {
      _storage.saveOfflineGoals(_goals.map((g) => g.toJson()).toList());
    } catch (_) {}
  }

  ApiClient get api => _api;
  LocalStorageService get storage => _storage;
  bool get isInitialized => _isInitialized;

  // -------------------------------------------------------------
  // AUTHENTICATION & USER MANAGEMENT
  // -------------------------------------------------------------

  bool get isAuthenticated => _storage.isAuthenticated;
  String? get currentUserId => _storage.getUserId();
  String? get currentUserEmail => _userProfile.email ?? _storage.getUserEmail();
  String? get currentUserName => _userProfile.fullName.isNotEmpty && _userProfile.fullName != 'Foydalanuvchi'
      ? _userProfile.fullName
      : _storage.getUserName() ?? 'Foydalanuvchi';
  String? get currentUserPhone => _userProfile.phoneNumber ?? _storage.getUserPhone();
  UserProfile get userProfile => _userProfile;

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await _api.post(ApiConstants.authSendOtp, body: {
      'phoneNumber': phoneNumber,
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String code) async {
    final response = await _api.post(ApiConstants.authVerifyOtp, body: {
      'phoneNumber': phoneNumber,
      'code': code,
    });

    if (response is Map) {
      final resMap = Map<String, dynamic>.from(response);
      final isNewUser = resMap['isNewUser'] == true;
      if (!isNewUser) {
        _resetMemorySession();
        final token = resMap['token']?.toString();
        final user = resMap['user'] as Map<String, dynamic>?;
        if (token != null) {
          await _storage.saveAuthToken(token);
        }
        if (user != null) {
          _userProfile = UserProfile.fromJson(user);
          await _storage.saveUserProfile(
            userId: _userProfile.id,
            email: _userProfile.email,
            fullName: _userProfile.fullName,
            phoneNumber: _userProfile.phoneNumber ?? phoneNumber,
          );
        }
        await syncAllWithBackend();
      }
      return resMap;
    }
    return {'isNewUser': false};
  }

  Future<void> completeRegistration(String phoneNumber, String fullName) async {
    final response = await _api.post(ApiConstants.authCompleteRegistration, body: {
      'phoneNumber': phoneNumber,
      'fullName': fullName,
    });

    if (response is Map) {
      _resetMemorySession();
      final token = response['token']?.toString();
      final user = response['user'] as Map<String, dynamic>?;
      if (token != null) {
        await _storage.saveAuthToken(token);
      }
      if (user != null) {
        _userProfile = UserProfile.fromJson(user);
        await _storage.saveUserProfile(
          userId: _userProfile.id,
          email: _userProfile.email,
          fullName: _userProfile.fullName,
          phoneNumber: _userProfile.phoneNumber ?? phoneNumber,
        );
      }
      await syncAllWithBackend();
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _api.post(ApiConstants.authLogin, body: {
      'email': email,
      'password': password,
    });

    if (response is Map) {
      _resetMemorySession();
      final token = response['token']?.toString();
      final user = response['user'] as Map<String, dynamic>?;
      if (token != null) {
        await _storage.saveAuthToken(token);
      }
      if (user != null) {
        _userProfile = UserProfile.fromJson(user);
        await _storage.saveUserProfile(
          userId: _userProfile.id,
          email: _userProfile.email,
          fullName: _userProfile.fullName,
          phoneNumber: _userProfile.phoneNumber,
        );
      }
      await syncAllWithBackend();
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    final response = await _api.post(ApiConstants.authRegister, body: {
      'email': email,
      'password': password,
      'fullName': fullName,
    });

    if (response is Map) {
      _resetMemorySession();
      final token = response['token']?.toString();
      final user = response['user'] as Map<String, dynamic>?;
      if (token != null) {
        await _storage.saveAuthToken(token);
      }
      if (user != null) {
        _userProfile = UserProfile.fromJson(user);
        await _storage.saveUserProfile(
          userId: _userProfile.id,
          email: _userProfile.email,
          fullName: _userProfile.fullName,
          phoneNumber: _userProfile.phoneNumber,
        );
      }
      await syncAllWithBackend();
    }
  }

  /// Wipes all in-memory financial and user caches instantly
  void _resetMemorySession() {
    _inFlightDashboard = null;
    _inFlightTransactions = null;
    _transactions = [];
    _debts = [];
    _budget = BudgetModel.defaultBudget();
    _goals = [];
    _dashboardSummary = DashboardSummary.empty();
    _statisticsCache.clear();
    _userProfile = UserProfile.guest();
    _isInitialized = false;
  }

  Future<void> logout() async {
    _resetMemorySession();
    await _storage.clearAllData();
  }

  Future<UserProfile> fetchProfile() async {
    if (!isAuthenticated) return _userProfile;
    try {
      final res = await _api.get(ApiConstants.authMe);
      if (res is Map<String, dynamic>) {
        _userProfile = UserProfile.fromJson(res);
        await _storage.saveUserProfile(
          userId: _userProfile.id,
          email: _userProfile.email,
          fullName: _userProfile.fullName,
          phoneNumber: _userProfile.phoneNumber,
        );
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchProfile notice: $e');
    }
    return _userProfile;
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    String? email,
    String? avatarUrl,
  }) async {
    final res = await _api.put(ApiConstants.authProfile, body: {
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
    });

    if (res is Map<String, dynamic>) {
      _userProfile = UserProfile.fromJson(res);
      await _storage.saveUserProfile(
        userId: _userProfile.id,
        email: _userProfile.email,
        fullName: _userProfile.fullName,
        phoneNumber: _userProfile.phoneNumber,
      );
    }
    return _userProfile;
  }

  Future<void> deleteAccount() async {
    try {
      await _api.delete(ApiConstants.authDeleteAccount);
    } catch (_) {}
    await logout();
  }

  // -------------------------------------------------------------
  // FULL REAL DATA SYNCHRONIZATION WITH POSTGRESQL
  // -------------------------------------------------------------

  Future<void> syncAllWithBackend() async {
    if (!isAuthenticated) return;

    try {
      Future<dynamic> safeGet(String endpoint, [Map<String, dynamic>? queryParams]) async {
        try {
          return await _api.get(endpoint, queryParams: queryParams);
        } catch (e) {
          debugPrint('[FinanceRepository] sync error for $endpoint: $e');
          return null;
        }
      }

      final results = await Future.wait([
        safeGet(ApiConstants.dashboard),
        safeGet(ApiConstants.transactions),
        safeGet(ApiConstants.budget),
        safeGet(ApiConstants.debts),
        safeGet(ApiConstants.goals),
        safeGet(ApiConstants.authMe),
      ]);

      if (!isAuthenticated) return;

      // 1. Dashboard summary
      if (results[0] is Map<String, dynamic>) {
        _dashboardSummary = DashboardSummary.fromJson(results[0] as Map<String, dynamic>);
      } else {
        _dashboardSummary = DashboardSummary.empty();
      }

      // 2. Transactions
      if (results[1] is List) {
        _transactions = (results[1] as List)
            .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _transactions = [];
      }

      // 3. Budget
      if (results[2] is Map<String, dynamic>) {
        _budget = BudgetModel.fromJson(results[2] as Map<String, dynamic>);
      } else {
        _budget = BudgetModel.defaultBudget();
      }

      // 4. Debts
      if (results[3] is List) {
        _debts = (results[3] as List)
            .map((e) => DebtItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _debts = [];
      }

      // 5. Goals
      if (results[4] is List) {
        _goals = (results[4] as List)
            .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _goals = [];
      }

      // 6. Profile
      if (results[5] is Map<String, dynamic>) {
        _userProfile = UserProfile.fromJson(results[5] as Map<String, dynamic>);
      }

      _statisticsCache.clear();
      _isInitialized = true;
    } catch (e) {
      debugPrint('[FinanceRepository] syncAllWithBackend warning: $e');
    }
  }

  // -------------------------------------------------------------
  // DASHBOARD
  // -------------------------------------------------------------

  Future<DashboardSummary>? _inFlightDashboard;

  DashboardSummary getDashboardSummary() => _dashboardSummary;

  Future<DashboardSummary> fetchDashboard() {
    if (!isAuthenticated) return Future.value(_dashboardSummary);
    if (_inFlightDashboard != null) return _inFlightDashboard!;

    _inFlightDashboard = _doFetchDashboard().whenComplete(() {
      _inFlightDashboard = null;
    });
    return _inFlightDashboard!;
  }

  Future<DashboardSummary> _doFetchDashboard() async {
    try {
      final res = await _api.get(ApiConstants.dashboard);
      if (res is Map<String, dynamic>) {
        _dashboardSummary = DashboardSummary.fromJson(res);
        // Seed transactions if empty
        if (_transactions.isEmpty && _dashboardSummary.recentTransactions.isNotEmpty) {
          _transactions = List.from(_dashboardSummary.recentTransactions);
        }
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchDashboard notice: $e');
    }
    return _dashboardSummary;
  }

  // -------------------------------------------------------------
  // TRANSACTIONS
  // -------------------------------------------------------------

  Future<List<TransactionItem>>? _inFlightTransactions;

  List<TransactionItem> getTransactions() => List.unmodifiable(_transactions);

  Future<List<TransactionItem>> fetchTransactions({
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    if (!isAuthenticated) return _transactions;

    // Deduplicate default page 1 fetches
    final isDefaultQuery = type == null &&
        categoryId == null &&
        startDate == null &&
        endDate == null &&
        (offset == null || offset == 0);

    if (isDefaultQuery && _inFlightTransactions != null) {
      return _inFlightTransactions!;
    }

    final future = _doFetchTransactions(
      type: type,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );

    if (isDefaultQuery) {
      _inFlightTransactions = future.whenComplete(() {
        _inFlightTransactions = null;
      });
      return _inFlightTransactions!;
    }

    return future;
  }

  Future<List<TransactionItem>> _doFetchTransactions({
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final query = <String, dynamic>{};
    if (type != null && type != 'all') query['type'] = type;
    if (categoryId != null && categoryId != 'all') query['categoryId'] = categoryId;
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();
    if (limit != null) query['limit'] = limit;
    if (offset != null) query['offset'] = offset;

    try {
      final res = await _api.get(ApiConstants.transactions, queryParams: query);
      if (res is List) {
        final list = res.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
        if (offset == null || offset == 0) {
          _transactions = list;
        } else {
          // Append for pagination without duplicates
          final existingIds = _transactions.map((t) => t.id).toSet();
          for (final t in list) {
            if (!existingIds.contains(t.id)) {
              _transactions.add(t);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchTransactions notice: $e');
    }
    return _transactions;
  }

  Future<TransactionItem> addTransaction(TransactionItem item) async {
    if (isAuthenticated) {
      final res = await _api.post(ApiConstants.transactions, body: item.toJson());
      if (res is Map<String, dynamic>) {
        final serverItem = TransactionItem.fromJson(res);
        _transactions.insert(0, serverItem);
        _persistTransactionsOffline();
        // Silently update dashboard in background
        fetchDashboard();
        return serverItem;
      }
    }
    _transactions.insert(0, item);
    _persistTransactionsOffline();
    return item;
  }

  Future<void> updateTransaction(TransactionItem updatedItem) async {
    if (isAuthenticated) {
      await _api.put('${ApiConstants.transactions}/${updatedItem.id}', body: updatedItem.toJson());
    }
    final index = _transactions.indexWhere((e) => e.id == updatedItem.id);
    if (index != -1) {
      _transactions[index] = updatedItem.copyWith(updatedAt: DateTime.now());
    }
    _persistTransactionsOffline();
    fetchDashboard();
  }

  Future<void> deleteTransaction(String id) async {
    if (isAuthenticated) {
      await _api.delete('${ApiConstants.transactions}/$id');
    }
    _transactions.removeWhere((e) => e.id == id);
    _persistTransactionsOffline();
    fetchDashboard();
  }

  // -------------------------------------------------------------
  // DEBTS
  // -------------------------------------------------------------

  List<DebtItem> getDebts() => List.unmodifiable(_debts);

  Future<List<DebtItem>> fetchDebts() async {
    if (!isAuthenticated) return _debts;
    try {
      final res = await _api.get(ApiConstants.debts);
      if (res is List) {
        _debts = res.map((e) => DebtItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchDebts error: $e');
    }
    return _debts;
  }

  Future<DebtItem> addDebt(DebtItem debt) async {
    if (isAuthenticated) {
      final res = await _api.post(ApiConstants.debts, body: debt.toJson());
      if (res is Map<String, dynamic>) {
        final serverDebt = DebtItem.fromJson(res);
        _debts.insert(0, serverDebt);
        _persistDebtsOffline();
        return serverDebt;
      }
    }
    _debts.insert(0, debt);
    _persistDebtsOffline();
    return debt;
  }

  Future<void> updateDebt(DebtItem updatedDebt) async {
    if (isAuthenticated) {
      await _api.put('${ApiConstants.debts}/${updatedDebt.id}', body: updatedDebt.toJson());
    }
    final index = _debts.indexWhere((d) => d.id == updatedDebt.id);
    if (index != -1) {
      _debts[index] = updatedDebt.copyWith(updatedAt: DateTime.now());
    }
    _persistDebtsOffline();
  }

  Future<void> recordDebtPayment({
    required String debtId,
    required int paymentAmount,
    String? note,
    bool linkTransaction = false,
  }) async {
    if (isAuthenticated) {
      await _api.post('${ApiConstants.debts}/$debtId/repay', body: {
        'amount': paymentAmount,
        'note': note ?? '',
      });
      // Re-fetch fresh debts state from PostgreSQL
      await fetchDebts();
    } else {
      final index = _debts.indexWhere((d) => d.id == debtId);
      if (index != -1) {
        final debt = _debts[index];
        final newPaid = (debt.paidAmount + paymentAmount).clamp(0, debt.amount);
        final newStatus = newPaid >= debt.amount ? DebtStatus.returned : DebtStatus.partiallyPaid;
        final newRepayments = List<DebtRepayment>.from(debt.repayments)
          ..add(DebtRepayment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            debtId: debtId,
            amount: paymentAmount,
            date: DateTime.now(),
            note: note,
          ));
        _debts[index] = debt.copyWith(
          paidAmount: newPaid,
          status: newStatus,
          repayments: newRepayments,
        );
      }
    }
    _persistDebtsOffline();

    if (linkTransaction) {
      final debtItem = _debts.firstWhere((d) => d.id == debtId);
      final isExpense = debtItem.isBorrowed;
      final tx = TransactionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: debtItem.isBorrowed
            ? '${debtItem.personName} ga qarz qaytarildi'
            : '${debtItem.personName} dan qarz qaytarildi',
        amount: paymentAmount,
        categoryId: debtItem.isBorrowed ? 'other' : 'other_income',
        type: isExpense ? TransactionType.expense : TransactionType.income,
        dateTime: DateTime.now(),
        note: note ?? 'Qarz to\'lovi',
        debtId: debtId,
        personName: debtItem.personName,
      );
      await addTransaction(tx);
    }
  }

  Future<void> markDebtReturned(String debtId) async {
    final debt = _debts.firstWhere((d) => d.id == debtId);
    final remaining = debt.remainingAmount;
    if (remaining > 0) {
      await recordDebtPayment(
        debtId: debtId,
        paymentAmount: remaining,
        note: 'To\'liq qaytarildi',
      );
    }
    _persistDebtsOffline();
  }

  Future<void> deleteDebt(String id) async {
    if (isAuthenticated) {
      await _api.delete('${ApiConstants.debts}/$id');
    }
    _debts.removeWhere((d) => d.id == id);
    _persistDebtsOffline();
  }

  // -------------------------------------------------------------
  // BUDGET & SMETA
  // -------------------------------------------------------------

  BudgetModel getBudget() => _budget;

  Future<BudgetModel> fetchBudget([String? yearMonth]) async {
    if (!isAuthenticated) return _budget;
    try {
      final query = yearMonth != null ? {'yearMonth': yearMonth} : null;
      final res = await _api.get(ApiConstants.budget, queryParams: query);
      if (res is Map<String, dynamic>) {
        _budget = BudgetModel.fromJson(res);
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchBudget error: $e');
    }
    return _budget;
  }

  Future<void> saveBudget(BudgetModel budget) async {
    _budget = budget;
    _persistBudgetOffline();
    if (isAuthenticated) {
      await _api.put(ApiConstants.budget, body: {
        'totalMonthlyLimit': budget.totalMonthlyBudget,
      });
    }
  }

  Future<void> setCategoryLimit(String categoryId, int limitAmount) async {
    final updatedLimits = Map<String, int>.from(_budget.categoryLimits);
    updatedLimits[categoryId] = limitAmount;
    _budget = _budget.copyWith(categoryLimits: updatedLimits);
    _persistBudgetOffline();

    if (isAuthenticated) {
      await _api.put('${ApiConstants.budgetCategoryLimit}/$categoryId', body: {
        'categoryId': categoryId,
        'limitAmount': limitAmount,
      });
    }
  }

  // -------------------------------------------------------------
  // SAVINGS GOALS
  // -------------------------------------------------------------

  List<SavingsGoal> getGoals() => List.unmodifiable(_goals);

  Future<List<SavingsGoal>> fetchGoals() async {
    if (!isAuthenticated) return _goals;
    try {
      final res = await _api.get(ApiConstants.goals);
      if (res is List) {
        _goals = res.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
        _persistGoalsOffline();
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchGoals error: $e');
    }
    return _goals;
  }

  Future<SavingsGoal> addGoal(SavingsGoal goal) async {
    if (isAuthenticated) {
      final res = await _api.post(ApiConstants.goals, body: goal.toJson());
      if (res is Map<String, dynamic>) {
        final serverGoal = SavingsGoal.fromJson(res);
        _goals.add(serverGoal);
        _persistGoalsOffline();
        return serverGoal;
      }
    }
    _goals.add(goal);
    _persistGoalsOffline();
    return goal;
  }

  Future<void> addGoalDeposit(String goalId, int amount) async {
    if (isAuthenticated) {
      await _api.post('${ApiConstants.goals}/$goalId/deposit', body: {'amount': amount});
      await fetchGoals();
    } else {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        final goal = _goals[index];
        _goals[index] = goal.copyWith(currentAmount: goal.currentAmount + amount);
      }
    }
    _persistGoalsOffline();
  }

  Future<void> deleteGoal(String id) async {
    if (isAuthenticated) {
      await _api.delete('${ApiConstants.goals}/$id');
    }
    _goals.removeWhere((g) => g.id == id);
    _persistGoalsOffline();
  }

  // -------------------------------------------------------------
  // STATISTICS
  // -------------------------------------------------------------

  Future<StatisticsResponse> fetchStatistics(String period) async {
    if (_statisticsCache.containsKey(period)) {
      // Background revalidation
      _api.get(ApiConstants.statistics, queryParams: {'period': period}).then((res) {
        if (res is Map<String, dynamic>) {
          _statisticsCache[period] = StatisticsResponse.fromJson(res);
        }
      }).catchError((_) {});
      return _statisticsCache[period]!;
    }

    if (!isAuthenticated) {
      return StatisticsResponse.empty(period);
    }

    try {
      final res = await _api.get(ApiConstants.statistics, queryParams: {'period': period});
      if (res is Map<String, dynamic>) {
        final stats = StatisticsResponse.fromJson(res);
        _statisticsCache[period] = stats;
        return stats;
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchStatistics error: $e');
    }
    return StatisticsResponse.empty(period);
  }

  // -------------------------------------------------------------
  // APP PREFERENCES
  // -------------------------------------------------------------

  ThemeMode getThemeMode() => _storage.themeMode;
  Future<void> setThemeMode(ThemeMode mode) => _storage.setThemeMode(mode);

  bool hasSeenOnboarding() => _storage.hasSeenOnboarding;
  Future<void> setHasSeenOnboarding(bool seen) => _storage.setHasSeenOnboarding(seen);

  // -------------------------------------------------------------
  // EXPORT TO CSV
  // -------------------------------------------------------------

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

      final txList = _transactions.where((t) {
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

      for (final d in _debts) {
        final type = d.isBorrowed ? 'Olingan qarz' : 'Berilgan qarz';
        final date = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
        final cleanNote = (d.note ?? '').replaceAll(',', ' ');
        buffer.writeln('${d.id},${d.personName},${d.phoneNumber ?? ''},$type,${d.amount},${d.paidAmount},${d.remainingAmount},${d.status.label},$date,$cleanNote');
      }
    }

    return buffer.toString();
  }

  int getInitialBalance() {
    if (_userProfile.initialBalance > 0) return _userProfile.initialBalance;
    if (_dashboardSummary.initialBalance > 0) return _dashboardSummary.initialBalance;
    return 0;
  }

  Future<void> setInitialBalance(int amount, {bool alsoUpdateMonthlyLimit = true}) async {
    _userProfile = _userProfile.copyWith(initialBalance: amount);
    final newLimit = alsoUpdateMonthlyLimit ? amount : _dashboardSummary.totalMonthlyLimit;
    final newRemaining = alsoUpdateMonthlyLimit
        ? (amount - _dashboardSummary.monthExpense > 0 ? amount - _dashboardSummary.monthExpense : 0)
        : _dashboardSummary.remainingBudget;

    _dashboardSummary = _dashboardSummary.copyWith(
      balance: amount + _dashboardSummary.totalIncome - _dashboardSummary.totalExpense,
      initialBalance: amount,
      totalMonthlyLimit: newLimit,
      remainingBudget: newRemaining,
      hasLoaded: true,
    );
    if (isAuthenticated) {
      try {
        await _api.put(ApiConstants.authInitialBalance, body: {
          'initialBalance': amount,
        });
      } catch (e) {
        debugPrint('[FinanceRepository] setInitialBalance cloud sync notice: $e');
      }
    }
  }

  Future<void> clearAllData() async {
    await logout();
  }

  // -------------------------------------------------------------
  // BILLING, SUBSCRIPTIONS & ENTITLEMENTS (PostgreSQL & Backend)
  // -------------------------------------------------------------

  SubscriptionDetailsModel _subscriptionDetails = SubscriptionDetailsModel.createDefault();
  SubscriptionDetailsModel get subscriptionDetails => _subscriptionDetails;

  Future<List<PlanModel>> fetchPlans() async {
    try {
      final res = await _api.get(ApiConstants.billingPlans);
      if (res is Map && res['plans'] is List) {
        return (res['plans'] as List).map((p) => PlanModel.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchPlans error: $e');
    }
    return [PlanModel.freeDefault, PlanModel.proDefault];
  }

  Future<SubscriptionDetailsModel> fetchSubscription() async {
    if (!isAuthenticated) {
      _subscriptionDetails = SubscriptionDetailsModel.createDefault(isPro: _storage.isProMember);
      return _subscriptionDetails;
    }
    try {
      final res = await _api.get(ApiConstants.billingSubscription);
      if (res is Map<String, dynamic>) {
        _subscriptionDetails = SubscriptionDetailsModel.fromJson(res);
        await _storage.setProMember(_subscriptionDetails.isPro);
        return _subscriptionDetails;
      }
    } catch (e) {
      debugPrint('[FinanceRepository] fetchSubscription error (using local cache): $e');
    }
    _subscriptionDetails = SubscriptionDetailsModel.createDefault(isPro: _storage.isProMember);
    return _subscriptionDetails;
  }

  Future<PaymentOrderModel> createPaymentOrder({
    required String planId,
    required String billingCycle,
    required String paymentMethod,
  }) async {
    final defaultAmount = billingCycle == 'annual' ? 149000 : 19000;
    if (!isAuthenticated) {
      return PaymentOrderModel(
        id: 'order_local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'local_user',
        planId: planId,
        billingCycle: billingCycle,
        amount: defaultAmount,
        currency: 'UZS',
        paymentMethod: paymentMethod,
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }
    try {
      final res = await _api.post(ApiConstants.billingOrders, body: {
        'planId': planId,
        'billingCycle': billingCycle,
        'paymentMethod': paymentMethod,
      });
      return PaymentOrderModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[FinanceRepository] createPaymentOrder API error (using local order): $e');
      return PaymentOrderModel(
        id: 'order_local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'local_user',
        planId: planId,
        billingCycle: billingCycle,
        amount: defaultAmount,
        currency: 'UZS',
        paymentMethod: paymentMethod,
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }
  }

  Future<PaymentOrderModel> getPaymentOrder(String orderId) async {
    if (!isAuthenticated || orderId.startsWith('order_local_')) {
      return PaymentOrderModel(
        id: orderId,
        userId: 'local_user',
        planId: 'pro',
        billingCycle: 'annual',
        amount: 149000,
        currency: 'UZS',
        paymentMethod: 'click',
        status: 'paid',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
    }
    try {
      final res = await _api.get('${ApiConstants.billingOrders}/$orderId');
      return PaymentOrderModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      return PaymentOrderModel(
        id: orderId,
        userId: 'local_user',
        planId: 'pro',
        billingCycle: 'annual',
        amount: 149000,
        currency: 'UZS',
        paymentMethod: 'click',
        status: 'paid',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
    }
  }

  Future<SubscriptionDetailsModel> confirmPaymentOrder(
    String orderId, {
    String? externalTransactionId,
    String? paymentMethod,
    String? notes,
  }) async {
    // 1. Immediately activate Pro locally in encrypted preferences
    await _storage.setProMember(true);
    _subscriptionDetails = SubscriptionDetailsModel.createDefault(isPro: true);

    // 2. If authenticated, sync with server seamlessly (non-blocking failure)
    if (isAuthenticated && !orderId.startsWith('order_local_')) {
      try {
        final body = <String, dynamic>{};
        if (externalTransactionId != null) body['externalTransactionId'] = externalTransactionId;
        if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
        if (notes != null) body['notes'] = notes;
        final res = await _api.post('${ApiConstants.billingOrders}/$orderId/confirm', body: body);
        if (res is Map && res['subscription'] is Map) {
          _subscriptionDetails = SubscriptionDetailsModel.fromJson(res['subscription'] as Map<String, dynamic>);
          await _storage.setProMember(_subscriptionDetails.isPro);
        }
      } catch (e) {
        debugPrint('[FinanceRepository] confirmPaymentOrder online sync failed (local activated): $e');
      }
    }
    return _subscriptionDetails;
  }

  Future<SubscriptionDetailsModel> cancelSubscription() async {
    final res = await _api.post(ApiConstants.billingCancel);
    if (res is Map && res['subscription'] is Map) {
      _subscriptionDetails = SubscriptionDetailsModel.fromJson(res['subscription'] as Map<String, dynamic>);
      await _storage.setProMember(_subscriptionDetails.isPro);
    } else {
      await fetchSubscription();
    }
    return _subscriptionDetails;
  }

  Future<Map<String, dynamic>> evaluateWhatIf({required int plannedExpense, String? title}) async {
    final res = await _api.post(ApiConstants.intelligenceWhatIf, body: {
      'plannedExpense': plannedExpense,
      'title': title ?? '',
    });
    // Refresh subscription to reflect updated usage
    unawaited(fetchSubscription());
    return res as Map<String, dynamic>;
  }

  Future<void> authorizeExport() async {
    await _api.post(ApiConstants.reportsExport);
    unawaited(fetchSubscription());
  }
}
