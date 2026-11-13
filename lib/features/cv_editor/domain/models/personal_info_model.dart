const _unsetPersonalInfoValue = Object();

/// Contact and headline information shown at the top of a CV.
class PersonalInfoModel {
  const PersonalInfoModel({
    this.fullName = '',
    this.targetRole = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.linkedInUrl,
    this.githubUrl,
    this.avatarPath,
    this.avatarPosition = 'right',
  });

  final String fullName;
  final String targetRole;
  final String email;
  final String phone;
  final String address;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? avatarPath;
  final String avatarPosition;

  factory PersonalInfoModel.fromJson(Map<String, dynamic> json) {
    return PersonalInfoModel(
      fullName: json['fullName'] as String? ?? '',
      targetRole: json['targetRole'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      linkedInUrl: json['linkedInUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      avatarPath: json['avatarPath'] as String?,
      avatarPosition: json['avatarPosition'] as String? ?? 'right',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'targetRole': targetRole,
      'email': email,
      'phone': phone,
      'address': address,
      'linkedInUrl': linkedInUrl,
      'githubUrl': githubUrl,
      'avatarPath': avatarPath,
      'avatarPosition': avatarPosition,
    };
  }

  PersonalInfoModel copyWith({
    String? fullName,
    String? targetRole,
    String? email,
    String? phone,
    String? address,
    Object? linkedInUrl = _unsetPersonalInfoValue,
    Object? githubUrl = _unsetPersonalInfoValue,
    Object? avatarPath = _unsetPersonalInfoValue,
    String? avatarPosition,
  }) {
    return PersonalInfoModel(
      fullName: fullName ?? this.fullName,
      targetRole: targetRole ?? this.targetRole,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      linkedInUrl: identical(linkedInUrl, _unsetPersonalInfoValue)
          ? this.linkedInUrl
          : linkedInUrl as String?,
      githubUrl: identical(githubUrl, _unsetPersonalInfoValue)
          ? this.githubUrl
          : githubUrl as String?,
      avatarPath: identical(avatarPath, _unsetPersonalInfoValue)
          ? this.avatarPath
          : avatarPath as String?,
      avatarPosition: avatarPosition ?? this.avatarPosition,
    );
  }
}
