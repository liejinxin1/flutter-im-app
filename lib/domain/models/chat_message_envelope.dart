import 'dart:convert';

import 'chat_message_content.dart';
import 'chat_message_kind.dart';

/// Event name for the app-owned wire envelope.
///
/// Text and (when an uploader is configured) attachment messages are sent as
/// Agora `CUSTOM` messages with this event. Unknown custom events are preserved
/// as `CustomMessageContent` instead of being dropped.
const String appMessageEvent = 'app.im.message';
const int appMessageProtocolVersion = 1;

/// Backend-independent message envelope.
///
/// The payload intentionally excludes local file paths and SDK secrets. For
/// attachments, [ChatMessageContent.remotePath] must already contain the
/// uploaded public URL.
class ChatMessageEnvelope {
  const ChatMessageEnvelope({required this.clientId, required this.content});

  final String clientId;
  final ChatMessageContent content;

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() => {
    'v': appMessageProtocolVersion,
    'clientId': clientId,
    'kind': content.kind.name,
    'payload': _payload(content),
  };

  static ChatMessageEnvelope? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final version = (decoded['v'] as num?)?.toInt();
      if (version != appMessageProtocolVersion) return null;
      final clientId = decoded['clientId'] as String?;
      final kindName = decoded['kind'] as String?;
      final rawPayload = decoded['payload'];
      if (clientId == null ||
          clientId.isEmpty ||
          kindName == null ||
          rawPayload is! Map) {
        return null;
      }
      final kind = _kindByName(kindName);
      if (kind == null) return null;
      final payload = {
        for (final entry in rawPayload.entries) '${entry.key}': entry.value,
      };
      final content = _contentFromPayload(kind, payload);
      if (content == null) return null;
      return ChatMessageEnvelope(clientId: clientId, content: content);
    } on FormatException {
      return null;
    }
  }
}

Map<String, Object?> _payload(ChatMessageContent content) => switch (content) {
  TextMessageContent(:final text) => {'text': text},
  ImageMessageContent(:final remotePath, :final width, :final height) => {
    'url': _requiredRemoteUrl(remotePath, 'image'),
    'width': width,
    'height': height,
  },
  VoiceMessageContent(:final remotePath, :final durationSeconds) => {
    'url': _requiredRemoteUrl(remotePath, 'voice'),
    'durationSeconds': durationSeconds,
  },
  FileMessageContent(
    :final remotePath,
    :final fileName,
    :final fileSizeBytes,
    :final mimeType,
  ) =>
    {
      'url': _requiredRemoteUrl(remotePath, 'file'),
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
    },
  VideoMessageContent(
    :final remotePath,
    :final durationSeconds,
    :final width,
    :final height,
  ) =>
    {
      'url': _requiredRemoteUrl(remotePath, 'video'),
      'durationSeconds': durationSeconds,
      'width': width,
      'height': height,
    },
  LocationMessageContent(
    :final latitude,
    :final longitude,
    :final address,
    :final title,
  ) =>
    {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'title': title,
    },
  ContactMessageContent(:final userId, :final displayName, :final avatarUrl) =>
    {'userId': userId, 'displayName': displayName, 'avatarUrl': avatarUrl},
  CustomMessageContent(:final event, :final params) => {
    'event': event,
    'params': params,
  },
  SystemMessageContent(:final text, :final systemType) => {
    'text': text,
    'systemType': systemType,
  },
  UnknownMessageContent(:final rawType, :final rawPayload) => {
    'rawType': rawType,
    'rawPayload': rawPayload,
  },
};

String _requiredRemoteUrl(String? url, String kind) {
  if (url == null || !url.startsWith(RegExp(r'https?://'))) {
    throw StateError('$kind content requires an uploaded remote URL.');
  }
  return url;
}

ChatMessageContent? _contentFromPayload(
  ChatMessageKind kind,
  Map<String, Object?> payload,
) => switch (kind) {
  ChatMessageKind.text => TextMessageContent(payload['text'] as String? ?? ''),
  ChatMessageKind.image => ImageMessageContent(
    remotePath: payload['url'] as String?,
    width: (payload['width'] as num?)?.toDouble(),
    height: (payload['height'] as num?)?.toDouble(),
  ),
  ChatMessageKind.voice => VoiceMessageContent(
    remotePath: payload['url'] as String?,
    durationSeconds: (payload['durationSeconds'] as num?)?.toInt() ?? 0,
  ),
  ChatMessageKind.file => FileMessageContent(
    remotePath: payload['url'] as String?,
    fileName: payload['fileName'] as String?,
    fileSizeBytes: (payload['fileSizeBytes'] as num?)?.toInt() ?? 0,
    mimeType: payload['mimeType'] as String?,
  ),
  ChatMessageKind.video => VideoMessageContent(
    remotePath: payload['url'] as String?,
    durationSeconds: (payload['durationSeconds'] as num?)?.toInt() ?? 0,
    width: (payload['width'] as num?)?.toDouble(),
    height: (payload['height'] as num?)?.toDouble(),
  ),
  ChatMessageKind.location => LocationMessageContent(
    latitude: (payload['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (payload['longitude'] as num?)?.toDouble() ?? 0,
    address: payload['address'] as String?,
    title: payload['title'] as String?,
  ),
  ChatMessageKind.contact => ContactMessageContent(
    userId: payload['userId'] as String? ?? '',
    displayName: payload['displayName'] as String?,
    avatarUrl: payload['avatarUrl'] as String?,
  ),
  ChatMessageKind.custom => CustomMessageContent(
    event: payload['event'] as String? ?? '',
    params: _map(payload['params']),
  ),
  ChatMessageKind.system => SystemMessageContent(
    text: payload['text'] as String? ?? '',
    systemType: payload['systemType'] as String?,
  ),
  ChatMessageKind.unknown => UnknownMessageContent(
    rawType: payload['rawType'] as String? ?? 'unknown',
    rawPayload: _map(payload['rawPayload']),
  ),
};

Map<String, Object?> _map(Object? raw) {
  if (raw is Map) {
    return {for (final entry in raw.entries) '${entry.key}': entry.value};
  }
  return const {};
}

ChatMessageKind? _kindByName(String name) {
  for (final kind in ChatMessageKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}
