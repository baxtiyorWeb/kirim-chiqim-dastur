class ApiConstants {
  // Live Production Backend on Render
  static const String productionBaseUrl = 'https://kirim-chiqim-dastur.onrender.com';

  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    // Live production server on Render
    return productionBaseUrl;
  }

  // Endpoints
  static const String health = '/health';
  static const String authRegister = '/api/v1/auth/register';
  static const String authLogin = '/api/v1/auth/login';
  static const String authSendOtp = '/api/v1/auth/send-otp';
  static const String authVerifyOtp = '/api/v1/auth/verify-otp';
  static const String authCompleteRegistration = '/api/v1/auth/complete-registration';
  static const String authMe = '/api/v1/auth/me';
  static const String authProfile = '/api/v1/auth/profile';
  static const String authInitialBalance = '/api/v1/auth/initial-balance';
  static const String authDeleteAccount = '/api/v1/auth/account';

  static const String transactions = '/api/v1/transactions';
  static const String dashboard = '/api/v1/dashboard';
  static const String statistics = '/api/v1/statistics';
  static const String budget = '/api/v1/budget';
  static const String budgetCategoryLimit = '/api/v1/budget/categories';
  static const String debts = '/api/v1/debts';
  static const String goals = '/api/v1/goals';
}
