import 'user_profile.dart';

enum GroupMemberRole { member, admin, owner }

class GroupMember {
  const GroupMember({required this.profile, required this.role});

  final UserProfile profile;
  final GroupMemberRole role;

  String get userId => profile.userId;
  bool get isOwner => role == GroupMemberRole.owner;
  bool get isAdmin => role == GroupMemberRole.admin;
  bool get canManage => isOwner || isAdmin;
}
