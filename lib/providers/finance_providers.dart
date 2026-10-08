import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_item.dart';
import '../data/models/debt_item.dart';
import '../data/models/budget_model.dart';
import '../data/models/savings_goal.dart';
import '../data/models/dashboard_summary.dart';
import '../data/models/statistics_response.dart';
import '../data/models/user_profile.dart';
import '../data/models/billing_models.dart';
import '../data/repositories/finance_repository.dart';
import '../data/services/local_storage_service.dart';

// Storage & Repository Providers
final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in ProviderScope');
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  final repo = FinanceRepository(storage);
  repo.onLogout = () {
    // Postpone provider reset to the next frame to prevent circular dependency
    // collisions during active build or microtask response handling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetAllFinanceProviders(ref);
    });
  };
  return repo;
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
  int _requestGeneration = 0;

  @override
  UserProfile build() {
    final repo = ref.watch(financeRepositoryProvider);
    // Asynchronously fetch fresh profile if authenticated
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.userProfile;
  }

  void reset([UserProfile? profile]) {
    _requestGeneration++;
    state = profile ?? UserProfile.guest();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = UserProfile.guest();
      return;
    }
    final currentGen = ++_requestGeneration;
    try {
      final profile = await repo.fetchProfile();
      if (currentGen == _requestGeneration && repo.isAuthenticated) {
        state = profile;
      }
    } catch (_) {
      // Prevent unhandled network failure from corrupting state
    }
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
  int _requestGeneration = 0;
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  @override
  DashboardSummary build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getDashboardSummary();
  }

  void reset([DashboardSummary? summary]) {
    _requestGeneration++;
    _isRefreshing = false;
    state = summary ?? DashboardSummary.empty();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = DashboardSummary.empty();
      return;
    }

    _isRefreshing = true;
    final currentGen = ++_requestGeneration;

    try {
      final summary = await repo.fetchDashboard();
      if (currentGen == _requestGeneration) {
        if (repo.isAuthenticated) {
          state = summary;
        } else {
          state = DashboardSummary.empty();
        }
      }
    } catch (_) {
      // NEVER blank existing valid financial data on network error
    } finally {
      if (currentGen == _requestGeneration) {
        _isRefreshing = false;
      }
    }
  }

  void updateOptimistically(DashboardSummary optimistic) {
    state = optimistic;
  }
}

final dashboardSummaryProvider =
    NotifierProvider<DashboardSummaryNotifier, DashboardSummary>(() {
  return DashboardSummaryNotifier();
});

// Transactions Notifier (Real PostgreSQL List via /api/v1/transactions)
class TransactionsNotifier extends Notifier<List<TransactionItem>> {
  int _requestGeneration = 0;
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  @override
  List<TransactionItem> build() {
    final repo = ref.watch(financeRepositoryProvider);
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return repo.getTransactions();
  }

  void reset([List<TransactionItem>? list]) {
    _requestGeneration++;
    _isRefreshing = false;
    state = list ?? [];
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = [];
      return;
    }

    _isRefreshing = true;
    final currentGen = ++_requestGeneration;

