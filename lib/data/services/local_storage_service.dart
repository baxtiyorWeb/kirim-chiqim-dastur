import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-First Secure Storage Service for Session Credentials, UI Preferences,
/// and Local Offline Persistence (Free tier offline & Pro tier local-first cache).
class LocalStorageService {
  // Session & Authentication Keys ONLY
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _themeModeKey = 'app_theme_mode';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // -------------------------------------------------------------
  // AUTHENTICATION & SESSION
  // -------------------------------------------------------------

  bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;
  String? get authToken => _prefs.getString(_authTokenKey);
  String? getAuthToken() => authToken;

  Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_authTokenKey);
    } else {
      await _prefs.setString(_authTokenKey, token);
    }
  }

  Future<void> saveAuthToken(String token) => setAuthToken(token);

  String? get currentUserId => _prefs.getString(_userIdKey);
  String? getUserId() => currentUserId;

  Future<void> setCurrentUserId(String? id) async {
    if (id == null) {
      await _prefs.remove(_userIdKey);
    } else {
      await _prefs.setString(_userIdKey, id);
    }
  }

  String? get currentUserEmail => _prefs.getString(_userEmailKey);
  String? getUserEmail() => currentUserEmail;

  Future<void> setCurrentUserEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(_userEmailKey);
    } else {
      await _prefs.setString(_userEmailKey, email);
    }
  }

  String? get currentUserName => _prefs.getString(_userNameKey);
  String? getUserName() => currentUserName;

  Future<void> setCurrentUserName(String? name) async {
    if (name == null) {
      await _prefs.remove(_userNameKey);
    } else {
      await _prefs.setString(_userNameKey, name);
    }
  }

  String? get currentUserPhone => _prefs.getString(_userPhoneKey);
  String? getUserPhone() => currentUserPhone;

  Future<void> setCurrentUserPhone(String? phone) async {
    if (phone == null) {
      await _prefs.remove(_userPhoneKey);
    } else {
      await _prefs.setString(_userPhoneKey, phone);
    }
  }

  Future<void> saveUserProfile({
    required String userId,
    String? email,
    required String fullName,
    String? phoneNumber,
  }) async {
    await setCurrentUserId(userId);
    if (email != null) await setCurrentUserEmail(email);
    await setCurrentUserName(fullName);
    if (phoneNumber != null) await setCurrentUserPhone(phoneNumber);
  }

  // -------------------------------------------------------------
  // APP PREFERENCES
  // -------------------------------------------------------------

  bool get hasSeenOnboarding => _prefs.getBool(_hasSeenOnboardingKey) ?? false;
  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_hasSeenOnboardingKey, value);
  }

  ThemeMode get themeMode {
    final modeStr = _prefs.getString(_themeModeKey);
    if (modeStr == 'light') return ThemeMode.light;
    if (modeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  // -------------------------------------------------------------
  // PRO MEMBERSHIP & SUBSCRIPTION STATUS
  // -------------------------------------------------------------
  static const String _isProKey = 'is_pro_member';

  bool get isProMember => _prefs.getBool(_isProKey) ?? false;
  Future<void> setProMember(bool value) async {
    await _prefs.setBool(_isProKey, value);
  }

  // -------------------------------------------------------------
  // GUIDED TOUR & PRODUCT EDUCATION PERSISTENCE
  // -------------------------------------------------------------
  static const String _completedToursPrefix = 'guide_tour_completed_';

  bool isTourCompleted(String tourId) {
    return _prefs.getBool('$_completedToursPrefix$tourId') ?? false;
  }

  Future<void> setTourCompleted(String tourId, [bool completed = true]) async {
    await _prefs.setBool('$_completedToursPrefix$tourId', completed);
  }

  Future<void> resetAllTours() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_completedToursPrefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  static const String _initialBalanceKey = 'initial_balance';

  int _sessionInitialBalance = 0;
  int getInitialBalance() {
    return _sessionInitialBalance;
  }

  Future<void> saveInitialBalance(int amount) async {
    _sessionInitialBalance = amount;
    // Explicitly ensure no un-scoped balance persists in SharedPreferences
    if (_prefs.containsKey(_initialBalanceKey)) {
      await _prefs.remove(_initialBalanceKey);
    }
  }

  static const String _evaluatedDecisionsKey = 'evaluated_decisions_count';

  int getEvaluatedDecisionsCount() {
    return _prefs.getInt(_evaluatedDecisionsKey) ?? 4;
  }

  Future<void> incrementEvaluatedDecisionsCount() async {
    final current = getEvaluatedDecisionsCount();
    await _prefs.setInt(_evaluatedDecisionsKey, current + 1);
  }

  // -------------------------------------------------------------
  // OFFLINE BUSINESS DATA PERSISTENCE (FREE & PRO LOCAL-FIRST)
  // -------------------------------------------------------------
  static const String _offlineTransactionsKey = 'offline_transactions';
  static const String _offlineDebtsKey = 'offline_debts';
  static const String _offlineBudgetKey = 'offline_budget';
  static const String _offlineGoalsKey = 'offline_goals';
  static const String _offlineInitialBalanceKey = 'offline_initial_balance';
  static const String _offlineLastSyncTimeKey = 'offline_last_sync_time';
  static const String _offlinePendingChangesKey = 'offline_pending_changes';

  List<Map<String, dynamic>> getOfflineTransactions() {
    final raw = _prefs.getString(_offlineTransactionsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveOfflineTransactions(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_offlineTransactionsKey, jsonEncode(list));
  }

  List<Map<String, dynamic>> getOfflineDebts() {
    final raw = _prefs.getString(_offlineDebtsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveOfflineDebts(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_offlineDebtsKey, jsonEncode(list));
  }

  Map<String, dynamic>? getOfflineBudget() {
    final raw = _prefs.getString(_offlineBudgetKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveOfflineBudget(Map<String, dynamic> budgetMap) async {
    await _prefs.setString(_offlineBudgetKey, jsonEncode(budgetMap));
  }

  List<Map<String, dynamic>> getOfflineGoals() {
    final raw = _prefs.getString(_offlineGoalsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveOfflineGoals(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_offlineGoalsKey, jsonEncode(list));
  }

  int getOfflineInitialBalance() {
    return _prefs.getInt(_offlineInitialBalanceKey) ?? _sessionInitialBalance;
  }

  Future<void> saveOfflineInitialBalance(int amount) async {
    _sessionInitialBalance = amount;
    await _prefs.setInt(_offlineInitialBalanceKey, amount);
  }

  DateTime? getLastSyncTime() {
    final raw = _prefs.getString(_offlineLastSyncTimeKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setString(_offlineLastSyncTimeKey, time.toIso8601String());
  }

  int getPendingChangesCount() {
    return _prefs.getInt(_offlinePendingChangesKey) ?? 0;
  }

  Future<void> setPendingChangesCount(int count) async {
    await _prefs.setInt(_offlinePendingChangesKey, count);
  }

  /// Secure session clear on logout
  Future<void> clearAllData() async {
    await _prefs.remove(_authTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userPhoneKey);
    await _prefs.remove(_initialBalanceKey);
    _sessionInitialBalance = 0;
  }

  Future<void> clearAll() => clearAllData();
}
