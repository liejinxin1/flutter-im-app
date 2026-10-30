class GroupMuteState {
  const GroupMuteState({required this.allMuted, this.mutedUserIds = const {}});

  final bool allMuted;
  final Set<String> mutedUserIds;
}
