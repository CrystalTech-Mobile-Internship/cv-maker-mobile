// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalCvsTable extends LocalCvs
    with TableInfo<$LocalCvsTable, LocalCvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCvsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    templateId,
    payloadJson,
    isSynced,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cvs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCvRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalCvsTable createAlias(String alias) {
    return $LocalCvsTable(attachedDatabase, alias);
  }
}

class LocalCvRow extends DataClass implements Insertable<LocalCvRow> {
  final String id;
  final String? userId;
  final String title;
  final String templateId;
  final String payloadJson;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalCvRow({
    required this.id,
    this.userId,
    required this.title,
    required this.templateId,
    required this.payloadJson,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['title'] = Variable<String>(title);
    map['template_id'] = Variable<String>(templateId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCvsCompanion toCompanion(bool nullToAbsent) {
    return LocalCvsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      title: Value(title),
      templateId: Value(templateId),
      payloadJson: Value(payloadJson),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCvRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      templateId: serializer.fromJson<String>(json['templateId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'title': serializer.toJson<String>(title),
      'templateId': serializer.toJson<String>(templateId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCvRow copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? title,
    String? templateId,
    String? payloadJson,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalCvRow(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    title: title ?? this.title,
    templateId: templateId ?? this.templateId,
    payloadJson: payloadJson ?? this.payloadJson,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCvRow copyWithCompanion(LocalCvsCompanion data) {
    return LocalCvRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCvRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('templateId: $templateId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    templateId,
    payloadJson,
    isSynced,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCvRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.templateId == this.templateId &&
          other.payloadJson == this.payloadJson &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalCvsCompanion extends UpdateCompanion<LocalCvRow> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> title;
  final Value<String> templateId;
  final Value<String> payloadJson;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalCvsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.templateId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCvsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String title,
    required String templateId,
    required String payloadJson,
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       templateId = Value(templateId),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCvRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? templateId,
    Expression<String>? payloadJson,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (templateId != null) 'template_id': templateId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCvsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? title,
    Value<String>? templateId,
    Value<String>? payloadJson,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCvsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      templateId: templateId ?? this.templateId,
      payloadJson: payloadJson ?? this.payloadJson,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCvsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('templateId: $templateId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingCvDeletionsTable extends PendingCvDeletions
    with TableInfo<$PendingCvDeletionsTable, PendingCvDeletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingCvDeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cvIdMeta = const VerificationMeta('cvId');
  @override
  late final GeneratedColumn<String> cvId = GeneratedColumn<String>(
    'cv_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cvId, userId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_cv_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingCvDeletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cv_id')) {
      context.handle(
        _cvIdMeta,
        cvId.isAcceptableOrUnknown(data['cv_id']!, _cvIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cvIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cvId};
  @override
  PendingCvDeletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingCvDeletionRow(
      cvId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cv_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $PendingCvDeletionsTable createAlias(String alias) {
    return $PendingCvDeletionsTable(attachedDatabase, alias);
  }
}

class PendingCvDeletionRow extends DataClass
    implements Insertable<PendingCvDeletionRow> {
  final String cvId;
  final String userId;
  final DateTime deletedAt;
  const PendingCvDeletionRow({
    required this.cvId,
    required this.userId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cv_id'] = Variable<String>(cvId);
    map['user_id'] = Variable<String>(userId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  PendingCvDeletionsCompanion toCompanion(bool nullToAbsent) {
    return PendingCvDeletionsCompanion(
      cvId: Value(cvId),
      userId: Value(userId),
      deletedAt: Value(deletedAt),
    );
  }

  factory PendingCvDeletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingCvDeletionRow(
      cvId: serializer.fromJson<String>(json['cvId']),
      userId: serializer.fromJson<String>(json['userId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cvId': serializer.toJson<String>(cvId),
      'userId': serializer.toJson<String>(userId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  PendingCvDeletionRow copyWith({
    String? cvId,
    String? userId,
    DateTime? deletedAt,
  }) => PendingCvDeletionRow(
    cvId: cvId ?? this.cvId,
    userId: userId ?? this.userId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  PendingCvDeletionRow copyWithCompanion(PendingCvDeletionsCompanion data) {
    return PendingCvDeletionRow(
      cvId: data.cvId.present ? data.cvId.value : this.cvId,
      userId: data.userId.present ? data.userId.value : this.userId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingCvDeletionRow(')
          ..write('cvId: $cvId, ')
          ..write('userId: $userId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cvId, userId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCvDeletionRow &&
          other.cvId == this.cvId &&
          other.userId == this.userId &&
          other.deletedAt == this.deletedAt);
}

class PendingCvDeletionsCompanion
    extends UpdateCompanion<PendingCvDeletionRow> {
  final Value<String> cvId;
  final Value<String> userId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const PendingCvDeletionsCompanion({
    this.cvId = const Value.absent(),
    this.userId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingCvDeletionsCompanion.insert({
    required String cvId,
    required String userId,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : cvId = Value(cvId),
       userId = Value(userId),
       deletedAt = Value(deletedAt);
  static Insertable<PendingCvDeletionRow> custom({
    Expression<String>? cvId,
    Expression<String>? userId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cvId != null) 'cv_id': cvId,
      if (userId != null) 'user_id': userId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingCvDeletionsCompanion copyWith({
    Value<String>? cvId,
    Value<String>? userId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return PendingCvDeletionsCompanion(
      cvId: cvId ?? this.cvId,
      userId: userId ?? this.userId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cvId.present) {
      map['cv_id'] = Variable<String>(cvId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingCvDeletionsCompanion(')
          ..write('cvId: $cvId, ')
          ..write('userId: $userId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCvsTable localCvs = $LocalCvsTable(this);
  late final $PendingCvDeletionsTable pendingCvDeletions =
      $PendingCvDeletionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localCvs,
    pendingCvDeletions,
  ];
}

typedef $$LocalCvsTableCreateCompanionBuilder =
    LocalCvsCompanion Function({
      required String id,
      Value<String?> userId,
      required String title,
      required String templateId,
      required String payloadJson,
      Value<bool> isSynced,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalCvsTableUpdateCompanionBuilder =
    LocalCvsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> title,
      Value<String> templateId,
      Value<String> payloadJson,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalCvsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCvsTable> {
  $$LocalCvsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCvsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCvsTable> {
  $$LocalCvsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCvsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCvsTable> {
  $$LocalCvsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCvsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCvsTable,
          LocalCvRow,
          $$LocalCvsTableFilterComposer,
          $$LocalCvsTableOrderingComposer,
          $$LocalCvsTableAnnotationComposer,
          $$LocalCvsTableCreateCompanionBuilder,
          $$LocalCvsTableUpdateCompanionBuilder,
          (
            LocalCvRow,
            BaseReferences<_$AppDatabase, $LocalCvsTable, LocalCvRow>,
          ),
          LocalCvRow,
          PrefetchHooks Function()
        > {
  $$LocalCvsTableTableManager(_$AppDatabase db, $LocalCvsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCvsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCvsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCvsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCvsCompanion(
                id: id,
                userId: userId,
                title: title,
                templateId: templateId,
                payloadJson: payloadJson,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String title,
                required String templateId,
                required String payloadJson,
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalCvsCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                templateId: templateId,
                payloadJson: payloadJson,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCvsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCvsTable,
      LocalCvRow,
      $$LocalCvsTableFilterComposer,
      $$LocalCvsTableOrderingComposer,
      $$LocalCvsTableAnnotationComposer,
      $$LocalCvsTableCreateCompanionBuilder,
      $$LocalCvsTableUpdateCompanionBuilder,
      (LocalCvRow, BaseReferences<_$AppDatabase, $LocalCvsTable, LocalCvRow>),
      LocalCvRow,
      PrefetchHooks Function()
    >;
typedef $$PendingCvDeletionsTableCreateCompanionBuilder =
    PendingCvDeletionsCompanion Function({
      required String cvId,
      required String userId,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$PendingCvDeletionsTableUpdateCompanionBuilder =
    PendingCvDeletionsCompanion Function({
      Value<String> cvId,
      Value<String> userId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$PendingCvDeletionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingCvDeletionsTable> {
  $$PendingCvDeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cvId => $composableBuilder(
    column: $table.cvId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingCvDeletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingCvDeletionsTable> {
  $$PendingCvDeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cvId => $composableBuilder(
    column: $table.cvId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingCvDeletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingCvDeletionsTable> {
  $$PendingCvDeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cvId =>
      $composableBuilder(column: $table.cvId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PendingCvDeletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingCvDeletionsTable,
          PendingCvDeletionRow,
          $$PendingCvDeletionsTableFilterComposer,
          $$PendingCvDeletionsTableOrderingComposer,
          $$PendingCvDeletionsTableAnnotationComposer,
          $$PendingCvDeletionsTableCreateCompanionBuilder,
          $$PendingCvDeletionsTableUpdateCompanionBuilder,
          (
            PendingCvDeletionRow,
            BaseReferences<
              _$AppDatabase,
              $PendingCvDeletionsTable,
              PendingCvDeletionRow
            >,
          ),
          PendingCvDeletionRow,
          PrefetchHooks Function()
        > {
  $$PendingCvDeletionsTableTableManager(
    _$AppDatabase db,
    $PendingCvDeletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingCvDeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingCvDeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingCvDeletionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cvId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingCvDeletionsCompanion(
                cvId: cvId,
                userId: userId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cvId,
                required String userId,
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingCvDeletionsCompanion.insert(
                cvId: cvId,
                userId: userId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingCvDeletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingCvDeletionsTable,
      PendingCvDeletionRow,
      $$PendingCvDeletionsTableFilterComposer,
      $$PendingCvDeletionsTableOrderingComposer,
      $$PendingCvDeletionsTableAnnotationComposer,
      $$PendingCvDeletionsTableCreateCompanionBuilder,
      $$PendingCvDeletionsTableUpdateCompanionBuilder,
      (
        PendingCvDeletionRow,
        BaseReferences<
          _$AppDatabase,
          $PendingCvDeletionsTable,
          PendingCvDeletionRow
        >,
      ),
      PendingCvDeletionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCvsTableTableManager get localCvs =>
      $$LocalCvsTableTableManager(_db, _db.localCvs);
  $$PendingCvDeletionsTableTableManager get pendingCvDeletions =>
      $$PendingCvDeletionsTableTableManager(_db, _db.pendingCvDeletions);
}
