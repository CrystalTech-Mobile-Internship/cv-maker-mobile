import '../../../core/i18n/app_language.dart';

/// Where a job application stands.
enum JobApplicationStatus {
  saved('saved'),
  applied('applied'),
  interview('interview'),
  offer('offer'),
  rejected('rejected');

  const JobApplicationStatus(this.value);

  final String value;

  String get label => switch (this) {
    saved => tr('Đang để ý', 'Saved'),
    applied => tr('Đã nộp', 'Applied'),
    interview => tr('Phỏng vấn', 'Interview'),
    offer => tr('Nhận việc', 'Offer'),
    rejected => tr('Không đạt', 'Not selected'),
  };

  static JobApplicationStatus fromValue(String? value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => JobApplicationStatus.saved,
  );
}

/// One job the user is tracking: kept only on this device.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.company,
    required this.role,
    required this.status,
    required this.updatedAt,
    this.appliedOn,
    this.link = '',
    this.note = '',
  });

  final String id;
  final String company;
  final String role;
  final JobApplicationStatus status;
  final DateTime updatedAt;
  final DateTime? appliedOn;
  final String link;
  final String note;

  JobApplication copyWith({
    String? company,
    String? role,
    JobApplicationStatus? status,
    DateTime? updatedAt,
    DateTime? appliedOn,
    bool clearAppliedOn = false,
    String? link,
    String? note,
  }) {
    return JobApplication(
      id: id,
      company: company ?? this.company,
      role: role ?? this.role,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      appliedOn: clearAppliedOn ? null : (appliedOn ?? this.appliedOn),
      link: link ?? this.link,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company,
    'role': role,
    'status': status.value,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (appliedOn != null) 'appliedOn': appliedOn!.toUtc().toIso8601String(),
    'link': link,
    'note': note,
  };

  /// Returns null for rows that are missing the basics, so one bad entry
  /// never hides the rest of the list.
  static JobApplication? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final company = json['company'];
    final role = json['role'];
    if (id is! String || company is! String || role is! String) return null;
    return JobApplication(
      id: id,
      company: company,
      role: role,
      status: JobApplicationStatus.fromValue(json['status'] as String?),
      updatedAt:
          DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      appliedOn: json['appliedOn'] == null
          ? null
          : DateTime.tryParse('${json['appliedOn']}')?.toUtc(),
      link: json['link'] is String ? json['link'] as String : '',
      note: json['note'] is String ? json['note'] as String : '',
    );
  }
}

/// Stores tracked applications.
abstract interface class JobApplicationRepository {
  Future<List<JobApplication>> load();

  Future<void> saveAll(List<JobApplication> items);
}
