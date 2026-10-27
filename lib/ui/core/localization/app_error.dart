import '../../../domain/errors/app_failure.dart';
import '../../../l10n/app_localizations.dart';

/// Stable, UI-independent error identity.
///
/// ViewModels expose [AppError] instead of localized strings so every screen
/// can render the message in the active locale. [detail] is reserved for raw
/// server/SDK text that cannot be translated.
enum AppErrorCode {
  sessionExpired,
  missingPasswordCredentials,
  missingTokenCredentials,
  logoutFailed,
  groupNameRequired,
  groupMembersRequired,
  addFriendIdRequired,
  attachmentPathExpired,
  imagePickFailed,
  microphonePermission,
  recordingStartFailed,
  recordingTooShort,
  recordingStopFailed,
  voiceNotDownloaded,
  voicePlaybackFailed,
  chatUnavailable,
  platformUnsupported,
  unknown,
}

class AppError {
  const AppError(this.code, {this.detail});

  factory AppError.from(Object error) {
    if (error is UnsupportedError || error is UnsupportedPlatformFailure) {
      return const AppError(AppErrorCode.platformUnsupported);
    }
    final detail = friendlyError(error).trim();
    return AppError(
      AppErrorCode.unknown,
      detail: detail.isEmpty ? null : detail,
    );
  }

  final AppErrorCode code;
  final String? detail;

  @override
  String toString() => detail == null ? code.name : '${code.name}: $detail';
}

String localizedError(AppLocalizations l10n, AppError error) {
  final detail = error.detail?.trim() ?? '';
  return switch (error.code) {
    AppErrorCode.sessionExpired => l10n.errorSessionExpired,
    AppErrorCode.missingPasswordCredentials =>
      l10n.errorMissingPasswordCredentials,
    AppErrorCode.missingTokenCredentials => l10n.errorMissingTokenCredentials,
    AppErrorCode.logoutFailed => l10n.errorLogoutFailed(detail),
    AppErrorCode.groupNameRequired => l10n.errorGroupNameRequired,
    AppErrorCode.groupMembersRequired => l10n.errorGroupMembersRequired,
    AppErrorCode.addFriendIdRequired => l10n.errorAddFriendIdRequired,
    AppErrorCode.attachmentPathExpired => l10n.errorAttachmentPathExpired,
    AppErrorCode.imagePickFailed => l10n.errorImagePickFailed(detail),
    AppErrorCode.microphonePermission => l10n.errorMicrophonePermission,
    AppErrorCode.recordingStartFailed => l10n.errorRecordingStartFailed(detail),
    AppErrorCode.recordingTooShort => l10n.errorRecordingTooShort,
    AppErrorCode.recordingStopFailed => l10n.errorRecordingStopFailed(detail),
    AppErrorCode.voiceNotDownloaded => l10n.errorVoiceNotDownloaded,
    AppErrorCode.voicePlaybackFailed => l10n.errorVoicePlaybackFailed(detail),
    AppErrorCode.chatUnavailable => l10n.errorChatUnavailable,
    AppErrorCode.platformUnsupported => l10n.errorPlatformUnsupported,
    AppErrorCode.unknown => detail.isEmpty ? l10n.errorUnknown : detail,
  };
}
