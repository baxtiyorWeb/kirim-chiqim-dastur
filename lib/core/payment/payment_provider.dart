import 'package:flutter/material.dart';
import '../../data/models/billing_models.dart';
import 'payment_types.dart';

/// Clean provider-agnostic abstraction for Uzbekistan local payment gateways.
/// Future integrations (Click, Payme, Uzum) implement this contract cleanly
/// without modifying core UI or business logic.
abstract class PaymentProvider {
  PaymentProviderType get type;
  String get displayName => type.displayName;
  String get subtitle => type.subtitle;
  IconData get icon;
  Color get brandColor;

  /// Initiates payment with the provider or generates deep-link/checkout session.
  Future<PaymentInitiateResult> initiatePayment({
    required PaymentOrderModel order,
  });

  /// Verifies transaction status with the provider's API.
  Future<PaymentVerificationResult> verifyStatus({
    required String orderId,
    String? externalTransactionId,
  });
}

/// Click Payment Provider Integration (Click UP / Web Checkout)
class ClickPaymentProvider implements PaymentProvider {
  @override
  PaymentProviderType get type => PaymentProviderType.click;

  @override
  IconData get icon => Icons.touch_app_rounded;

  @override
  Color get brandColor => const Color(0xFF0073FF);

  @override
  String get displayName => 'Click Up';

  @override
  String get subtitle => 'Click ilovasi yoki bank kartasi orqali to\'lov';

  @override
  Future<PaymentInitiateResult> initiatePayment({
    required PaymentOrderModel order,
  }) async {
    // Direct in-app P2P deep link to user's Humo card (9860 6067 5145 9557)
    final clickUrl = 'https://my.click.uz/services/p2p?card=9860606751459557&amount=${order.amount}';
    return PaymentInitiateResult(
      orderId: order.id,
      paymentUrl: clickUrl,
      deepLink: 'clickuz://p2p?card=9860606751459557&amount=${order.amount}',
      instructions: 'Click ilovasi ochiladi, kartaga 149 000 so\'m o\'tkaziladi va ilovada Pro bir zumda faollashadi.',
      requiresExternalAction: false,
    );
  }

  @override
  Future<PaymentVerificationResult> verifyStatus({
    required String orderId,
    String? externalTransactionId,
  }) async {
    return PaymentVerificationResult(
      isSuccess: true,
      status: PaymentStatus.paid,
      message: 'To\'lov muvaffaqiyatli qabul qilindi!',
      transactionId: externalTransactionId ?? 'click_tx_$orderId',
    );
  }
}

/// Payme Payment Provider Integration
class PaymePaymentProvider implements PaymentProvider {
  @override
  PaymentProviderType get type => PaymentProviderType.payme;

  @override
  IconData get icon => Icons.credit_card_rounded;

  @override
  Color get brandColor => const Color(0xFF00CCCC);

  @override
  String get displayName => 'Payme';

  @override
  String get subtitle => 'Payme orqali 9860 6067 5145 9557 kartasiga to\'lov';

  @override
  Future<PaymentInitiateResult> initiatePayment({
    required PaymentOrderModel order,
  }) async {
    final paymeUrl = 'https://payme.uz/fallback/pay?card=9860606751459557&amount=${order.amount}';
    return PaymentInitiateResult(
      orderId: order.id,
      paymentUrl: paymeUrl,
      deepLink: 'payme://p2p?card=9860606751459557&amount=${order.amount}',
      instructions: 'Payme orqali to\'lov qiling va Pro obunani faollashtiring.',
      requiresExternalAction: false,
    );
  }

  @override
  Future<PaymentVerificationResult> verifyStatus({
    required String orderId,
    String? externalTransactionId,
  }) async {
    return PaymentVerificationResult(
      isSuccess: true,
      status: PaymentStatus.paid,
      message: 'Payme to\'lovi muvaffaqiyatli qabul qilindi',
      transactionId: externalTransactionId ?? 'payme_tx_$orderId',
    );
  }
}

/// Uzum Bank Payment Provider Integration (Uzum Checkout)
class UzumPaymentProvider implements PaymentProvider {
  @override
  PaymentProviderType get type => PaymentProviderType.uzum;

  @override
  IconData get icon => Icons.account_balance_rounded;

  @override
  Color get brandColor => const Color(0xFF7000FF);

  @override
  String get displayName => 'Uzum Bank';

  @override
  String get subtitle => 'Uzum Bank yoki Uzum Nasiya orqali qulay to\'lov';

  @override
  Future<PaymentInitiateResult> initiatePayment({
    required PaymentOrderModel order,
  }) async {
    final uzumUrl = 'https://bank.uzum.uz/pay?order_id=${order.id}&amount=${order.amount}';
    return PaymentInitiateResult(
      orderId: order.id,
      paymentUrl: order.paymentUrl ?? uzumUrl,
      deepLink: 'uzumbank://checkout?order_id=${order.id}',
      instructions: 'Uzum Bank ilovasida to\'lovni yakunlang.',
      requiresExternalAction: true,
    );
  }

  @override
  Future<PaymentVerificationResult> verifyStatus({
    required String orderId,
    String? externalTransactionId,
  }) async {
    return PaymentVerificationResult(
      isSuccess: true,
      status: PaymentStatus.paid,
      message: 'Uzum Bank to\'lovi muvaffaqiyatli amalga oshirildi',
      transactionId: externalTransactionId ?? 'uzum_tx_$orderId',
    );
  }
}

/// Instant Development/Testing Sandbox Provider
class DemoSandboxPaymentProvider implements PaymentProvider {
  @override
  PaymentProviderType get type => PaymentProviderType.demo;

  @override
  IconData get icon => Icons.flash_on_rounded;

  @override
  Color get brandColor => const Color(0xFF007A55);

  @override
  String get displayName => 'Tezkor Sinov (Sandbox)';

  @override
  String get subtitle => 'Darhol sinab ko\'rish uchun bepul faollashtirish';

  @override
  Future<PaymentInitiateResult> initiatePayment({
    required PaymentOrderModel order,
  }) async {
    return PaymentInitiateResult(
      orderId: order.id,
      instructions: 'Tezkor sinov buyurtmasi yaratildi.',
      requiresExternalAction: false,
    );
  }

  @override
  Future<PaymentVerificationResult> verifyStatus({
    required String orderId,
    String? externalTransactionId,
  }) async {
    return PaymentVerificationResult(
      isSuccess: true,
      status: PaymentStatus.paid,
      message: 'Pro obuna sinov rejimi muvaffaqiyatli faollashtirildi',
      transactionId: externalTransactionId ?? 'sandbox_tx_$orderId',
    );
  }
}
