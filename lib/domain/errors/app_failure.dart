/// Application-level failure types and user-facing error formatting.
///
/// This file lives in `domain/` so both the data layer (SDK/plugin mapping)
/// and the UI layer can depend on it without creating a UI-to-data import.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class ApiFailure extends AppFailure {
  const ApiFailure(this.statusCode, super.message, {this.body});

  final int statusCode;
  final String? body;
}

final class UnsupportedPlatformFailure extends AppFailure {
  const UnsupportedPlatformFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}

final _exceptionPrefix = RegExp(r'^Exception:\s*');
final _chatErrorPattern = RegExp(r'^code:\s*(-?\d+)\s*desc:\s*(.+)$');

/// Converts thrown objects (including raw Agora Chat errors) into a short,
/// user-facing message.
String friendlyError(Object error) {
  if (error is AppFailure) return error.message;

  final message = error.toString().trim();
  final chatError = _chatErrorPattern.firstMatch(message);
  if (chatError != null) {
    return chatError.group(2)!.trim();
  }

  return message.replaceFirst(_exceptionPrefix, '');
}
