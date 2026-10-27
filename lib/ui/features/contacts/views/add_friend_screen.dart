import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';
import '../view_models/add_friend_view_model.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({
    super.key,
    required this.contacts,
    required this.profiles,
  });

  final ContactRepository contacts;
  final ProfileRepository profiles;

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  late final AddFriendViewModel _viewModel;
  final _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AddFriendViewModel(widget.contacts, widget.profiles);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppSystemUi.lightStatus,
    child: Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const SystemNavBarInset(),
      body: Column(
        children: [
          GradientHeader(
            title: context.l10n.addFriendTitle,
            leading: _BackButton(onTap: () => Navigator.pop(context)),
          ),
          Expanded(
            child: AppContentFrame(
              maxWidth: 760,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => _content(context),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      children: [
        Text(
          l10n.findPeople,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF252936),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l10n.addFriendDescription,
          style: const TextStyle(color: Color(0xFF9699A5), fontSize: 13),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _userIdController,
          textInputAction: TextInputAction.search,
          onSubmitted: _viewModel.search,
          decoration: InputDecoration(
            hintText: l10n.userIdHint,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.brandBlueLight,
            ),
            suffixIcon: IconButton(
              tooltip: l10n.sendFriendRequest,
              onPressed: () => _viewModel.search(_userIdController.text),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.brandBlueLight,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 17),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE6EDF2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE6EDF2)),
            ),
          ),
        ),
        if (_viewModel.error case final error?) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: localizedError(l10n, error)),
        ],
        if (_viewModel.isLoading) ...[
          const SizedBox(height: 30),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_viewModel.candidate case final profile?) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE9EEF2)),
            ),
            child: Row(
              children: [
                UserAvatar(
                  userId: profile.userId,
                  radius: 24,
                  foregroundImage: profile.effectiveAvatarUrl == null
                      ? null
                      : NetworkImage(profile.effectiveAvatarUrl!),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.displayName == profile.userId
                            ? l10n.agoraChatUser
                            : profile.userId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999CA8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF35B883),
                ),
              ],
            ),
          ),
          if (_viewModel.added)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.friendRequestSent(profile.displayName),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF35A97D)),
              ),
            ),
        ] else if (!_viewModel.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 94),
            child: Column(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 108,
                  color: AppColors.brandBlueLight.withValues(alpha: .19),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.searchForFriend,
                  style: const TextStyle(color: Color(0xFFAFB6C0)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: .18),
    ),
    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 21),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: const TextStyle(color: Color(0xFFB5443D), height: 1.4),
  );
}
