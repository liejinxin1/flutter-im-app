abstract interface class GroupRepository {
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  });

  Future<List<String>> loadMemberIds(String groupId);
}
