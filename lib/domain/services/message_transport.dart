import '../models/chat_message_kind.dart';

enum MessageTransportMode { native, custom, hybrid }

MessageTransportMode messageTransportModeFrom(String value) =>
    switch (value.trim().toLowerCase()) {
      'native' => MessageTransportMode.native,
      'custom' => MessageTransportMode.custom,
      _ => MessageTransportMode.hybrid,
    };

class AttachmentUploadRequest {
  const AttachmentUploadRequest({
    required this.localPath,
    required this.kind,
    this.fileName,
    this.mimeType,
  });

  final String localPath;
  final ChatMessageKind kind;
  final String? fileName;
  final String? mimeType;
}

class AttachmentUploadResult {
  const AttachmentUploadResult({
    required this.url,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
  });

  final String url;
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
}

/// Uploads an attachment to an external object store.
///
/// This is the seam for "custom protocol + own OSS". When no uploader is
/// configured, `hybrid` mode falls back to the native SDK message type and
/// `custom` mode refuses to send instead of losing the local file.
abstract interface class AttachmentUploader {
  Future<AttachmentUploadResult?> upload(AttachmentUploadRequest request);
}
