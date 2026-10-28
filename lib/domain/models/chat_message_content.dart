import 'chat_message_kind.dart';
import 'chat_message_quote.dart';

/// App-owned message payloads.
///
/// The SDK is mapped into this hierarchy at the data boundary. UI code switches
/// on the concrete content type, so adding file/location/contact/RTC custom
/// messages does not require adding more nullable fields to `ChatMessage`.
sealed class ChatMessageContent {
  const ChatMessageContent();

  ChatMessageKind get kind;

  Map<String, Object?> toJson();

  /// Returns a copy with cached attachment paths filled in when applicable.
  ChatMessageContent withAttachmentPaths({
    String? localPath,
    String? thumbnailLocalPath,
  }) => this;

  factory ChatMessageContent.fromJson(Map<String, Object?> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'text' => TextMessageContent(
        json['text'] as String? ?? '',
        quote: json['quote'] is Map
            ? ChatMessageQuote.fromJson(_objectMap(json['quote']))
            : null,
      ),
      'image' => ImageMessageContent(
        localPath: json['localPath'] as String?,
        remotePath: json['remotePath'] as String?,
        thumbnailLocalPath: json['thumbnailLocalPath'] as String?,
        secret: json['secret'] as String?,
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
      ),
      'voice' => VoiceMessageContent(
        localPath: json['localPath'] as String?,
        remotePath: json['remotePath'] as String?,
        secret: json['secret'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      ),
      'file' => FileMessageContent(
        fileName: json['fileName'] as String?,
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
        mimeType: json['mimeType'] as String?,
        localPath: json['localPath'] as String?,
        remotePath: json['remotePath'] as String?,
        secret: json['secret'] as String?,
      ),
      'video' => VideoMessageContent(
        localPath: json['localPath'] as String?,
        remotePath: json['remotePath'] as String?,
        thumbnailLocalPath: json['thumbnailLocalPath'] as String?,
        secret: json['secret'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
      ),
      'location' => LocationMessageContent(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String?,
        title: json['title'] as String?,
      ),
      'contact' => ContactMessageContent(
        userId: json['userId'] as String? ?? '',
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      ),
      'custom' => CustomMessageContent(
        event: json['event'] as String? ?? '',
        params: _stringMap(json['params']),
      ),
      'system' => SystemMessageContent(
        text: json['text'] as String? ?? '',
        systemType: json['systemType'] as String?,
      ),
      'unknown' => UnknownMessageContent(
        rawType: json['rawType'] as String? ?? 'unknown',
        rawPayload: _objectMap(json['rawPayload']),
      ),
      _ => UnknownMessageContent(
        rawType: type ?? 'unknown',
        rawPayload: _objectMap(json),
      ),
    };
  }
}

final class TextMessageContent extends ChatMessageContent {
  const TextMessageContent(this.text, {this.quote});

  final String text;
  final ChatMessageQuote? quote;

  @override
  ChatMessageKind get kind => ChatMessageKind.text;

  @override
  Map<String, Object?> toJson() => {
    'type': 'text',
    'text': text,
    if (quote != null) 'quote': quote!.toJson(),
  };
}

sealed class AttachmentMessageContent extends ChatMessageContent {
  const AttachmentMessageContent({
    this.localPath,
    this.remotePath,
    this.secret,
  });

  final String? localPath;
  final String? remotePath;
  final String? secret;
}

final class ImageMessageContent extends AttachmentMessageContent {
  const ImageMessageContent({
    super.localPath,
    super.remotePath,
    super.secret,
    this.thumbnailLocalPath,
    this.width,
    this.height,
  });

  final String? thumbnailLocalPath;
  final double? width;
  final double? height;

  @override
  ChatMessageKind get kind => ChatMessageKind.image;

