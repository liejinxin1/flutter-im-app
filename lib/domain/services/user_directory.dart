import '../models/user_profile.dart';

/// Read-only user directory used by the profile cache.
abstract interface class UserDirectory {
  Future<Map<String, UserProfile>> loadUserProfiles(List<String> userIds);
}
