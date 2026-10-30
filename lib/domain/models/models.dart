/// Barrel for app-owned domain models.
///
/// Adapters that also import a vendor SDK with clashing type names (for example
/// Agora's `ChatMessage`) import this file with a prefix to keep the two
/// worlds unambiguous.
library;

export 'chat_conversation.dart';
export 'chat_message.dart';
export 'chat_message_content.dart';
export 'chat_message_envelope.dart';
export 'chat_message_kind.dart';
export 'chat_message_quote.dart';
export 'friend_request_update.dart';
export 'group_member.dart';
export 'group_mute_state.dart';
export 'outbox_message.dart';
export 'user_profile.dart';
export 'voice_recording.dart';
