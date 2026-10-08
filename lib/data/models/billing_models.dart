import '../../core/monetization/app_features.dart';

class PlanModel {
  final String id;
  final String name;
  final String description;
  final int monthlyPrice;
  final int annualPrice;
  final String currency;
  final bool isActive;
  final int sortOrder;

  const PlanModel({
    required this.id,
    required this.name,
    this.description = '',
    this.monthlyPrice = 0,
    this.annualPrice = 0,
    this.currency = 'UZS',
    this.isActive = true,
    this.sortOrder = 0,
  });

  bool get isPro => id == 'pro';
  bool get isFree => id == 'free';

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String? ?? 'free',
      name: json['name'] as String? ?? 'Oddiy Reja',
      description: json['description'] as String? ?? '',
      monthlyPrice: (json['monthlyPrice'] as num?)?.toInt() ?? 0,
      annualPrice: (json['annualPrice'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'UZS',
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'monthlyPrice': monthlyPrice,
    'annualPrice': annualPrice,
    'currency': currency,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };

  static const PlanModel freeDefault = PlanModel(
    id: 'free',
    name: 'Oddiy Reja',
    description: 'Asosiy daromad-xarajat hisobi va cheklangan tahlillar',
    monthlyPrice: 0,
    annualPrice: 0,
  );

  static const PlanModel proDefault = PlanModel(
    id: 'pro',
    name: 'Pro Intellekt',
    description: 'Cheksiz AI qaror tahlili, dinamik xarajat me\'yori va eksport',
    monthlyPrice: 19000,
    annualPrice: 149000,
  );
}

class SubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final String status; // active, expired, canceled, trialing
  final String billingCycle; // none, monthly, annual, lifetime
  final DateTime startDate;
  final DateTime currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? canceledAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    this.status = 'active',
    this.billingCycle = 'none',
    required this.startDate,
    required this.currentPeriodStart,
    this.currentPeriodEnd,
    this.canceledAt,
  });

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isExpired => status == 'expired';
  bool get isCanceled => status == 'canceled';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      billingCycle: json['billingCycle'] as String? ?? 'none',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      currentPeriodStart: DateTime.tryParse(json['currentPeriodStart']?.toString() ?? '') ?? DateTime.now(),
      currentPeriodEnd: json['currentPeriodEnd'] != null ? DateTime.tryParse(json['currentPeriodEnd'].toString()) : null,
      canceledAt: json['canceledAt'] != null ? DateTime.tryParse(json['canceledAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'planId': planId,
    'status': status,
    'billingCycle': billingCycle,
    'startDate': startDate.toIso8601String(),
    'currentPeriodStart': currentPeriodStart.toIso8601String(),
    'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    'canceledAt': canceledAt?.toIso8601String(),
  };

  static SubscriptionModel createDefault(String userId) {
    final now = DateTime.now();
    return SubscriptionModel(
      id: 'sub_default',
      userId: userId,
      planId: 'free',
      status: 'active',
      billingCycle: 'none',
      startDate: now,
      currentPeriodStart: now,
    );
  }
}

class EntitlementModel {
  final String featureKey;
  final bool isEntitled;
  final int limit; // -1 = unlimited, 0 = locked, >0 = limit count
  final int currentUsage;
  final int remaining; // -1 = unlimited, 0 = exhausted
  final String period;

  const EntitlementModel({
    required this.featureKey,
    required this.isEntitled,
    required this.limit,
    required this.currentUsage,
    required this.remaining,
    required this.period,
  });

  bool get isUnlimited => limit == -1;
  bool get isExhausted => limit > 0 && remaining <= 0;

  factory EntitlementModel.fromJson(String key, Map<String, dynamic> json) {
    return EntitlementModel(
      featureKey: json['featureKey'] as String? ?? key,
      isEntitled: json['isEntitled'] as bool? ?? false,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      currentUsage: (json['currentUsage'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      period: json['period'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'featureKey': featureKey,
    'isEntitled': isEntitled,
    'limit': limit,
    'currentUsage': currentUsage,
    'remaining': remaining,
    'period': period,
  };
}

class SubscriptionDetailsModel {
  final PlanModel plan;
  final SubscriptionModel subscription;
  final bool isPro;
  final Map<String, EntitlementModel> entitlements;

  const SubscriptionDetailsModel({
    required this.plan,
    required this.subscription,
    required this.isPro,
    required this.entitlements,
  });

  bool canUse(String featureKey) {
    if (isPro) return true;
    final ent = entitlements[featureKey];
    if (ent == null) return false;
    return ent.isEntitled && (ent.isUnlimited || ent.remaining > 0);
  }

  bool hasAccess(AppFeature feature) {
    if (isPro) return true;
    if (feature == AppFeature.offlineStorage) return true;
    return canUse(feature.key);
  }

  EntitlementModel? getEntitlement(String featureKey) => entitlements[featureKey];

  EntitlementModel? getFeatureEntitlement(AppFeature feature) => entitlements[feature.key];

  factory SubscriptionDetailsModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] as Map<String, dynamic>? ?? {};
    final subJson = json['subscription'] as Map<String, dynamic>? ?? {};
    final isPro = json['isPro'] as bool? ?? false;

    final entMap = <String, EntitlementModel>{};
    if (json['entitlements'] is Map) {
      final raw = json['entitlements'] as Map<String, dynamic>;
      raw.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          entMap[k] = EntitlementModel.fromJson(k, v);
        }
      });
    }

