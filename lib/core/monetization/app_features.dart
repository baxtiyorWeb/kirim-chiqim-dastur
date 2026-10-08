/// Centralized, scalable feature & entitlement definition for Kirim-Chiqim (Moliya).
/// Precludes scattered `if (isPro)` checks throughout the application.
enum AppFeature {
  /// Offline/Local storage on device (Free & Pro: Unlimited)
  offlineStorage,

  /// Cloud database synchronization with PostgreSQL (Free: Locked, Pro: Unlimited)
  cloudSync,

  /// Automatic cloud backup and disaster recovery (Free: Locked, Pro: Unlimited)
  cloudBackup,

  /// Access account data across multiple devices simultaneously (Free: Locked, Pro: Unlimited)
  multiDeviceSync,

  /// Pre-purchase financial impact simulation ("What-If" AI engine)
  /// Free: 3 simulations / month, Pro: Unlimited
  whatIfSimulator,

  /// Cash runway forecast and depletion date projection (Pro only)
  runwayForecast,

  /// Dynamic daily safe-to-spend allowance calculations
  dynamicDailyBudget,

  /// Unlimited PDF & Excel financial export reports (Free: 2 / month, Pro: Unlimited)
  exportReports,

  /// Deep category spending analytics and trend forecasting (Pro only)
  advancedAnalytics,

  /// Smart debt prioritization and repayment schedules (Free: Basic, Pro: Advanced)
  smartDebtsAdvisor;

  /// Canonical backend & serialization key
  String get key {
    switch (this) {
      case AppFeature.offlineStorage:
        return 'offline_storage';
      case AppFeature.cloudSync:
        return 'cloud_sync';
      case AppFeature.cloudBackup:
        return 'cloud_backup';
      case AppFeature.multiDeviceSync:
        return 'multi_device_sync';
      case AppFeature.whatIfSimulator:
        return 'what_if_simulator';
      case AppFeature.runwayForecast:
        return 'runway_forecast';
      case AppFeature.dynamicDailyBudget:
        return 'intelligence_daily_budget';
      case AppFeature.exportReports:
        return 'export_reports';
      case AppFeature.advancedAnalytics:
        return 'advanced_analytics';
      case AppFeature.smartDebtsAdvisor:
        return 'smart_debts_advisor';
    }
  }

  /// Human-readable title in Uzbek
  String get title {
    switch (this) {
      case AppFeature.offlineStorage:
        return 'Mahalliy xotira (Offline)';
      case AppFeature.cloudSync:
        return 'Bulutli sinxronizatsiya';
      case AppFeature.cloudBackup:
        return 'Avtomatik bulutli zaxira';
      case AppFeature.multiDeviceSync:
        return 'Ko\'p qurilmadan kirish';
      case AppFeature.whatIfSimulator:
        return 'Xarid oldidan oqibatni hisoblash';
      case AppFeature.runwayForecast:
        return 'Mablag\' yetish muddati prognozi';
      case AppFeature.dynamicDailyBudget:
        return 'Kunlik dinamik me\'yor';
      case AppFeature.exportReports:
        return 'PDF va Excel hisobotlar';
      case AppFeature.advancedAnalytics:
        return 'Kengaytirilgan chuqur tahlil';
      case AppFeature.smartDebtsAdvisor:
        return 'Aqlli qarz va byudjet maslahatchisi';
    }
  }

  /// Uzbek description explaining the user benefit
  String get description {
    switch (this) {
      case AppFeature.offlineStorage:
        return 'Ma\'lumotlar to\'g\'ridan-to\'g\'ri qurilmangizda xavfsiz saqlanadi va internsiz ishlaydi.';
      case AppFeature.cloudSync:
        return 'Barcha daromad va xarajatlaringiz xavfsiz server bilan doimiy yangilanib turadi.';
      case AppFeature.cloudBackup:
        return 'Telefoningiz yo\'qolganda yoki almashganda ma\'lumotlaringiz bir zumda qayta tiklanadi.';
      case AppFeature.multiDeviceSync:
        return 'Bir nechta telefon yoki planshetdan bitta hisob bilan ishlash imkoniyati.';
      case AppFeature.whatIfSimulator:
        return 'Katta xarid qilishdan oldin oylik byudjetingizga ta\'sirini oldindan bilib oling.';
      case AppFeature.runwayForecast:
        return 'Mavjud pulingiz hozirgi xarajat sur\'atida qaysi sanagacha yetishini hisoblab beradi.';
      case AppFeature.dynamicDailyBudget:
        return 'Har kuni ortiqcha sarflamasdan omon qolish uchun xavfsiz kunlik limit.';
      case AppFeature.exportReports:
        return 'Barcha moliyaviy hisobotlarni chop etish yoki buxgalteriyaga yuborish uchun yuklab oling.';
      case AppFeature.advancedAnalytics:
        return 'Xarajat toifalari va oylik dinamika bo\'yicha chuqur grafikli tahlillar.';
      case AppFeature.smartDebtsAdvisor:
        return 'Qarzlarni eng maqbul tartibda to\'lash va kechikishlarning oldini olish rejasi.';
    }
  }

  /// Whether this feature is strictly locked on the Free tier
  bool get isProOnly {
    switch (this) {
      case AppFeature.cloudSync:
      case AppFeature.cloudBackup:
      case AppFeature.multiDeviceSync:
      case AppFeature.runwayForecast:
      case AppFeature.advancedAnalytics:
        return true;
      case AppFeature.offlineStorage:
      case AppFeature.dynamicDailyBudget:
      case AppFeature.whatIfSimulator:
      case AppFeature.exportReports:
      case AppFeature.smartDebtsAdvisor:
        return false;
    }
  }

  /// Default monthly usage limit on the Free tier (-1 = unlimited, 0 = locked, >0 = count)
  int get defaultFreeLimit {
    switch (this) {
      case AppFeature.offlineStorage:
      case AppFeature.dynamicDailyBudget:
        return -1; // Unlimited for all
      case AppFeature.whatIfSimulator:
        return 3; // 3 free simulations per month
      case AppFeature.exportReports:
        return 2; // 2 free exports per month
      case AppFeature.smartDebtsAdvisor:
        return 5;
      case AppFeature.cloudSync:
      case AppFeature.cloudBackup:
      case AppFeature.multiDeviceSync:
      case AppFeature.runwayForecast:
      case AppFeature.advancedAnalytics:
        return 0; // Strictly Pro
    }
  }

  static AppFeature? fromKey(String key) {
    for (final f in AppFeature.values) {
      if (f.key == key) return f;
    }
    return null;
  }
}
