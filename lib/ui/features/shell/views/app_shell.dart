import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/coordinators/outbox_coordinator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../domain/models/chat_conversation.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../../domain/models/friend_request_update.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_navigation_rail.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../contacts/view_models/contacts_view_model.dart';
import '../../contacts/views/add_friend_screen.dart';
import '../../contacts/views/contacts_screen.dart';
import '../../contacts/views/friend_requests_screen.dart';
import '../../groups/views/create_group_screen.dart';
import '../../inbox/view_models/inbox_view_model.dart';
import '../../inbox/views/inbox_screen.dart';
import '../../more/views/more_screen.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.dependencies,
    required this.authViewModel,
    required this.currentUserId,
    this.initialTab = 0,
  });

  final AppDependencies dependencies;
  final AuthViewModel authViewModel;
  final String currentUserId;
  final int initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final InboxViewModel _inbox;
  late final ContactsViewModel _contacts;
  late final ProfileViewModel _profile;
  late final OutboxCoordinator _outbox;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3).toInt();
    _inbox = InboxViewModel(
      widget.dependencies.chat,
      widget.dependencies.session,
      widget.dependencies.profiles,
    )..addListener(_onInboxChanged);
    _contacts = ContactsViewModel(
      widget.dependencies.contacts,
      widget.dependencies.profiles,
      widget.dependencies.friendRequests,
      widget.currentUserId,
    )..addListener(_onContactsChanged);
    _profile = ProfileViewModel(
      widget.dependencies.profiles,
      widget.currentUserId,
    )..load();
    _outbox = OutboxCoordinator(
      widget.dependencies.chat,
      widget.dependencies.session,
      widget.currentUserId,
    )..start();
    _inbox.start();
  }

  @override
  void dispose() {
    _inbox
      ..removeListener(_onInboxChanged)
      ..dispose();
    _contacts
      ..removeListener(_onContactsChanged)
      ..dispose();
    _profile.dispose();
    unawaited(_outbox.dispose());
    super.dispose();
  }

  void _onInboxChanged() {
    final toast = _inbox.incomingToast;
    if (toast == null) return;
    _inbox.consumeIncomingToast();
    _showIncomingMessage(toast);
  }

  void _onContactsChanged() {
    final toast = _contacts.requestToast;
    if (toast == null) return;
    _contacts.consumeRequestToast();
    _showFriendRequest(toast);
  }

  void _showIncomingMessage(ChatMessage message) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${message.senderId}: ${message.text}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showFriendRequest(FriendRequestUpdate update) {
    if (!mounted) return;
    final l10n = context.l10n;
    final text = switch (update.type) {
      FriendRequestUpdateType.received => l10n.friendRequestReceived(
        update.userId,
      ),
      FriendRequestUpdateType.accepted => l10n.friendRequestAccepted(
        update.userId,
      ),
      FriendRequestUpdateType.declined => l10n.friendRequestDeclined(
        update.userId,
      ),
      FriendRequestUpdateType.contactAdded => l10n.friendRequestAdded(
        update.userId,
      ),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: update.type == FriendRequestUpdateType.received
              ? SnackBarAction(
                  label: l10n.viewAction,
                  onPressed: () => setState(() => _selectedTab = 3),
                )
              : null,
        ),
      );
  }

  Future<void> _openFriendRequests() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ListenableBuilder(
          listenable: _contacts,
          builder: (_, _) => FriendRequestsScreen(
            requests: _contacts.pendingFriendRequests,
            onRespond: _contacts.respondToFriendRequest,
          ),
        ),
      ),
    );
  }

  Future<void> _openContacts() async {
    await _contacts.load();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ContactsScreen(
          viewModel: _contacts,
          onOpenConversation: (userId) => _openConversation(userId),
        ),
      ),
    );
    if (mounted) await _inbox.refresh(showLoading: false);
  }

  Future<void> _logout() async {
    await widget.authViewModel.logout();
    if (!mounted || !widget.authViewModel.isLoggedIn) return;
    final error = widget.authViewModel.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(context.l10n, error))),
      );
    }
  }

  Future<void> _openAddFriend() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddFriendScreen(
          contacts: widget.dependencies.contacts,
          profiles: widget.dependencies.profiles,
        ),
      ),
    );
  }

  Future<void> _openAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE2E8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF7FD),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.brandBlueLight,
                  ),
                ),
                title: Text(
                  context.l10n.addFriendAction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, 'friend'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF7FD),
                  child: Icon(
                    Icons.group_add_rounded,
                    color: AppColors.brandBlueLight,
                  ),
                ),
                title: Text(
                  context.l10n.createGroupAction,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, 'group'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'friend') {
      await _openAddFriend();
    } else if (action == 'group') {
      final groupId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CreateGroupScreen(
            contacts: widget.dependencies.contacts,
            groups: widget.dependencies.groups,
          ),
        ),
      );
      if (!mounted) return;
      if (groupId != null) {
        setState(() => _selectedTab = 1);
        await _inbox.refresh(showLoading: false);
      }
    }
  }

  Future<void> _openConversation(
    String peerId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    final conversation = _inbox.conversationById(peerId);
    final contact = _contacts.profileById(peerId);
    _inbox
      ..markReadLocally(peerId)
      ..setActiveConversation(peerId);
    try {
      await context.push<void>(
        '/chats/${Uri.encodeComponent(peerId)}',
        extra: ConversationRouteArgs(
          title: conversation?.name ?? contact?.displayName,
          avatarUrl: conversation?.avatarUrl ?? contact?.effectiveAvatarUrl,
          kind: kind,
        ),
      );
    } finally {
      _inbox.setActiveConversation(null);
    }
    if (mounted) await _inbox.refresh(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isExpanded(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightStatus,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: wide
            ? Row(
                children: [
                  ListenableBuilder(
                    listenable: Listenable.merge([_inbox, _contacts]),
                    builder: (context, _) => SafeArea(
                      right: false,
                      bottom: false,
                      child: AppNavigationRail(
                        index: _selectedTab,
                        onChanged: (index) =>
                            setState(() => _selectedTab = index),
                        chatsBadgeCount: _inbox.directUnreadCount,
                        groupsBadgeCount: _inbox.groupUnreadCount,
                        moreBadgeCount: _contacts.pendingFriendRequests.length,
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _shellBody()),
                ],
              )
            : _shellBody(),
        bottomNavigationBar: wide
            ? null
            : ListenableBuilder(
                listenable: Listenable.merge([_inbox, _contacts]),
                builder: (context, _) => AppBottomNav(
                  index: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                  chatsBadgeCount: _inbox.directUnreadCount,
                  groupsBadgeCount: _inbox.groupUnreadCount,
                  moreBadgeCount: _contacts.pendingFriendRequests.length,
                ),
              ),
      ),
    );
  }

  Widget _shellBody() => ListenableBuilder(
    listenable: Listenable.merge([_inbox, _contacts, _profile]),
    builder: (context, _) => Column(
      children: [
        if (_selectedTab < 2) _header(),
        Expanded(child: _selectedTabContent()),
      ],
    ),
  );

  Widget _selectedTabContent() => switch (_selectedTab) {
    0 => InboxScreen(
      viewModel: _inbox,
      kind: ChatConversationKind.direct,
      onOpenConversation: (conversation) =>
          _openConversation(conversation.id, kind: conversation.kind),
      onAdd: _openAddMenu,
    ),
    1 => InboxScreen(
      viewModel: _inbox,
      kind: ChatConversationKind.group,
      onOpenConversation: (conversation) =>
          _openConversation(conversation.id, kind: conversation.kind),
      onAdd: _openAddMenu,
    ),
    2 => ProfileScreen(viewModel: _profile, onLogout: _logout),
    _ => MoreScreen(
      userId: widget.currentUserId,
      displayName: _profile.profile?.displayName,
      onLogout: _logout,
      onFriendRequests: _openFriendRequests,
      onContacts: _openContacts,
      friendRequestCount: _contacts.pendingFriendRequests.length,
    ),
  };

  Widget _header() => GradientHeader(
    title: _selectedTab == 0 ? 'E-Chat' : context.l10n.groupsTitle,
    leading: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forum_rounded, color: Colors.white, size: 25),
        SizedBox(width: 8),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: _inbox.isConnected
              ? context.l10n.connected
              : context.l10n.disconnected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.circle,
              color: _inbox.isConnected
                  ? const Color(0xFF35C785)
                  : const Color(0xFFFF7268),
              size: 9,
            ),
          ),
        ),
        IconButton(
          tooltip: context.l10n.searchOrAddFriend,
          onPressed: _openAddFriend,
          color: Colors.white,
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: context.l10n.addFriendOrGroup,
          onPressed: _openAddMenu,
          color: Colors.white,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}
