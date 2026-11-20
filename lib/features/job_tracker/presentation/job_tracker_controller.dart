import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/cv_id.dart';

import '../data/prefs_job_application_repository.dart';
import '../domain/job_application.dart';

/// Loads, edits and saves the tracked applications.
class JobTrackerController
    extends StateNotifier<AsyncValue<List<JobApplication>>> {
  JobTrackerController(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  final JobApplicationRepository _repository;

  Future<void> _load() async {
    try {
      state = AsyncData(_sorted(await _repository.load()));
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  List<JobApplication> get _items => state.asData?.value ?? const [];

  Future<void> add({
    required String company,
    required String role,
    JobApplicationStatus status = JobApplicationStatus.saved,
    DateTime? appliedOn,
    String link = '',
    String note = '',
  }) {
    final item = JobApplication(
      id: newCvId(),
      company: company.trim(),
      role: role.trim(),
      status: status,
      updatedAt: DateTime.now().toUtc(),
      appliedOn: appliedOn,
      link: link.trim(),
      note: note.trim(),
    );
    return _commit([item, ..._items]);
  }

  Future<void> update(JobApplication item) => _commit([
    for (final existing in _items)
      existing.id == item.id
          ? item.copyWith(updatedAt: DateTime.now().toUtc())
          : existing,
  ]);

  Future<void> setStatus(String id, JobApplicationStatus status) {
    final item = _items.where((e) => e.id == id).firstOrNull;
    if (item == null) return Future.value();
    return update(
      item.copyWith(
        status: status,
        appliedOn: status != JobApplicationStatus.saved
            ? (item.appliedOn ?? DateTime.now().toUtc())
            : null,
      ),
    );
  }

  Future<void> remove(String id) => _commit([
    for (final e in _items)
      if (e.id != id) e,
  ]);

  Future<void> _commit(List<JobApplication> next) async {
    final sorted = _sorted(next);
    state = AsyncData(sorted);
    await _repository.saveAll(sorted);
  }

  static List<JobApplication> _sorted(List<JobApplication> items) =>
      [...items]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

final jobTrackerProvider =
    StateNotifierProvider<
      JobTrackerController,
      AsyncValue<List<JobApplication>>
    >(
      (ref) =>
          JobTrackerController(ref.watch(jobApplicationRepositoryProvider)),
    );
