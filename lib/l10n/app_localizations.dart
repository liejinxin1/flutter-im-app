import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'E-Chat'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This setting is not available in the current chat MVP.'**
  String get comingSoonMessage;

  /// No description provided for @aboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Agora Chat Flutter client'**
  String get aboutLegalese;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to Agora Chat'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat one-to-one with a user created in the Agora Console'**
  String get loginSubtitle;

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdLabel;

  /// No description provided for @passwordLogin.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLogin;

  /// No description provided for @tokenLogin.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get tokenLogin;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat Token'**
  String get tokenLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @webPreviewNote.
  ///
  /// In en, this message translates to:
  /// **'The web build is a UI preview; Agora Chat currently sends and receives on Android/iOS through the native Flutter SDK.'**
  String get webPreviewNote;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password login is for local testing. In production, issue a user token from your own server.'**
  String get passwordHint;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'Use a user token issued by your trusted server.'**
  String get tokenHint;

  /// No description provided for @chatsTab.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTab;

  /// No description provided for @groupsTab.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @moreTab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTab;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @searchOrAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Search or add a friend'**
  String get searchOrAddFriend;

  /// No description provided for @addFriendOrGroup.
  ///
  /// In en, this message translates to:
  /// **'Add a friend or create a group'**
  String get addFriendOrGroup;

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @friendRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'{userId} sent you a friend request'**
  String friendRequestReceived(String userId);

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'{userId} accepted your friend request'**
  String friendRequestAccepted(String userId);

  /// No description provided for @friendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'{userId} declined your friend request'**
  String friendRequestDeclined(String userId);

  /// No description provided for @friendRequestAdded.
  ///
  /// In en, this message translates to:
  /// **'{userId} is now a contact'**
  String friendRequestAdded(String userId);

  /// No description provided for @addFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriendAction;

  /// No description provided for @createGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupAction;

  /// No description provided for @conversationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Conversations are unavailable right now'**
  String get conversationsUnavailable;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChats;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroups;

  /// No description provided for @noChatsDetail.
  ///
  /// In en, this message translates to:
  /// **'Add a friend, or start a chat with their Agora Chat user ID.'**
  String get noChatsDetail;

  /// No description provided for @noGroupsDetail.
  ///
  /// In en, this message translates to:
  /// **'Create a group and invite contacts to start chatting.'**
  String get noGroupsDetail;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation'**
  String get startConversation;

  /// No description provided for @imageMessage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get imageMessage;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'[Voice]'**
  String get voiceMessage;

  /// No description provided for @fileMessage.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileMessage;

  /// No description provided for @videoMessage.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoMessage;

  /// No description provided for @locationMessage.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationMessage;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactMessage;

  /// No description provided for @customMessage.
  ///
  /// In en, this message translates to:
  /// **'Custom message'**
  String get customMessage;

  /// No description provided for @systemMessage.
  ///
  /// In en, this message translates to:
  /// **'System message'**
  String get systemMessage;

  /// No description provided for @unsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unsupported message'**
  String get unsupportedMessage;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @conversationDetails.
  ///
  /// In en, this message translates to:
  /// **'Conversation details'**
  String get conversationDetails;

  /// No description provided for @showUserId.
  ///
  /// In en, this message translates to:
  /// **'Show user ID'**
  String get showUserId;

  /// No description provided for @groupChat.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get groupChat;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get videoCall;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get voiceCall;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get messageHint;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @sendFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to send. Retry.'**
  String get sendFailedRetry;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @recall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get recall;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete messages?'**
  String get deleteMessagesTitle;

  /// No description provided for @deleteMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected messages from this device.'**
  String get deleteMessagesBody;

  /// No description provided for @recallMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall this message?'**
  String get recallMessageTitle;

  /// No description provided for @recallMessageBody.
  ///
  /// In en, this message translates to:
  /// **'Recalled messages cannot be restored.'**
  String get recallMessageBody;

  /// No description provided for @recalledMessage.
  ///
  /// In en, this message translates to:
  /// **'Message recalled'**
  String get recalledMessage;

  /// No description provided for @quotedMessage.
  ///
  /// In en, this message translates to:
  /// **'Quoted message'**
  String get quotedMessage;

  /// No description provided for @quotedMessageNotFound.
  ///
  /// In en, this message translates to:
  /// **'The quoted message is no longer available.'**
  String get quotedMessageNotFound;

  /// No description provided for @forwardTo.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get forwardTo;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations available'**
  String get noConversations;

  /// No description provided for @forwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get forwarded;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @selectedMessages.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedMessages(num count);

  /// No description provided for @messageActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {detail}'**
  String messageActionFailed(String detail);

  /// No description provided for @rtcComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{callType} calls will be available after Agora RTC integration.'**
  String rtcComingSoon(String callType);

  /// No description provided for @rtcVideoComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Video calls will be available after Agora RTC integration.'**
  String get rtcVideoComingSoon;

  /// No description provided for @rtcVoiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Voice calls will be available after Agora RTC integration.'**
  String get rtcVoiceComingSoon;

  /// No description provided for @conversationDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Conversation details are not available yet.'**
  String get conversationDetailsUnavailable;

  /// No description provided for @userIdValue.
  ///
  /// In en, this message translates to:
  /// **'User ID: {userId}'**
  String userIdValue(String userId);

  /// No description provided for @contactShareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact sharing is not available yet.'**
  String get contactShareUnavailable;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location messages are not available yet.'**
  String get locationUnavailable;

  /// No description provided for @documentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'File messages are not available yet.'**
  String get documentUnavailable;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @voiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get voiceRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop {duration}'**
  String stopRecording(String duration);

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get document;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load contacts. Tap to retry.'**
  String get contactsLoadFailed;

  /// No description provided for @noContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContacts;

  /// No description provided for @agoraChatContact.
  ///
  /// In en, this message translates to:
  /// **'Agora Chat contact'**
  String get agoraChatContact;

  /// No description provided for @addFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriendTitle;

  /// No description provided for @findPeople.
  ///
  /// In en, this message translates to:
  /// **'Find people'**
  String get findPeople;

  /// No description provided for @addFriendDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter an Agora Chat user ID to send a friend request.'**
  String get addFriendDescription;

  /// No description provided for @userIdHint.
  ///
  /// In en, this message translates to:
  /// **'Agora Chat user ID'**
  String get userIdHint;

  /// No description provided for @sendFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get sendFriendRequest;

  /// No description provided for @agoraChatUser.
  ///
  /// In en, this message translates to:
  /// **'Agora Chat user'**
  String get agoraChatUser;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {name}.'**
  String friendRequestSent(String name);

  /// No description provided for @searchForFriend.
  ///
  /// In en, this message translates to:
  /// **'Search for a friend'**
  String get searchForFriend;

  /// No description provided for @friendRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequestsTitle;

  /// No description provided for @noPendingFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending friend requests'**
  String get noPendingFriendRequests;

  /// No description provided for @requestUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update this request. Try again.'**
  String get requestUpdateFailed;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @createGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupTitle;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get groupNameHint;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members selected} =1{1 selected} other{{count} selected}}'**
  String selectedCount(num count);

  /// No description provided for @addMembersToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add members to group'**
  String get addMembersToGroup;

  /// No description provided for @editSelectedMembers.
  ///
  /// In en, this message translates to:
  /// **'Edit selected members'**
  String get editSelectedMembers;

  /// No description provided for @createGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupButton;

  /// No description provided for @addMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add members to group'**
  String get addMembersTitle;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContacts;

  /// No description provided for @noContactsAddFriend.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet. Add a friend first.'**
  String get noContactsAddFriend;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @agoraChatAccount.
  ///
  /// In en, this message translates to:
  /// **'Agora Chat account'**
  String get agoraChatAccount;

  /// No description provided for @userIdTitle.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdTitle;

  /// No description provided for @userIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Agora Chat identifier'**
  String get userIdSubtitle;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatus;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpFeedback;

  /// No description provided for @aboutEchat.
  ///
  /// In en, this message translates to:
  /// **'About E-Chat'**
  String get aboutEchat;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequests;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please log in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorMissingPasswordCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your user ID and password.'**
  String get errorMissingPasswordCredentials;

  /// No description provided for @errorMissingTokenCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your user ID and Chat Token.'**
  String get errorMissingTokenCredentials;

  /// No description provided for @errorLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign out: {detail}'**
  String errorLogoutFailed(String detail);

  /// No description provided for @errorGroupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a group name.'**
  String get errorGroupNameRequired;

  /// No description provided for @errorGroupMembersRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one member.'**
  String get errorGroupMembersRequired;

  /// No description provided for @errorAddFriendIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an Agora Chat user ID.'**
  String get errorAddFriendIdRequired;

  /// No description provided for @errorAttachmentPathExpired.
  ///
  /// In en, this message translates to:
  /// **'The attachment path is no longer valid. Choose the file again.'**
  String get errorAttachmentPathExpired;

  /// No description provided for @errorImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t select the image: {detail}'**
  String errorImagePickFailed(String detail);

  /// No description provided for @errorMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record voice messages.'**
  String get errorMicrophonePermission;

  /// No description provided for @errorRecordingStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start recording: {detail}'**
  String errorRecordingStartFailed(String detail);

  /// No description provided for @errorRecordingTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording is too short. Record at least 1 second.'**
  String get errorRecordingTooShort;

  /// No description provided for @errorRecordingStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t stop recording: {detail}'**
  String errorRecordingStopFailed(String detail);

  /// No description provided for @errorVoiceNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'The voice file hasn\'t been downloaded yet.'**
  String get errorVoiceNotDownloaded;

  /// No description provided for @errorVoicePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play the voice message: {detail}'**
  String errorVoicePlaybackFailed(String detail);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Chat is temporarily unavailable. Please try again.'**
  String get errorChatUnavailable;

  /// No description provided for @errorPlatformUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Agora Chat is only available on Android and iOS.'**
  String get errorPlatformUnsupported;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
