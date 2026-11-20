import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/job_application.dart';

/// Keeps the tracker on this device as one JSON list.
class PrefsJobApplicationRepository implements JobApplicationRepository {
  static const storageKey = 'job_applications_v1';

  @override
  Future<List<JobApplication>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map(JobApplication.fromJson)
          .whereType<JobApplication>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> saveAll(List<JobApplication> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }
}

final jobApplicationRepositoryProvider = Provider<JobApplicationRepository>(
  (ref) => PrefsJobApplicationRepository(),
);