  @override
  ImageMessageContent withAttachmentPaths({
    String? localPath,
    String? thumbnailLocalPath,
  }) => ImageMessageContent(
    localPath: localPath ?? this.localPath,
    remotePath: remotePath,
    secret: secret,
    thumbnailLocalPath: thumbnailLocalPath ?? this.thumbnailLocalPath,
    width: width,
    height: height,
  );

  @override
  Map<String, Object?> toJson() => {
    'type': 'image',
    'localPath': localPath,
    'remotePath': remotePath,
    'thumbnailLocalPath': thumbnailLocalPath,
    'secret': secret,
    'width': width,
    'height': height,
  };
}

final class VoiceMessageContent extends AttachmentMessageContent {
  const VoiceMessageContent({
    super.localPath,
    super.remotePath,
    super.secret,
    required this.durationSeconds,
  });

  final int durationSeconds;

  @override
  ChatMessageKind get kind => ChatMessageKind.voice;

  @override
  VoiceMessageContent withAttachmentPaths({
    String? localPath,
    String? thumbnailLocalPath,
  }) => VoiceMessageContent(
    localPath: localPath ?? this.localPath,
    remotePath: remotePath,
    secret: secret,
    durationSeconds: durationSeconds,
  );

  @override
  Map<String, Object?> toJson() => {
    'type': 'voice',
    'localPath': localPath,
    'remotePath': remotePath,
    'secret': secret,
    'durationSeconds': durationSeconds,
  };
}

final class FileMessageContent extends AttachmentMessageContent {
  const FileMessageContent({
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    super.localPath,
    super.remotePath,
    super.secret,
  });

  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;

  @override
  ChatMessageKind get kind => ChatMessageKind.file;

  @override
  FileMessageContent withAttachmentPaths({
    String? localPath,
    String? thumbnailLocalPath,
  }) => FileMessageContent(
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    mimeType: mimeType,
    localPath: localPath ?? this.localPath,
    remotePath: remotePath,
    secret: secret,
  );

  @override
  Map<String, Object?> toJson() => {
    'type': 'file',
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'mimeType': mimeType,
    'localPath': localPath,
    'remotePath': remotePath,
    'secret': secret,
  };
}

final class VideoMessageContent extends AttachmentMessageContent {
  const VideoMessageContent({
    super.localPath,
    super.remotePath,
    super.secret,
    this.thumbnailLocalPath,
    this.durationSeconds = 0,
    this.width,
    this.height,
  });

  final String? thumbnailLocalPath;
  final int durationSeconds;
  final double? width;
  final double? height;

  @override
  ChatMessageKind get kind => ChatMessageKind.video;

  @override
  VideoMessageContent withAttachmentPaths({
    String? localPath,
    String? thumbnailLocalPath,
  }) => VideoMessageContent(
    localPath: localPath ?? this.localPath,
    remotePath: remotePath,
    secret: secret,
    thumbnailLocalPath: thumbnailLocalPath ?? this.thumbnailLocalPath,
    durationSeconds: durationSeconds,
    width: width,
    height: height,
  );

