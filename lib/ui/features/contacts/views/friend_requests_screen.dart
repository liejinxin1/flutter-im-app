import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/friend_request_update.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({
    super.key,
    required this.requests,
    required this.onRespond,
  });

  final List<FriendRequestUpdate> requests;
  final Future<bool> Function(String userId, {required bool accept}) onRespond;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppSystemUi.lightStatus,
    child: Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const SystemNavBarInset(),
      body: Column(
        children: [
          GradientHeader(
            title: context.l10n.friendRequestsTitle,
            leading: IconButton.filledTonal(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .18),
              ),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: AppContentFrame(
              maxWidth: 760,
              child: requests.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.noPendingFriendRequests,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _RequestTile(
                        request: requests[index],
                        onRespond: onRespond,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RequestTile extends StatefulWidget {
  const _RequestTile({required this.request, required this.onRespond});

  final FriendRequestUpdate request;
  final Future<bool> Function(String userId, {required bool accept}) onRespond;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    final success = await widget.onRespond(
      widget.request.userId,
      accept: accept,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.requestUpdateFailed)));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        UserAvatar(userId: widget.request.userId, radius: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.request.userId,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (widget.request.reason?.isNotEmpty == true)
                Text(
                  widget.request.reason!,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (_busy)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else ...[
          IconButton(
            tooltip: context.l10n.decline,
            onPressed: () => _respond(false),
            icon: const Icon(Icons.close_rounded, color: Color(0xFFD56969)),
          ),
          IconButton(
            tooltip: context.l10n.accept,
            onPressed: () => _respond(true),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF35B883),
            ),
          ),
        ],
      ],
    ),
  );
}
