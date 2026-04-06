class ProfileModel {
  final int id;
  final String? accountPhone;
  final String profileUid;
  final String profileName;
  final String? profileAvatar;
  final bool isPrimary;
  final bool isActive;
  final String? dateOfBirth;
  final String? gender;
  final int activeSessions;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    this.accountPhone,
    required this.profileUid,
    required this.profileName,
    this.profileAvatar,
    required this.isPrimary,
    required this.isActive,
    this.dateOfBirth,
    this.gender,
    this.activeSessions = 0,
    this.lastUsedAt,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int,
      accountPhone: json['account_phone'] as String?,
      profileUid: json['profile_uid'] as String,
      profileName: json['profile_name'] as String,
      profileAvatar: json['profile_avatar'] as String?,
      isPrimary: json['isPrimary'] == true || json['is_primary'] == 1 || json['is_primary'] == true,
      isActive: json['isActive'] == true || json['is_active'] == 1 || json['is_active'] == true,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      activeSessions: json['activeSessions'] as int? ?? json['active_sessions'] as int? ?? 0,
      lastUsedAt: json['last_used_at'] != null 
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_phone': accountPhone,
      'profile_uid': profileUid,
      'profile_name': profileName,
      'profile_avatar': profileAvatar,
      'isPrimary': isPrimary,
      'isActive': isActive,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'activeSessions': activeSessions,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName => profileName;
  
  String get avatarInitials {
    if (profileName.isEmpty) return '?';
    final parts = profileName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return profileName[0].toUpperCase();
  }
}
