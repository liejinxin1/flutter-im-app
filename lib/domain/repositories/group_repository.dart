import '../models/group_member.dart';
import '../models/group_mute_state.dart';

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

  Future<void> inviteMembers(String groupId, List<String> userIds);

  Future<GroupMuteState> loadMuteState(String groupId);

  Future<void> setAllMuted(String groupId, bool muted);

  Future<void> setMemberMuted(String groupId, String userId, bool muted);
}
