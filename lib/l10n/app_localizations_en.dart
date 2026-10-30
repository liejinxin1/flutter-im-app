// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'E-Chat';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get more => 'More';

  @override
  String get close => 'Close';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonMessage =>
      'This setting is not available in the current chat MVP.';

  @override
  String get aboutLegalese => 'Agora Chat Flutter client';

  @override
  String get loginTitle => 'Log in to Agora Chat';

  @override
  String get loginSubtitle =>
      'Chat one-to-one with a user created in the Agora Console';

  @override
  String get userIdLabel => 'User ID';

  @override
  String get passwordLogin => 'Password';

  @override
  String get tokenLogin => 'Token';

  @override
  String get passwordLabel => 'Password';

  @override
  String get tokenLabel => 'Chat Token';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String get loginButton => 'Log in';

  @override
  String get webPreviewNote =>
      'The web build is a UI preview; Agora Chat currently sends and receives on Android/iOS through the native Flutter SDK.';

  @override
  String get passwordHint =>
      'Password login is for local testing. In production, issue a user token from your own server.';

  @override
  String get tokenHint => 'Use a user token issued by your trusted server.';

  @override
  String get chatsTab => 'Chats';

  @override
  String get groupsTab => 'Groups';

  @override
  String get profileTab => 'Profile';

  @override
  String get moreTab => 'More';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get searchOrAddFriend => 'Search or add a friend';

  @override
  String get addFriendOrGroup => 'Add a friend or create a group';

  @override
  String get viewAction => 'View';

  @override
  String friendRequestReceived(String userId) {
    return '$userId sent you a friend request';
  }

  @override
  String groupInvitationReceived(String inviter, String group) {
    return '$inviter invited you to $group';
  }

  @override
  String groupInvitationAccepted(String group) {
    return 'You joined $group';
  }

  @override
  String groupInvitationDeclined(String group) {
    return 'You declined the invitation to $group';
  }

  @override
  String friendRequestAccepted(String userId) {
    return '$userId accepted your friend request';
  }

  @override
  String friendRequestDeclined(String userId) {
    return '$userId declined your friend request';
  }

  @override
  String friendRequestAdded(String userId) {
    return '$userId is now a contact';
  }

  @override
  String get addFriendAction => 'Add friend';

  @override
  String get createGroupAction => 'Create group';

  @override
  String get conversationsUnavailable =>
      'Conversations are unavailable right now';

  @override
  String get noChats => 'No chats yet';

  @override
  String get noGroups => 'No groups yet';

  @override
  String get noChatsDetail =>
      'Add a friend, or start a chat with their Agora Chat user ID.';

  @override
  String get noGroupsDetail =>
      'Create a group and invite contacts to start chatting.';

  @override
  String get startConversation => 'Send a message to start the conversation';

  @override
  String get imageMessage => '[Image]';

  @override
  String get voiceMessage => '[Voice]';

  @override
  String get fileMessage => 'File';

  @override
  String fileDownloaded(String name) {
    return 'File downloaded: $name';
  }

  @override
  String fileOpened(String name) {
    return 'Opened: $name';
  }

  @override
  String get fileOpenFailed => 'Couldn\'t open the file.';

  @override
  String get fileDownloadFailed => 'Couldn\'t download the file.';

  @override
  String get videoMessage => 'Video';

  @override
  String get locationMessage => 'Location';

  @override
  String get contactMessage => 'Contact';

  @override
  String get customMessage => 'Custom message';

  @override
  String get systemMessage => 'System message';

  @override
  String get unsupportedMessage => 'Unsupported message';

  @override
  String get conversationPreviewImage => '[Image]';

  @override
  String get conversationPreviewVoice => '[Voice]';

  @override
  String get conversationPreviewFile => '[File]';

  @override
  String get conversationPreviewVideo => '[Video]';

  @override
  String get conversationPreviewLocation => '[Location]';

  @override
  String get conversationPreviewContact => '[Contact]';

  @override
  String get conversationPreviewCustom => '[Custom message]';

  @override
  String get conversationPreviewSystem => '[System message]';

  @override
  String get conversationPreviewUnknown => '[Unsupported message]';

  @override
  String get chatTitle => 'Chat';

  @override
  String get conversationDetails => 'Conversation details';

  @override
  String get showUserId => 'Show user ID';

  @override
  String get groupChat => 'Group chat';

  @override
  String groupMembers(num count) {
    return '$count members';
  }

  @override
  String get groupProfile => 'Group profile';

  @override
  String get groupMembersTitle => 'Group members';

  @override
  String get videoCall => 'Video call';

  @override
  String get voiceCall => 'Voice call';

  @override
  String get messageHint => 'Type a message…';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get sendFailedRetry => 'Failed to send. Retry.';

  @override
  String get copy => 'Copy';

  @override
  String get delete => 'Delete';

  @override
  String get recall => 'Recall';

  @override
  String get quote => 'Quote';

  @override
  String get forward => 'Forward';

  @override
  String get select => 'Select';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteMessagesTitle => 'Delete messages?';

  @override
  String get deleteMessagesBody =>
      'This removes the selected messages from this device.';

  @override
  String get recallMessageTitle => 'Recall this message?';

  @override
  String get recallMessageBody => 'Recalled messages cannot be restored.';

  @override
  String get recalledMessage => 'Message recalled';

  @override
  String get quotedMessage => 'Quoted message';

  @override
  String get quotedMessageNotFound =>
      'The quoted message is no longer available.';

  @override
  String get forwardTo => 'Forward to';

  @override
  String get noConversations => 'No conversations available';

  @override
  String get forwarded => 'Forwarded';

  @override
  String get copied => 'Copied';

  @override
  String get deleted => 'Deleted';

  @override
  String selectedMessages(num count) {
    return '$count selected';
  }

  @override
  String messageActionFailed(String detail) {
    return 'Action failed: $detail';
  }

  @override
  String rtcComingSoon(String callType) {
    return '$callType calls will be available after Agora RTC integration.';
  }

  @override
  String get rtcVideoComingSoon =>
      'Video calls will be available after Agora RTC integration.';

  @override
  String get rtcVoiceComingSoon =>
      'Voice calls will be available after Agora RTC integration.';

  @override
  String get conversationDetailsUnavailable =>
      'Conversation details are not available yet.';

  @override
  String userIdValue(String userId) {
    return 'User ID: $userId';
  }

  @override
  String get contactShareUnavailable => 'Contact sharing is not available yet.';

  @override
  String get locationUnavailable => 'Location messages are not available yet.';

  @override
  String get documentUnavailable => 'File messages are not available yet.';

  @override
  String get camera => 'Camera';

  @override
  String get send => 'Send';

  @override
  String get withdrawRecording => 'Withdraw';

  @override
  String get recordingExitTitle => 'Send voice message?';

  @override
  String get recordingExitBody =>
      'You tapped outside the recording bar. Send this recording or withdraw it?';

  @override
  String get noMoreMessages => 'No more messages';

  @override
  String newMessages(int count) {
    return '$count new messages';
  }

  @override
  String get voiceLimitReached => '60s limit reached, sending…';

  @override
  String get myLocation => 'My Location';

  @override
  String get documentAction => 'Document';

  @override
  String get editRemark => 'Edit remark';

  @override
  String get sendMessage => 'Send message';

  @override
  String get friendProfile => 'Contact profile';

  @override
  String get remark => 'Remark';

  @override
  String get noRemark => 'No remark';

  @override
  String get remarkHint => 'Add a remark';

  @override
  String get save => 'Save';

  @override
  String get remarkUpdated => 'Remark updated';

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get gallery => 'Gallery';

  @override
  String get voiceRecording => 'Record';

  @override
  String stopRecording(String duration) {
    return 'Stop $duration';
  }

  @override
  String get contact => 'Contact';

  @override
  String get location => 'Location';

  @override
  String get document => 'File';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsLoadFailed => 'Couldn\'t load contacts. Tap to retry.';

  @override
  String get noContacts => 'No contacts yet';

  @override
  String get agoraChatContact => 'Agora Chat contact';

  @override
  String get addFriendTitle => 'Add friend';

  @override
  String get findPeople => 'Find people';

  @override
  String get addFriendDescription =>
      'Enter an Agora Chat user ID to send a friend request.';

  @override
  String get userIdHint => 'Agora Chat user ID';

  @override
  String get sendFriendRequest => 'Send friend request';

  @override
  String get agoraChatUser => 'Agora Chat user';

  @override
  String friendRequestSent(String name) {
    return 'Friend request sent to $name.';
  }

  @override
  String get searchForFriend => 'Search for a friend';

  @override
  String get friendRequestsTitle => 'Requests & invitations';

  @override
  String get noPendingFriendRequests =>
      'No friend requests or group invitations';

  @override
  String get requestUpdateFailed => 'Could not update this request. Try again.';

  @override
  String get groupInvitation => 'Group invitation';

  @override
  String get friendRequestLabel => 'Friend request';

  @override
  String invitedByUser(String userId) {
    return 'Invited by $userId';
  }

  @override
  String get requestStatusAccepted => 'Accepted';

  @override
  String get requestStatusDeclined => 'Declined';

  @override
  String get requestStatusAdded => 'Added';

  @override
  String get requestStatusPending => 'Pending';

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get createGroupTitle => 'Create group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'Enter group name';

  @override
  String get members => 'Members';

  @override
  String selectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'No members selected',
    );
    return '$_temp0';
  }

  @override
  String get addMembersToGroup => 'Add members to group';

  @override
  String get editSelectedMembers => 'Edit selected members';

  @override
  String get createGroupButton => 'Create Group';

  @override
  String get addMembersTitle => 'Add members to group';

  @override
  String get searchContacts => 'Search contacts';

  @override
  String get noContactsAddFriend => 'No contacts yet. Add a friend first.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get gender => 'Gender';

  @override
  String get birthday => 'Birthday';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get avatarUrl => 'Avatar URL';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get agoraChatAccount => 'Agora Chat account';

  @override
  String get userIdTitle => 'User ID';

  @override
  String get userIdSubtitle => 'Your Agora Chat identifier';

  @override
  String get accountStatus => 'Account status';

  @override
  String get signOut => 'Sign out';

  @override
  String get moreTitle => 'More';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get storage => 'Storage';

  @override
  String get networkHistory => 'Show network chat history';

  @override
  String get networkHistorySubtitle =>
      'When off, only locally cached history is shown';

  @override
  String get helpFeedback => 'Help & Feedback';

  @override
  String get aboutEchat => 'About E-Chat';

  @override
  String get contacts => 'Contacts';

  @override
  String get friendRequests => 'Friend requests';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please log in again.';

  @override
  String get errorMissingPasswordCredentials =>
      'Enter your user ID and password.';

  @override
  String get errorMissingTokenCredentials =>
      'Enter your user ID and Chat Token.';

  @override
  String errorLogoutFailed(String detail) {
    return 'Couldn\'t sign out: $detail';
  }

  @override
  String get errorGroupNameRequired => 'Enter a group name.';

  @override
  String get errorGroupMembersRequired => 'Select at least one member.';

  @override
  String get errorAddFriendIdRequired => 'Enter an Agora Chat user ID.';

  @override
  String get errorAttachmentPathExpired =>
      'The attachment path is no longer valid. Choose the file again.';

  @override
  String errorImagePickFailed(String detail) {
    return 'Couldn\'t select the image: $detail';
  }

  @override
  String errorFilePickFailed(String detail) {
    return 'Couldn\'t select the file: $detail';
  }

  @override
  String get errorMicrophonePermission =>
      'Microphone permission is required to record voice messages.';

  @override
  String errorRecordingStartFailed(String detail) {
    return 'Couldn\'t start recording: $detail';
  }

  @override
  String get errorRecordingTooShort =>
      'Recording is too short. Record at least 1 second.';

  @override
  String errorRecordingStopFailed(String detail) {
    return 'Couldn\'t stop recording: $detail';
  }

  @override
  String get errorVoiceNotDownloaded =>
      'The voice file hasn\'t been downloaded yet.';

  @override
  String errorVoicePlaybackFailed(String detail) {
    return 'Couldn\'t play the voice message: $detail';
  }

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorChatUnavailable =>
      'Chat is temporarily unavailable. Please try again.';

  @override
  String get errorPlatformUnsupported =>
      'Agora Chat is only available on Android and iOS.';
}
