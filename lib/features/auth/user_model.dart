class UserModel {
  final String uid;
  final String mobile;
  final String email;
  final String name;
  final String photo;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? state;
  final String? pincode;
  final String authProvider; // 'phone' | 'google'
  final bool isProfileComplete;
  final bool isBlocked;       // set from DB is_blocked column
  final String? blockReason;

  const UserModel({
    required this.uid,
    required this.mobile,
    this.email = '',
    this.name = '',
    this.photo = '',
    this.gender,
    this.dateOfBirth,
    this.address,
    this.state,
    this.pincode,
    required this.authProvider,
    this.isProfileComplete = false,
    this.isBlocked = false,
    this.blockReason,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? photo,
    String? mobile,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? state,
    String? pincode,
    bool? isProfileComplete,
    bool? isBlocked,
    String? blockReason,
  }) {
    return UserModel(
      uid: uid,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      authProvider: authProvider,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Defensive parsing — any field that was added in a newer version
    // may be missing in cached data from an older install. Never throw.
    final uid = (json['uid'] as String?)?.trim() ?? '';
    return UserModel(
      uid: uid,
      mobile: (json['mobile'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      photo: (json['photo'] as String?)?.trim() ?? '',
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      authProvider: (json['auth_provider'] as String?)?.trim() ?? 'phone',
      isProfileComplete: _parseBool(json['is_profile_complete']),
      isBlocked: _parseBool(json['is_blocked']),
      blockReason: json['block_reason'] as String?,
    );
  }

  /// Safely coerce various representations of bool that may come from
  /// older cached JSON (e.g. 0/1 integers, "true"/"false" strings).
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'mobile': mobile,
    'email': email,
    'name': name,
    'photo': photo,
    'gender': gender,
    'date_of_birth': dateOfBirth,
    'address': address,
    'state': state,
    'pincode': pincode,
    'auth_provider': authProvider,
    'is_profile_complete': isProfileComplete,
    'is_blocked': isBlocked,
    'block_reason': blockReason,
  };
}
