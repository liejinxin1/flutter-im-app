import '../../domain/models/group_member.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/services/chat_service.dart';

class AgoraGroupRepository implements GroupRepository {
  AgoraGroupRepository(this._service);

  final ChatService _service;

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) => _service.createGroup(name: name, memberIds: memberIds);

  @override
  Future<List<GroupMember>> loadMembers(String groupId) =>
      _service.loadGroupMembers(groupId);

  @override
  Future<void> updateName(String groupId, String name) =>
      _service.updateGroupName(groupId, name);

  @override
  Future<void> leaveGroup(String groupId) => _service.leaveGroup(groupId);

  @override
  Future<void> removeMember(String groupId, String userId) =>
      _service.removeGroupMember(groupId, userId);

  @override
  Future<void> setAdmin(String groupId, String userId, {required bool admin}) =>
      _service.setGroupAdmin(groupId, userId, admin: admin);
}
