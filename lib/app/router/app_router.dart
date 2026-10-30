import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/chat_conversation.dart';
import '../../ui/features/auth/view_models/auth_view_model.dart';
import '../../ui/features/auth/views/auth_screen.dart';
import '../../ui/features/contacts/views/friend_detail_screen.dart';
import '../../ui/features/conversation/views/conversation_screen.dart';
import '../../ui/features/groups/views/group_detail_screen.dart';
import '../../ui/features/shell/views/app_shell.dart';
import '../app_dependencies.dart';
import '../navigation/app_navigation.dart';

/// Extra data carried when navigating from the inbox/contacts to a chat.
///
/// Deep links deliberately omit it, so the conversation falls back to the ID.
class ConversationRouteArgs {
  const ConversationRouteArgs({
    this.title,
    this.avatarUrl,
    this.kind = ChatConversationKind.direct,
    this.memberCount,
  });

  final String? title;
  final String? avatarUrl;
  final ChatConversationKind kind;
  final int? memberCount;
}

class AppRouter {
  AppRouter({
    required AppDependencies dependencies,
    required AuthViewModel auth,
  }) {
    _router = GoRouter(
      navigatorKey: appRootNavigatorKey,
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;
        if (auth.isRestoring) {
          return location == '/splash' ? null : '/splash';
        }
        if (!auth.isLoggedIn) {
          return location == '/login' ? null : '/login';
        }
        if (location == '/login' || location == '/splash') return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => AuthScreen(viewModel: auth),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) {
            final userId = auth.userId;
            if (userId == null) return const _SplashScreen();
            return AppShell(
              dependencies: dependencies,
              authViewModel: auth,
              currentUserId: userId,
            );
          },
        ),
        GoRoute(
          path: '/groups/:groupId',
          builder: (context, state) {
            final groupId = Uri.decodeComponent(
              state.pathParameters['groupId'] ?? '',
            );
            final members = int.tryParse(
              state.uri.queryParameters['members'] ?? '',
            );
            return GroupDetailScreen(
              groupId: groupId,
              groupName: state.uri.queryParameters['name'],
              memberCount: members,
              currentUserId: state.uri.queryParameters['me'],
              groups: dependencies.groups,
              onOpenMember: (userId) =>
                  context.push<void>('/friends/${Uri.encodeComponent(userId)}'),
            );
          },
        ),
        GoRoute(
          path: '/friends/:userId',
          builder: (context, state) {
            final userId = Uri.decodeComponent(
              state.pathParameters['userId'] ?? '',
            );
            return FriendDetailScreen(
              userId: userId,
              profiles: dependencies.profiles,
              contacts: dependencies.contacts,
              onOpenChat: (peerId) => context.push<void>(
                '/chats/${Uri.encodeComponent(peerId)}',
                extra: const ConversationRouteArgs(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/chats/:conversationId',
          builder: (context, state) {
            final userId = auth.userId;
            if (userId == null) return const _SplashScreen();
            final peerId = Uri.decodeComponent(
              state.pathParameters['conversationId'] ?? '',
            );
            final extra = state.extra;
            final args = extra is ConversationRouteArgs
                ? extra
                : ConversationRouteArgs(
                    kind: state.uri.queryParameters['kind'] == 'group'
                        ? ChatConversationKind.group
                        : ChatConversationKind.direct,
                  );
            return ConversationScreen(
              repository: dependencies.chat,
              media: dependencies.media,
              outbox: dependencies.outbox,
              currentUserId: userId,
              peerId: peerId,
              settings: dependencies.settings,
              profiles: dependencies.profiles,
              kind: args.kind,
              memberCount: args.memberCount,
              peerName: args.title,
              peerAvatarUrl: args.avatarUrl,
            );
          },
        ),
      ],
    );
  }

  late final GoRouter _router;

  GoRouter get router => _router;

  void dispose() => _router.dispose();
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
