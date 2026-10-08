import 'package:flutter/foundation.dart';
import '../../data/models/billing_models.dart';
import '../../data/models/debt_item.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/services/local_storage_service.dart';
import '../constants/api_constants.dart';
import '../monetization/app_features.dart';
import 'sync_types.dart';

/// Offline-First Synchronization Service.
/// FREE PLAN: Data resides locally on device (offline-first).
/// PAID PLAN: Data resides locally on device AND synchronizes with PostgreSQL cloud storage.
class SyncService {
  final FinanceRepository _repository;
  final LocalStorageService _storage;

  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(SyncStatus.idle);

  SyncService(this._repository, this._storage) {
    _initInitialStatus();
  }

  void _initInitialStatus() {
    final lastSync = _storage.getLastSyncTime();
    if (lastSync != null) {
      statusNotifier.value = SyncStatus.synced;
    } else {
      statusNotifier.value = SyncStatus.idle;
    }
  }

  SyncStatus get currentStatus => statusNotifier.value;
  DateTime? get lastSyncTime => _storage.getLastSyncTime();
  int get pendingChangesCount => _storage.getPendingChangesCount();

  /// Core sync execution respecting tier entitlements
  Future<SyncResult> sync({required SubscriptionDetailsModel subscription}) async {
    // 1. FREE PLAN ENFORCEMENT: Offline only
    final isEntitledToCloudSync = subscription.hasAccess(AppFeature.cloudSync);
    if (!isEntitledToCloudSync) {
      // Free users keep data strictly in local storage
      await _persistCurrentStateLocally();
      statusNotifier.value = SyncStatus.offlineOnly;
      return SyncResult.offlineOnly();
    }

    // 2. PAID PLAN: Cloud Sync + Local Persistence
    if (!_repository.isAuthenticated) {
      await _persistCurrentStateLocally();
      statusNotifier.value = SyncStatus.offline;
      return SyncResult.failure('Avtorizatsiyadan o\'tilmagan. Avval tizimga kiring.');
    }

    statusNotifier.value = SyncStatus.syncing;

    try {
      // 1. Attempt delta push of any local changes to server
      await _pushDeltaChanges();

      // 2. Synchronize latest PostgreSQL cloud state
      await _repository.syncAllWithBackend();

      // 3. Persist newly fetched state into local encrypted storage for offline resiliency
      await _persistCurrentStateLocally();

      final now = DateTime.now();
      await _storage.setLastSyncTime(now);
      await _storage.setPendingChangesCount(0);

      statusNotifier.value = SyncStatus.synced;
      return SyncResult.success(itemsSynced: _repository.getTransactions().length);
    } catch (e) {
      debugPrint('[SyncService] Cloud sync notice (offline fallback active): $e');
      statusNotifier.value = SyncStatus.offline;
      return SyncResult.offline();
    }
  }

  /// Pushes delta changes to PostgreSQL /api/v1/sync/push
  Future<void> _pushDeltaChanges() async {
    try {
      final txs = _repository.getTransactions();
      final debts = _repository.getDebts();

      final payload = {
        'clientTime': DateTime.now().toIso8601String(),
        'transactions': txs.map((t) => {
          'id': t.id,
          'categoryId': t.categoryId,
          'title': t.title,
          'amount': t.amount,
          'transactionType': t.isIncome ? 'income' : 'expense',
          'transactionDate': t.dateTime.toIso8601String(),
          'note': t.note,
          'paymentMethod': t.paymentMethod,
          'personName': t.personName,
          'updatedAt': t.updatedAt.toIso8601String(),
          'version': 1,
        }).toList(),
        'debts': debts.map((d) => {
          'id': d.id,
          'personName': d.personName,
          'phoneNumber': d.phoneNumber,
          'amount': d.amount,
          'paidAmount': d.paidAmount,
          'debtType': d.type == DebtType.borrowed ? 'borrowed' : 'lent',
          'status': d.status.name,
          'dueDate': d.dueDate?.toIso8601String(),
          'note': d.note,
          'updatedAt': DateTime.now().toIso8601String(),
          'version': 1,
        }).toList(),
      };

      await _repository.api.post(ApiConstants.syncPush, body: payload);
    } catch (e) {
      // Non-fatal: if push fails, full sync continues
      debugPrint('[SyncService] Delta push notice: $e');
    }
  }

  /// Automatically caches repository data into device offline storage
  Future<void> _persistCurrentStateLocally() async {
    try {
      final txs = _repository.getTransactions().map((t) => t.toJson()).toList();
      await _storage.saveOfflineTransactions(txs);

      final debts = _repository.getDebts().map((d) => d.toJson()).toList();
      await _storage.saveOfflineDebts(debts);

      final budget = _repository.getBudget().toJson();
      await _storage.saveOfflineBudget(budget);

      final goals = _repository.getGoals().map((g) => g.toJson()).toList();
      await _storage.saveOfflineGoals(goals);

      await _storage.saveOfflineInitialBalance(_repository.getInitialBalance());
    } catch (e) {
      debugPrint('[SyncService] Local persistence notice: $e');
    }
  }

  /// Loads locally cached data on app launch (guarantees offline availability for Free & Paid)
  void loadOfflineCacheIntoMemory() {
    try {
      _repository.hydrateFromLocalStorage();
    } catch (e) {
      debugPrint('[SyncService] Hydration error: $e');
    }
  }
}
