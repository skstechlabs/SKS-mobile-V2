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
    return UserModel(
      uid: json['uid'] as String,
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'phone',
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      blockReason: json['block_reason'] as String?,
    );
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
