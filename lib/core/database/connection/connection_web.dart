import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/wasm.dart';

/// Defined in web/index.html: resolves to false when the browser blocks
/// network access inside shared workers (embedded and in-app browsers).
@JS('cvCanUseDatabaseWorker')
external JSPromise<JSBoolean> _probeWorkerSupport();

Future<bool> _workersUsable() async {
  try {
    return (await _probeWorkerSupport().toDart).toDart;
  } catch (_) {
    // Probe missing or failed: keep the default worker-based setup.
    return true;
  }
}

/// Opens the browser database. Uses drift's worker setup when possible and
/// otherwise runs SQLite in the page with the same IndexedDB store and file
/// path that drift's IndexedDB worker mode uses, so data stays compatible.
QueryExecutor openAppDatabase(String name) {
  return LazyDatabase(() async {
    if (await _workersUsable()) {
      return driftDatabase(
        name: name,
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
    }
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    final fileSystem = await IndexedDbFileSystem.open(dbName: name);
    sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);
    return WasmDatabase(
      sqlite3: sqlite3,
      path: '/database',
      fileSystem: fileSystem,
    );
  });
}
