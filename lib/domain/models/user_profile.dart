class UserProfile {
  const UserProfile({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.remark,
    this.phone,
    this.email,
    this.birthday,
    this.gender = 0,
  });

  final String userId;
  final String? nickname;
  final String? avatarUrl;
  final String? remark;

  /// 0 unknown, 1 male, 2 female (Agora Chat convention).
  final int gender;
  final String? phone;
  final String? email;
  final String? birthday;

  /// Remark is the strongest signal (local contact name), then nickname.
  String get displayName {
    final localRemark = remark?.trim();
    if (localRemark != null && localRemark.isNotEmpty) return localRemark;
    final nick = nickname?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    return userId;
  }

  String? get effectiveAvatarUrl {
    final url = avatarUrl?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  UserProfile copyWith({
    String? userId,
    String? nickname,
    String? avatarUrl,
    String? remark,
    int? gender,
    String? phone,
    String? email,
    String? birthday,
  }) => UserProfile(
    userId: userId ?? this.userId,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    remark: remark ?? this.remark,
    gender: gender ?? this.gender,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    birthday: birthday ?? this.birthday,
  );

  Map<String, Object?> toJson() => {
    'userId': userId,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
    'remark': remark,
    'gender': gender,
    'phone': phone,
    'email': email,
    'birthday': birthday,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    userId: json['userId'] as String? ?? '',
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    remark: json['remark'] as String?,
    gender: (json['gender'] as num?)?.toInt() ?? 0,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    birthday: json['birthday'] as String?,
  );
}
