import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Local SQLite file on Android, iOS and desktop.
QueryExecutor openAppDatabase(String name) => driftDatabase(name: name);
