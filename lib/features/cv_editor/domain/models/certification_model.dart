import 'month_date.dart';

const _unsetCertificationValue = Object();

class CertificationModel {
  const CertificationModel({
    required this.id,
    required this.name,
    this.issuer = '',
    this.score,
    this.issueDate,
    this.credentialUrl,
  });

  final String id;
  final String name;
  final String issuer;
  final String? score;
  final DateTime? issueDate;
  final String? credentialUrl;

  factory CertificationModel.fromJson(Map<String, dynamic> json) =>
      CertificationModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        score: json['score'] as String?,
        issueDate: json['issueDate'] == null
            ? null
            : parseMonthDate(json['issueDate'] as String),
        credentialUrl: json['credentialUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'issuer': issuer,
    'score': score,
    'issueDate': issueDate?.toUtc().toIso8601String(),
    'credentialUrl': credentialUrl,
  };

  CertificationModel copyWith({
    String? id,
    String? name,
    String? issuer,
    Object? score = _unsetCertificationValue,
    Object? issueDate = _unsetCertificationValue,
    Object? credentialUrl = _unsetCertificationValue,
  }) => CertificationModel(
    id: id ?? this.id,
    name: name ?? this.name,
    issuer: issuer ?? this.issuer,
    score: identical(score, _unsetCertificationValue)
        ? this.score
        : score as String?,
    issueDate: identical(issueDate, _unsetCertificationValue)
        ? this.issueDate
        : issueDate as DateTime?,
    credentialUrl: identical(credentialUrl, _unsetCertificationValue)
        ? this.credentialUrl
        : credentialUrl as String?,
  );
}
