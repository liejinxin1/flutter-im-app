class UserProfile {
  const UserProfile({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.remark,
  });

  final String userId;
  final String? nickname;
  final String? avatarUrl;
  final String? remark;

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
  }) => UserProfile(
    userId: userId ?? this.userId,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    remark: remark ?? this.remark,
  );

  Map<String, Object?> toJson() => {
    'userId': userId,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
    'remark': remark,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
    userId: json['userId'] as String? ?? '',
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    remark: json['remark'] as String?,
  );
}
