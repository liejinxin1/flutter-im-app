import '../../domain/repositories/session_repository.dart';
import '../services/chat_connection.dart';

class AgoraSessionRepository implements SessionRepository {
  AgoraSessionRepository(this._connection);

  final ChatConnection _connection;

  @override
  Stream<bool> get connectionChanges => _connection.connectionChanges;
  @override
  Stream<void> get sessionInvalidated => _connection.sessionInvalidated;
  @override
  Future<String?> restoreSession() => _connection.restoreSession();
  @override
  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
  }) => _connection.login(
    userId: userId,
    credential: credential,
    usePassword: usePassword,
  );
  @override
  Future<void> logout() => _connection.service.logout();
}
