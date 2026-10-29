enum FriendRequestUpdateType { received, accepted, declined, contactAdded }

enum FriendRequestTargetType { contact, group }

/// A contact request or group invitation, including handled history.
///
/// [userId] is the contact user ID for contact requests and the inviter ID for
/// group invitations. [targetId] is the stable key used for de-duplication.
class FriendRequestUpdate {
  const FriendRequestUpdate({
    required this.userId,
    required this.type,
    this.reason,
    this.targetType = FriendRequestTargetType.contact,
    this.groupId,
    this.groupName,
    this.inviter,
    this.occurredAt,
  });

  final String userId;
  final FriendRequestUpdateType type;
  final String? reason;
  final FriendRequestTargetType targetType;
  final String? groupId;
  final String? groupName;
  final String? inviter;
  final DateTime? occurredAt;

  bool get isGroup => targetType == FriendRequestTargetType.group;

  String get targetId => isGroup ? (groupId ?? '') : userId;

  String get targetKey => '${targetType.name}:$targetId';

  String get displayId => isGroup
      ? (groupName?.isNotEmpty == true ? groupName! : targetId)
      : userId;

  FriendRequestUpdate copyWith({
    String? userId,
    FriendRequestUpdateType? type,
    String? reason,
    FriendRequestTargetType? targetType,
    String? groupId,
    String? groupName,
    String? inviter,
    DateTime? occurredAt,
  }) => FriendRequestUpdate(
    userId: userId ?? this.userId,
    type: type ?? this.type,
    reason: reason ?? this.reason,
    targetType: targetType ?? this.targetType,
    groupId: groupId ?? this.groupId,
    groupName: groupName ?? this.groupName,
    inviter: inviter ?? this.inviter,
    occurredAt: occurredAt ?? this.occurredAt,
  );

  Map<String, Object?> toJson() => {
    'userId': userId,
    'type': type.name,
    'reason': reason,
    'targetType': targetType.name,
    'groupId': groupId,
    'groupName': groupName,
    'inviter': inviter,
    'occurredAt': occurredAt?.millisecondsSinceEpoch,
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
    final targetName = json['targetType'];
    var targetType = FriendRequestTargetType.contact;
    for (final value in FriendRequestTargetType.values) {
      if (value.name == targetName) {
        targetType = value;
        break;
      }
    }
    final occurred = (json['occurredAt'] as num?)?.toInt();
    return FriendRequestUpdate(
      userId: json['userId'] as String? ?? '',
      type: type,
      reason: json['reason'] as String?,
      targetType: targetType,
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      inviter: json['inviter'] as String?,
      occurredAt: occurred == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(occurred),
    );
  }
}