    try {
      final list = await repo.fetchTransactions();
      if (currentGen == _requestGeneration) {
        if (repo.isAuthenticated) {
          state = list;
        } else {
          state = [];
        }
      }
    } catch (_) {
      // Keep existing items on failure
    } finally {
      if (currentGen == _requestGeneration) {
        _isRefreshing = false;
      }
    }
  }

  Future<void> addTransaction(TransactionItem item) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.addTransaction(item);
    state = repo.getTransactions();
    ref.read(dashboardSummaryProvider.notifier).updateOptimistically(repo.getDashboardSummary());
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.updateTransaction(item);
    state = repo.getTransactions();
    ref.read(dashboardSummaryProvider.notifier).updateOptimistically(repo.getDashboardSummary());
    ref.read(dashboardSummaryProvider.notifier).refresh();
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteTransaction(id);
    state = repo.getTransactions();
    ref.read(dashboardSummaryProvider.notifier).updateOptimistically(repo.getDashboardSummary());
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
  return dashboard.balance;
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

  void reset([List<DebtItem>? list]) {
    state = list ?? [];
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = [];
      return;
    }
    final list = await repo.fetchDebts();
    if (repo.isAuthenticated) {
      state = list;
    } else {
      state = [];
    }
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

  void reset([BudgetModel? budget]) {
    state = budget ?? BudgetModel.defaultBudget();
  }

  Future<void> refresh([String? yearMonth]) async {
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = BudgetModel.defaultBudget();
      return;
    }
    final budget = await repo.fetchBudget(yearMonth);
    if (repo.isAuthenticated) {
      state = budget;
    } else {
      state = BudgetModel.defaultBudget();
    }
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

  void reset([List<SavingsGoal>? list]) {
    state = list ?? [];
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = [];
      return;
    }
    final list = await repo.fetchGoals();
    if (repo.isAuthenticated) {
      state = list;
    } else {
      state = [];
    }
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

  void reset([StatisticsResponse? stats]) {
    state = stats ?? StatisticsResponse.empty(_currentPeriod);
  }

  Future<void> setPeriod(String period) async {
    _currentPeriod = period;
    await refresh();
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = StatisticsResponse.empty(_currentPeriod);
      return;
    }
    final res = await repo.fetchStatistics(_currentPeriod);
    if (repo.isAuthenticated) {
      state = res;
    } else {
      state = StatisticsResponse.empty(_currentPeriod);
    }
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

  void reset() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
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

  void reset([int? balance]) {
    state = balance ?? 0;
  }

  Future<void> setInitialBalance(int amount, {bool syncWithBudget = true}) async {
    final repo = ref.read(financeRepositoryProvider);
    await repo.setInitialBalance(amount, alsoUpdateMonthlyLimit: syncWithBudget);
    state = amount;

    if (syncWithBudget) {
      try {
        await ref.read(budgetProvider.notifier).updateMonthlyBudget(amount);
      } catch (e) {
        debugPrint('[InitialBalanceNotifier] syncWithBudget notice: $e');
      }
    }

    // Push updated ledger to dashboard summary optimistically and sync with server
    final summary = repo.getDashboardSummary();
    ref.read(dashboardSummaryProvider.notifier).updateOptimistically(summary);
    try {
      await ref.read(dashboardSummaryProvider.notifier).refresh();
    } catch (_) {}
  }

  /// Sets the unified financial baseline (both initial balance and monthly budget limit)
  Future<void> setInitialFinancialBase(int amount) async {
    await setInitialBalance(amount, syncWithBudget: true);
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
  final dash = ref.watch(dashboardSummaryProvider);
  if (dash.totalBorrowed > 0 ||
      dash.totalLent > 0 ||
      dash.remainingBorrowed > 0 ||
      dash.remainingLent > 0) {
    return DebtsSummary(
      totalBorrowed: dash.totalBorrowed,
      remainingBorrowed: dash.remainingBorrowed,
      totalLent: dash.totalLent,
      remainingLent: dash.remainingLent,
    );
  }

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

// -------------------------------------------------------------
// MULTI-ACCOUNT SESSION ISOLATION & LIFECYCLE COORDINATION
// -------------------------------------------------------------

/// Completely purges all in-memory Riverpod financial state.
/// Ensures zero data leakage between user sessions.
void resetAllFinanceProviders(dynamic ref) {
  ref.read(userProfileProvider.notifier).reset();
  ref.read(dashboardSummaryProvider.notifier).reset();
  ref.read(transactionsProvider.notifier).reset();
  ref.read(budgetProvider.notifier).reset();
  ref.read(debtsProvider.notifier).reset();
  ref.read(goalsProvider.notifier).reset();
  ref.read(statisticsProvider.notifier).reset();
  ref.read(initialBalanceProvider.notifier).reset();
  ref.read(selectedDateFilterProvider.notifier).reset();
  ref.read(subscriptionProvider.notifier).reset();
}

/// Synchronizes all Riverpod notifiers with the authenticated user's freshly fetched PostgreSQL data.
void syncAllFinanceProviders(dynamic ref) {
  final repo = ref.read(financeRepositoryProvider) as FinanceRepository;
  ref.read(userProfileProvider.notifier).reset(repo.userProfile);
  ref.read(dashboardSummaryProvider.notifier).reset(repo.getDashboardSummary());
  ref.read(transactionsProvider.notifier).reset(repo.getTransactions());
  ref.read(budgetProvider.notifier).reset(repo.getBudget());
  ref.read(debtsProvider.notifier).reset(repo.getDebts());
  ref.read(goalsProvider.notifier).reset(repo.getGoals());
  ref.read(initialBalanceProvider.notifier).reset(repo.getInitialBalance());
  ref.read(statisticsProvider.notifier).reset();
  ref.read(selectedDateFilterProvider.notifier).reset();
  ref.read(subscriptionProvider.notifier).refresh().ignore();
}

/// Full logout flow: clears storage, cancels in-flight requests, clears repository cache, and wipes all Riverpod notifiers.
Future<void> appLogout(dynamic ref) async {
  final repo = ref.read(financeRepositoryProvider) as FinanceRepository;
  await repo.logout();
  resetAllFinanceProviders(ref);
}

// ============================================================
// SUBSCRIPTION & ENTITLEMENTS STATE MANAGEMENT
// ============================================================

class SubscriptionNotifier extends Notifier<SubscriptionDetailsModel> {
  int _requestGeneration = 0;

  @override
  SubscriptionDetailsModel build() {
    final storage = ref.watch(localStorageProvider);
    final initial = SubscriptionDetailsModel.createDefault(isPro: storage.isProMember);
    final repo = ref.watch(financeRepositoryProvider);
    // Fetch authoritative state from PostgreSQL backend only when authenticated
    if (repo.isAuthenticated) {
      Future.microtask(() => refresh());
    }
    return initial;
  }

  Future<void> refresh() async {
    final repo = ref.read(financeRepositoryProvider);
    if (!repo.isAuthenticated) {
      state = SubscriptionDetailsModel.createDefault(isPro: false);
      return;
    }
    final currentGen = ++_requestGeneration;
    try {
      final updated = await repo.fetchSubscription();
      if (currentGen == _requestGeneration && repo.isAuthenticated) {
        state = updated;
      }
    } catch (_) {
      // Keep existing state on error
    }
  }

  void reset() {
    _requestGeneration++;
    state = SubscriptionDetailsModel.createDefault(isPro: false);
  }

  Future<PaymentOrderModel> createOrder({
    required String planId,
    required String billingCycle,
    required String paymentMethod,
  }) async {
    final repo = ref.read(financeRepositoryProvider);
    return await repo.createPaymentOrder(
      planId: planId,
      billingCycle: billingCycle,
      paymentMethod: paymentMethod,
    );
  }

  Future<void> confirmOrder(
    String orderId, {
    String? externalTransactionId,
    String? paymentMethod,
    String? notes,
  }) async {
    final repo = ref.read(financeRepositoryProvider);
    final updated = await repo.confirmPaymentOrder(
      orderId,
      externalTransactionId: externalTransactionId,
      paymentMethod: paymentMethod,
      notes: notes,
    );
    state = updated;
  }

  Future<void> cancelSubscription() async {
    final repo = ref.read(financeRepositoryProvider);
    final updated = await repo.cancelSubscription();
    state = updated;
  }

  Future<void> setProFallback(bool value) async {
    final storage = ref.read(localStorageProvider);
    await storage.setProMember(value);
    state = SubscriptionDetailsModel.createDefault(isPro: value);
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionDetailsModel>(() {
  return SubscriptionNotifier();
});

final availablePlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return await repo.fetchPlans();
});

/// Feature-based entitlement check provider
/// Usage: ref.watch(canUseFeatureProvider('what_if_simulator'))
final canUseFeatureProvider = Provider.family<bool, String>((ref, featureKey) {
  final sub = ref.watch(subscriptionProvider);
  return sub.canUse(featureKey);
});

final featureEntitlementProvider = Provider.family<EntitlementModel?, String>((ref, featureKey) {
  final sub = ref.watch(subscriptionProvider);
  return sub.getEntitlement(featureKey);
});

/// Pro Membership status provider (backward-compatible, driven by subscriptionProvider)
class ProMemberNotifier extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref.watch(subscriptionProvider);
    return sub.isPro;
  }

  Future<void> setPro(bool value) async {
    await ref.read(subscriptionProvider.notifier).setProFallback(value);
  }
}

final proMemberProvider = NotifierProvider<ProMemberNotifier, bool>(() {
  return ProMemberNotifier();
});