  @override
  Map<String, Object?> toJson() => {
    'type': 'video',
    'localPath': localPath,
    'remotePath': remotePath,
    'thumbnailLocalPath': thumbnailLocalPath,
    'secret': secret,
    'durationSeconds': durationSeconds,
    'width': width,
    'height': height,
  };
}

final class LocationMessageContent extends ChatMessageContent {
  const LocationMessageContent({
    required this.latitude,
    required this.longitude,
    this.address,
    this.title,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final String? title;

  @override
  ChatMessageKind get kind => ChatMessageKind.location;

  @override
  Map<String, Object?> toJson() => {
    'type': 'location',
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'title': title,
  };
}

final class ContactMessageContent extends ChatMessageContent {
  const ContactMessageContent({
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;

  @override
  ChatMessageKind get kind => ChatMessageKind.contact;

  @override
  Map<String, Object?> toJson() => {
    'type': 'contact',
    'userId': userId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
  };
}

final class CustomMessageContent extends ChatMessageContent {
  const CustomMessageContent({required this.event, this.params = const {}});

  final String event;
  final Map<String, Object?> params;

  @override
  ChatMessageKind get kind => ChatMessageKind.custom;

  @override
  Map<String, Object?> toJson() => {
    'type': 'custom',
    'event': event,
    'params': params,
  };
}

final class SystemMessageContent extends ChatMessageContent {
  const SystemMessageContent({required this.text, this.systemType});

  final String text;
  final String? systemType;

  @override
  ChatMessageKind get kind => ChatMessageKind.system;

  @override
  Map<String, Object?> toJson() => {
    'type': 'system',
    'text': text,
    'systemType': systemType,
  };
}

final class UnknownMessageContent extends ChatMessageContent {
  const UnknownMessageContent({
    required this.rawType,
    this.rawPayload = const {},
  });

  final String rawType;
  final Map<String, Object?> rawPayload;

  @override
  ChatMessageKind get kind => ChatMessageKind.unknown;

  @override
  Map<String, Object?> toJson() => {
    'type': 'unknown',
    'rawType': rawType,
    'rawPayload': rawPayload,
  };
}

Map<String, Object?> _stringMap(Object? raw) {
  if (raw is Map) {
    return {for (final entry in raw.entries) '${entry.key}': entry.value};
  }
  return const {};
}

Map<String, Object?> _objectMap(Object? raw) {
  if (raw is Map) {
    return {for (final entry in raw.entries) '${entry.key}': entry.value};
  }
  return const {};
}

/// Merges a server status/content update into an existing optimistic message,
/// keeping locally cached attachment paths when the update does not carry them.
ChatMessageContent mergeChatMessageContent(
  ChatMessageContent current,
  ChatMessageContent update,
) {
  final currentPath = current is AttachmentMessageContent
      ? current.localPath
      : null;
  final currentRemotePath = current is AttachmentMessageContent
      ? current.remotePath
      : null;
  final currentSecret = current is AttachmentMessageContent
      ? current.secret
      : null;
  final currentThumbnail = switch (current) {
    ImageMessageContent(:final thumbnailLocalPath) => thumbnailLocalPath,
    VideoMessageContent(:final thumbnailLocalPath) => thumbnailLocalPath,
    _ => null,
  };
  final currentDuration = switch (current) {
    VoiceMessageContent(:final durationSeconds) => durationSeconds,
    VideoMessageContent(:final durationSeconds) => durationSeconds,
    _ => 0,
  };
  return switch (update) {
    TextMessageContent(:final text) => text.isEmpty ? current : update,
    ImageMessageContent() => update.withAttachmentPaths(
      localPath: update.localPath ?? currentPath,
      thumbnailLocalPath: update.thumbnailLocalPath ?? currentThumbnail,
    ),
    VoiceMessageContent(:final durationSeconds) => VoiceMessageContent(
      localPath: update.localPath ?? currentPath,
      remotePath: update.remotePath ?? currentRemotePath,
      secret: update.secret ?? currentSecret,
      durationSeconds: durationSeconds > 0 ? durationSeconds : currentDuration,
    ),
    FileMessageContent() => FileMessageContent(
      fileName: update.fileName,
      fileSizeBytes: update.fileSizeBytes,
      mimeType: update.mimeType,
      localPath: update.localPath ?? currentPath,
      remotePath: update.remotePath ?? currentRemotePath,
      secret: update.secret ?? currentSecret,
    ),
    VideoMessageContent(:final durationSeconds) => VideoMessageContent(
      localPath: update.localPath ?? currentPath,
      remotePath: update.remotePath ?? currentRemotePath,
      secret: update.secret ?? currentSecret,
      thumbnailLocalPath: update.thumbnailLocalPath ?? currentThumbnail,
      durationSeconds: durationSeconds > 0 ? durationSeconds : currentDuration,
      width: update.width,
      height: update.height,
    ),
    _ => update,
  };
}
