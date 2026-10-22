import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/data/repositories/cv_sync_repository.dart';

class DashboardSyncState {
  const DashboardSyncState({
    this.isSyncing = false,
    this.lastResult,
    this.lastSyncedAt,
  });

  final bool isSyncing;
  final CvSyncResult? lastResult;
  final DateTime? lastSyncedAt;

  DashboardSyncState copyWith({
    bool? isSyncing,
    CvSyncResult? lastResult,
    DateTime? lastSyncedAt,
  }) {
    return DashboardSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastResult: lastResult ?? this.lastResult,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class DashboardSyncController extends StateNotifier<DashboardSyncState> {
  DashboardSyncController(this._repository) : super(const DashboardSyncState());

  final CvSyncRepository _repository;

  Future<CvSyncResult> synchronize(String userId) async {
    if (state.isSyncing) {
      return state.lastResult ??
          const CvSyncResult(
            uploadedCount: 0,
            downloadedCount: 0,
            failedCount: 0,
          );
    }

    state = state.copyWith(isSyncing: true);
    final result = await _repository.syncAccount(userId);
    state = DashboardSyncState(
      isSyncing: false,
      lastResult: result,
      lastSyncedAt: result.isSuccess ? DateTime.now() : state.lastSyncedAt,
    );
    return result;
  }
}

final dashboardSyncControllerProvider =
    StateNotifierProvider<DashboardSyncController, DashboardSyncState>((ref) {
      return DashboardSyncController(ref.watch(cvSyncRepositoryProvider));
    });
