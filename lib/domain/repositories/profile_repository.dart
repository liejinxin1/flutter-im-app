import '../models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> load(String userId, {bool forceRefresh = false});

  /// Returns profiles for all requested IDs. Missing/failed IDs fall back to
  /// a profile containing only the userId.
  Future<Map<String, UserProfile>> loadAll(
    Iterable<String> userIds, {
    bool forceRefresh = false,
  });
}
