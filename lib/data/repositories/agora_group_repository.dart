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
}
