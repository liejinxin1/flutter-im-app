import '../models/group_member.dart';

abstract interface class GroupRepository {
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  });

  Future<List<GroupMember>> loadMembers(String groupId);

  Future<void> updateName(String groupId, String name);

  Future<void> leaveGroup(String groupId);

  Future<void> removeMember(String groupId, String userId);

  Future<void> setAdmin(String groupId, String userId, {required bool admin});
}
