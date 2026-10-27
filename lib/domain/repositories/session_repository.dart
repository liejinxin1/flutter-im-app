abstract interface class SessionRepository {
  Stream<bool> get connectionChanges;
  Stream<void> get sessionInvalidated;

  Future<String?> restoreSession();

  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
  });

  Future<void> logout();
}
