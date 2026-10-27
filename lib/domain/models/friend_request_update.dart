enum FriendRequestUpdateType { received, accepted, declined, contactAdded }

class FriendRequestUpdate {
  const FriendRequestUpdate({
    required this.userId,
    required this.type,
    this.reason,
  });

  final String userId;
  final FriendRequestUpdateType type;
  final String? reason;

  Map<String, Object?> toJson() => {
    'userId': userId,
    'type': type.name,
    'reason': reason,
  };

  factory FriendRequestUpdate.fromJson(Map<String, Object?> json) {
    final typeName = json['type'];
    var type = FriendRequestUpdateType.received;
    for (final value in FriendRequestUpdateType.values) {
      if (value.name == typeName) {
        type = value;
        break;
      }
    }
    return FriendRequestUpdate(
      userId: json['userId'] as String? ?? '',
      type: type,
      reason: json['reason'] as String?,
    );
  }
}