    return SubscriptionDetailsModel(
      plan: PlanModel.fromJson(planJson),
      subscription: SubscriptionModel.fromJson(subJson),
      isPro: isPro,
      entitlements: entMap,
    );
  }

  static SubscriptionDetailsModel createDefault({bool isPro = false}) {
    final now = DateTime.now();
    final periodKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return SubscriptionDetailsModel(
      plan: isPro ? PlanModel.proDefault : PlanModel.freeDefault,
      subscription: SubscriptionModel(
        id: 'default',
        userId: 'local_user',
        planId: isPro ? 'pro' : 'free',
        status: 'active',
        startDate: now,
        currentPeriodStart: now,
      ),
      isPro: isPro,
      entitlements: {
        AppFeature.offlineStorage.key: EntitlementModel(
          featureKey: AppFeature.offlineStorage.key,
          isEntitled: true,
          limit: -1,
          currentUsage: 0,
          remaining: -1,
          period: periodKey,
        ),
        AppFeature.cloudSync.key: EntitlementModel(
          featureKey: AppFeature.cloudSync.key,
          isEntitled: isPro,
          limit: isPro ? -1 : 0,
          currentUsage: 0,
          remaining: isPro ? -1 : 0,
          period: periodKey,
        ),
        AppFeature.cloudBackup.key: EntitlementModel(
          featureKey: AppFeature.cloudBackup.key,
          isEntitled: isPro,
          limit: isPro ? -1 : 0,
          currentUsage: 0,
          remaining: isPro ? -1 : 0,
          period: periodKey,
        ),
        AppFeature.multiDeviceSync.key: EntitlementModel(
          featureKey: AppFeature.multiDeviceSync.key,
          isEntitled: isPro,
          limit: isPro ? -1 : 0,
          currentUsage: 0,
          remaining: isPro ? -1 : 0,
          period: periodKey,
        ),
        AppFeature.whatIfSimulator.key: EntitlementModel(
          featureKey: AppFeature.whatIfSimulator.key,
          isEntitled: true,
          limit: isPro ? -1 : 3,
          currentUsage: 0,
          remaining: isPro ? -1 : 3,
          period: periodKey,
        ),
        AppFeature.dynamicDailyBudget.key: EntitlementModel(
          featureKey: AppFeature.dynamicDailyBudget.key,
          isEntitled: true,
          limit: -1,
          currentUsage: 0,
          remaining: -1,
          period: periodKey,
        ),
        AppFeature.runwayForecast.key: EntitlementModel(
          featureKey: AppFeature.runwayForecast.key,
          isEntitled: isPro,
          limit: isPro ? -1 : 0,
          currentUsage: 0,
          remaining: isPro ? -1 : 0,
          period: periodKey,
        ),
        AppFeature.exportReports.key: EntitlementModel(
          featureKey: AppFeature.exportReports.key,
          isEntitled: true,
          limit: isPro ? -1 : 2,
          currentUsage: 0,
          remaining: isPro ? -1 : 2,
          period: periodKey,
        ),
        AppFeature.advancedAnalytics.key: EntitlementModel(
          featureKey: AppFeature.advancedAnalytics.key,
          isEntitled: isPro,
          limit: isPro ? -1 : 0,
          currentUsage: 0,
          remaining: isPro ? -1 : 0,
          period: periodKey,
        ),
        AppFeature.smartDebtsAdvisor.key: EntitlementModel(
          featureKey: AppFeature.smartDebtsAdvisor.key,
          isEntitled: true,
          limit: isPro ? -1 : 5,
          currentUsage: 0,
          remaining: isPro ? -1 : 5,
          period: periodKey,
        ),
      },
    );
  }
}

class PaymentOrderModel {
  final String id;
  final String userId;
  final String planId;
  final String billingCycle;
  final int amount;
  final String currency;
  final String status; // pending, paid, failed, expired, canceled
  final String paymentMethod;
  final String? externalTransactionId;
  final DateTime? paidAt;
  final DateTime expiresAt;
  final String? paymentUrl;
  final String? botDeepLink;

  const PaymentOrderModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.billingCycle,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.externalTransactionId,
    this.paidAt,
    required this.expiresAt,
    this.paymentUrl,
    this.botDeepLink,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String? ?? 'pro',
      billingCycle: json['billingCycle'] as String? ?? 'annual',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'UZS',
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'manual',
      externalTransactionId: json['externalTransactionId'] as String?,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
      paymentUrl: json['paymentUrl'] as String?,
      botDeepLink: json['botDeepLink'] as String?,
    );
  }
}
