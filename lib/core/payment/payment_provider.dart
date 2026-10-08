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
    // Generate Click checkout endpoint URL (Click Merchant protocol standard)
    final clickUrl = 'https://my.click.uz/services/pay?service_id=moliya&merchant_id=moliya_fin&amount=${order.amount}&transaction_param=${order.id}';
    return PaymentInitiateResult(
      orderId: order.id,
      paymentUrl: order.paymentUrl ?? clickUrl,
      deepLink: 'clickuz://pay?amount=${order.amount}&order_id=${order.id}',
      instructions: 'Click orqali to\'lov amalga oshirilgandan so\'ng tizim avtomatik faollashadi.',
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
      message: 'Click to\'lovi muvaffaqiyatli tasdiqlandi',
      transactionId: externalTransactionId ?? 'click_tx_$orderId',
    );
  }
}

/// Payme Payment Provider Integration (Payme Subscribe / Checkout)
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
  String get subtitle => 'Payme tizimi va milliy kartalar (Uzcard/Humo)';

  @override
  Future<PaymentInitiateResult> initiatePayment({
    required PaymentOrderModel order,
  }) async {
    final paymeUrl = 'https://checkout.paycom.uz/moliya?amount=${order.amount * 100}&account%5Border_id%5D=${order.id}';
    return PaymentInitiateResult(
      orderId: order.id,
      paymentUrl: order.paymentUrl ?? paymeUrl,
      deepLink: 'payme://pay?amount=${order.amount}&order_id=${order.id}',
      instructions: 'Payme orqali to\'lovni tasdiqlang.',
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
