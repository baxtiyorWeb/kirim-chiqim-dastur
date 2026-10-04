import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Storage Service exclusively for Session Credentials, Auth Tokens, and UI Preferences.
/// In strict accordance with the Production Fintech Architecture:
/// NO BUSINESS OR FINANCIAL DATA (transactions, debts, budgets, goals, balances)
/// IS PERSISTED LOCALLY ON THE DEVICE. The PostgreSQL database is the single source of truth.
class LocalStorageService {
  // Session & Authentication Keys ONLY
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _themeModeKey = 'app_theme_mode';

  // Legacy keys to purge immediately to ensure zero local business data persistence
  static const List<String> _legacyBusinessKeys = [
    'app_transactions',
    'app_debts',
    'app_budget',
    'app_goals',
    'app_initial_balance',
  ];

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service._purgeLegacyBusinessData();
    return service;
  }

  /// Purges any legacy cached financial data from device storage
  Future<void> _purgeLegacyBusinessData() async {
    for (final key in _legacyBusinessKeys) {
      if (_prefs.containsKey(key)) {
        await _prefs.remove(key);
      }
    }
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

  int _sessionInitialBalance = 0;
  int getInitialBalance() => _sessionInitialBalance;
  Future<void> saveInitialBalance(int amount) async {
    _sessionInitialBalance = amount;
  }

  /// Secure session clear on logout
  Future<void> clearAllData() async {
    await _prefs.remove(_authTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userPhoneKey);
    _sessionInitialBalance = 0;
    await _purgeLegacyBusinessData();
  }

  Future<void> clearAll() => clearAllData();
}
