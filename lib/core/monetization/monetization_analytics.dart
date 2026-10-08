import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_features.dart';

/// Clean analytics and conversion measurement abstraction.
/// Decoupled from third-party SDKs; provides structured event dispatching
/// for growth, funnels, and monetization diagnostics.
class MonetizationAnalyticsService {
  static final MonetizationAnalyticsService instance = MonetizationAnalyticsService._();
  MonetizationAnalyticsService._();

  void logPaywallView({required String featureKey, String? source}) {
    debugPrint('[Analytics] paywall_viewed: source=${source ?? 'default'}, feature=$featureKey');
  }

  void logPlanSelected({required String planId, required String cycle, required int priceUzs}) {
    debugPrint('[Analytics] plan_selected: plan=$planId, cycle=$cycle, price=$priceUzs UZS');
  }

  void logCheckoutStarted({
    required String planId,
    required String cycle,
    required String provider,
    required int amountUzs,
    String? orderId,
  }) {
    debugPrint('[Analytics] checkout_started: orderId=$orderId, plan=$planId, provider=$provider, amount=$amountUzs UZS');
  }

  void logPaymentSuccess({
    String? orderId,
    required String planId,
    required String provider,
    required int amountUzs,
  }) {
    debugPrint('[Analytics] payment_success: orderId=$orderId, plan=$planId, provider=$provider, amount=$amountUzs UZS');
  }

  void logPaymentFailure({
    String? orderId,
    required String reason,
  }) {
    debugPrint('[Analytics] payment_failure: orderId=$orderId, reason=$reason');
  }

  void trackFeatureLockedAccessed({required AppFeature feature}) {
    debugPrint('[Analytics] feature_locked_accessed: feature=${feature.key}');
  }

  void trackSyncTriggered({required bool isPro, required bool isSuccess}) {
    debugPrint('[Analytics] sync_triggered: isPro=$isPro, isSuccess=$isSuccess');
  }
}

final monetizationAnalyticsProvider = Provider<MonetizationAnalyticsService>((ref) {
  return MonetizationAnalyticsService.instance;
});
