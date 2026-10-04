import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL
  // Default for physical Android devices: host IP or localhost (with adb reverse)
  static const String _defaultHost = '192.168.104.192'; // PC IP on LAN
  static const String _defaultPort = '8080';

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }
    if (Platform.isAndroid) {
      // With ADB reverse tcp:8080 tcp:8080, localhost works directly on USB-connected device.
      // 192.168.104.192 works over Wi-Fi.
      return 'http://$_defaultHost:$_defaultPort';
    }
    return 'http://localhost:$_defaultPort';
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
  static const String authDeleteAccount = '/api/v1/auth/account';

  static const String transactions = '/api/v1/transactions';
  static const String dashboard = '/api/v1/dashboard';
  static const String statistics = '/api/v1/statistics';
  static const String budget = '/api/v1/budget';
  static const String budgetCategoryLimit = '/api/v1/budget/categories';
  static const String debts = '/api/v1/debts';
  static const String goals = '/api/v1/goals';
}
