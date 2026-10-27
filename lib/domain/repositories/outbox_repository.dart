import '../models/outbox_message.dart';

/// Persistent per-account queue of messages not yet acknowledged by the SDK.
abstract interface class OutboxRepository {
  Future<List<OutboxMessage>> load(String userId, {String? conversationId});

  /// Upserts by [OutboxMessage.clientId] so manual retries do not duplicate.
  Future<void> save(String userId, OutboxMessage message);

  Future<void> remove(String userId, String clientId);
}
