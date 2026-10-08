library;

/// Types and status models for Offline-First and Cloud Synchronization.

enum SyncStatus {
  idle,
  syncing,
  synced,
  offlineOnly, // Free tier: data is saved locally on device only
  offline,     // Paid user: internet temporarily unavailable, local data safe
  error;

  String get label {
    switch (this) {
      case SyncStatus.idle:
        return 'Tayyor';
      case SyncStatus.syncing:
        return 'Sinxronizatsiya qilinmoqda...';
      case SyncStatus.synced:
        return 'Bulut bilan sinxronlangan';
      case SyncStatus.offlineOnly:
        return 'Mahalliy xotira (Offline)';
      case SyncStatus.offline:
        return 'Oflayn rejim (Mahalliy saqlangan)';
      case SyncStatus.error:
        return 'Qayta urinish kutilmoqda';
    }
  }

  bool get isSyncing => this == SyncStatus.syncing;
  bool get isSynced => this == SyncStatus.synced;
}

class SyncResult {
  final bool isSuccess;
  final SyncStatus status;
  final String message;
  final DateTime timestamp;
  final int itemsSynced;

  const SyncResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    required this.timestamp,
    this.itemsSynced = 0,
  });

  factory SyncResult.success({int itemsSynced = 0}) {
    return SyncResult(
      isSuccess: true,
      status: SyncStatus.synced,
      message: 'Ma\'lumotlar bulut bilan to\'liq yangilandi',
      timestamp: DateTime.now(),
      itemsSynced: itemsSynced,
    );
  }

  factory SyncResult.offlineOnly() {
    return SyncResult(
      isSuccess: false,
      status: SyncStatus.offlineOnly,
      message: 'Bepul rejada ma\'lumotlar faqat qurilmada saqlanadi. Bulutli sinxronizatsiya uchun Pro ga o\'ting.',
      timestamp: DateTime.now(),
    );
  }

  factory SyncResult.offline() {
    return SyncResult(
      isSuccess: false,
      status: SyncStatus.offline,
      message: 'Internet aloqasi yo\'q. Ma\'lumotlar qurilmada xavfsiz saqlandi va internet paydo bo\'lganda sinxronlanadi.',
      timestamp: DateTime.now(),
    );
  }

  factory SyncResult.failure(String error) {
    return SyncResult(
      isSuccess: false,
      status: SyncStatus.error,
      message: 'Sinxronizatsiya xatosi: $error',
      timestamp: DateTime.now(),
    );
  }
}
