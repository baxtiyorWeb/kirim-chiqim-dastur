library;

/// Provider-agnostic payment domain types for Uzbekistan Fintech infrastructure.

enum PaymentProviderType {
  click,
  payme,
  uzum,
  demo;

  String get id {
    switch (this) {
      case PaymentProviderType.click:
        return 'click';
      case PaymentProviderType.payme:
        return 'payme';
      case PaymentProviderType.uzum:
        return 'uzum';
      case PaymentProviderType.demo:
        return 'manual';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentProviderType.click:
        return 'Click Up';
      case PaymentProviderType.payme:
        return 'Payme';
      case PaymentProviderType.uzum:
        return 'Uzum Bank';
      case PaymentProviderType.demo:
        return 'Tezkor Sinov (Sandbox)';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentProviderType.click:
        return 'Click ilovasi yoki USSD orqali to\'lash';
      case PaymentProviderType.payme:
        return 'Payme tizimi orqali xavfsiz to\'lov';
      case PaymentProviderType.uzum:
        return 'Uzum Bank orqali to\'g\'ridan-to\'g\'ri to\'lov';
      case PaymentProviderType.demo:
        return 'Rivojlantirish va tezkor tekshiruv uchun';
    }
  }

  static PaymentProviderType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'click':
        return PaymentProviderType.click;
      case 'payme':
        return PaymentProviderType.payme;
      case 'uzum':
        return PaymentProviderType.uzum;
      default:
        return PaymentProviderType.demo;
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  expired,
  canceled;

  bool get isPaid => this == PaymentStatus.paid;
  bool get isPending => this == PaymentStatus.pending;
  bool get isFailed => this == PaymentStatus.failed;
}

class PaymentOrderRequest {
  final String planId;
  final String billingCycle;
  final int amountUzs;
  final PaymentProviderType providerType;

  const PaymentOrderRequest({
    required this.planId,
    required this.billingCycle,
    required this.amountUzs,
    required this.providerType,
  });
}

class PaymentInitiateResult {
  final String orderId;
  final String? paymentUrl;
  final String? deepLink;
  final String? instructions;
  final bool requiresExternalAction;

  const PaymentInitiateResult({
    required this.orderId,
    this.paymentUrl,
    this.deepLink,
    this.instructions,
    this.requiresExternalAction = false,
  });
}

class PaymentVerificationResult {
  final bool isSuccess;
  final PaymentStatus status;
  final String message;
  final String? transactionId;
  final String? orderId;

  const PaymentVerificationResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.transactionId,
    this.orderId,
  });
}
