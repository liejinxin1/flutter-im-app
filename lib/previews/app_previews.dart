import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../app/app_dependencies.dart';
import '../domain/models/friend_request_update.dart';
import '../ui/features/auth/view_models/auth_view_model.dart';
import '../ui/features/auth/views/auth_screen.dart';
import '../ui/features/contacts/view_models/contacts_view_model.dart';
import '../ui/features/contacts/views/add_friend_screen.dart';
import '../ui/features/contacts/views/contacts_screen.dart';
import '../ui/features/contacts/views/friend_requests_screen.dart';
import '../ui/features/conversation/views/conversation_screen.dart';
import '../ui/features/groups/views/create_group_screen.dart';
import '../ui/features/more/views/more_screen.dart';
import '../ui/features/profile/view_models/profile_view_model.dart';
import '../ui/features/profile/views/profile_screen.dart';
import '../ui/features/shell/views/app_shell.dart';
import 'preview_fakes.dart';
import 'preview_host.dart';

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

@Preview(name: 'Login', group: 'IM Screens', size: Size(393, 852))
Widget loginPreview() => const PreviewHost(child: _AuthPreview());

class _AuthPreview extends StatefulWidget {
  const _AuthPreview();

  @override
  State<_AuthPreview> createState() => _AuthPreviewState();
}

class _AuthPreviewState extends State<_AuthPreview> {
  late final AuthViewModel _viewModel = previewAuthViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScreen(viewModel: _viewModel);
}

// ---------------------------------------------------------------------------
// Main shell tabs
// ---------------------------------------------------------------------------

@Preview(name: 'Chats', group: 'IM Screens', size: Size(393, 852))
Widget chatsPreview() => const PreviewHost(child: _AppShellPreview(tab: 0));

@Preview(name: 'Groups', group: 'IM Screens', size: Size(393, 852))
Widget groupsPreview() => const PreviewHost(child: _AppShellPreview(tab: 1));

@Preview(name: 'Profile tab', group: 'IM Screens', size: Size(393, 852))
Widget profileTabPreview() =>
    const PreviewHost(child: _AppShellPreview(tab: 2));

@Preview(name: 'More tab', group: 'IM Screens', size: Size(393, 852))
Widget moreTabPreview() => const PreviewHost(child: _AppShellPreview(tab: 3));

class _AppShellPreview extends StatefulWidget {
  const _AppShellPreview({required this.tab});

  final int tab;

  @override
  State<_AppShellPreview> createState() => _AppShellPreviewState();
}

class _AppShellPreviewState extends State<_AppShellPreview> {
  late final AppDependencies _dependencies = previewDependencies();
  late final AuthViewModel _auth = previewAuthViewModel();

  @override
  void dispose() {
    _auth.dispose();
    unawaited(_dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
    dependencies: _dependencies,
    authViewModel: _auth,
    currentUserId: 'alice',
    initialTab: widget.tab,
  );
}

// ---------------------------------------------------------------------------
// Conversation
// ---------------------------------------------------------------------------

@Preview(name: 'Conversation', group: 'IM Screens', size: Size(393, 852))
Widget conversationPreview() => PreviewHost(
  child: ConversationScreen(
    repository: PreviewChatRepository(),
    media: PreviewMediaGateway(),
    outbox: PreviewOutboxRepository(),
    currentUserId: 'alice',
    peerId: 'echat001',
    peerName: 'David Wayne',
  ),
);

// ---------------------------------------------------------------------------
// Contacts / groups / profile pages
// ---------------------------------------------------------------------------

@Preview(name: 'Contacts', group: 'IM Screens', size: Size(393, 852))
Widget contactsPreview() => const PreviewHost(child: _ContactsPreview());

class _ContactsPreview extends StatefulWidget {
  const _ContactsPreview();

  @override
  State<_ContactsPreview> createState() => _ContactsPreviewState();
}

class _ContactsPreviewState extends State<_ContactsPreview> {
  late final ContactsViewModel _viewModel = ContactsViewModel(
    PreviewContactRepository(),
    PreviewProfileRepository(),
    PreviewFriendRequestStore(),
    'alice',
  )..load();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ContactsScreen(viewModel: _viewModel, onOpenConversation: (_) {});
}

@Preview(name: 'Friend requests', group: 'IM Screens', size: Size(393, 852))
Widget friendRequestsPreview() => PreviewHost(
  child: FriendRequestsScreen(
    requests: const [
      FriendRequestUpdate(
        userId: 'david',
        type: FriendRequestUpdateType.received,
        reason: 'Hi, I am David',
      ),
      FriendRequestUpdate(
        userId: 'angela',
        type: FriendRequestUpdateType.received,
        reason: 'Let us connect',
      ),
    ],
    onRespond: (userId, {required accept}) async => true,
  ),
);

@Preview(name: 'Add friend', group: 'IM Screens', size: Size(393, 852))
Widget addFriendPreview() => PreviewHost(
  child: AddFriendScreen(
    contacts: PreviewContactRepository(),
    profiles: PreviewProfileRepository(),
  ),
);

@Preview(name: 'Create group', group: 'IM Screens', size: Size(393, 852))
Widget createGroupPreview() => PreviewHost(
  child: CreateGroupScreen(
    contacts: PreviewContactRepository(),
    groups: PreviewGroupRepository(),
  ),
);

@Preview(name: 'Profile page', group: 'IM Screens', size: Size(393, 852))
Widget profilePagePreview() => const PreviewHost(child: _ProfilePreview());

class _ProfilePreview extends StatefulWidget {
  const _ProfilePreview();

  @override
  State<_ProfilePreview> createState() => _ProfilePreviewState();
}

class _ProfilePreviewState extends State<_ProfilePreview> {
  late final ProfileViewModel _viewModel = ProfileViewModel(
    PreviewProfileRepository(),
    'alice',
  )..load();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ProfileScreen(viewModel: _viewModel, onLogout: () {});
}

@Preview(name: 'More page', group: 'IM Screens', size: Size(393, 852))
Widget morePagePreview() => PreviewHost(
  child: MoreScreen(
    userId: 'alice',
    displayName: 'Alex Chen',
    onLogout: () {},
    onFriendRequests: () {},
    onContacts: () {},
    friendRequestCount: 2,
  ),
);
