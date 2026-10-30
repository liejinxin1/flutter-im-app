import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/user_profile.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/edit_profile_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.viewModel,
    required this.onLogout,
  });

  final ProfileViewModel viewModel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: Column(
      children: [
        GradientHeader(title: context.l10n.profileTitle),
        Expanded(
          child: AppContentFrame(
            maxWidth: 760,
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                final profile = viewModel.profile;
                final displayName = profile?.displayName ?? viewModel.userId;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                  children: [
                    Center(
                      child: _AvatarEditor(
                        userId: viewModel.userId,
                        profile: profile,
                        onEdit: profile == null
                            ? null
                            : () => _editAvatar(context, profile),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF252936),
                      ),
                    ),
                    if (displayName != viewModel.userId) ...[
                      const SizedBox(height: 4),
                      Text(
                        viewModel.userId,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    _InfoRow(
                      label: context.l10n.phone,
                      value: profile?.phone,
                      onCopy: (value) => _copy(context, value),
                    ),
                    _InfoRow(
                      label: context.l10n.gender,
                      value: _genderLabel(context, profile?.gender ?? 0),
                      onCopy: (value) => _copy(context, value),
                    ),
                    _InfoRow(
                      label: context.l10n.birthday,
                      value: _displayBirthday(profile?.birthday),
                      onCopy: (value) => _copy(context, value),
                    ),
                    _InfoRow(
                      label: context.l10n.email,
                      value: profile?.email,
                      onCopy: (value) => _copy(context, value),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: profile == null
                          ? null
                          : () => _editProfile(context, profile),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.l10n.editProfile),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlueLight,
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(context.l10n.signOut),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFDEBEC),
                        foregroundColor: const Color(0xFFD95656),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    if (viewModel.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.errorUnknown,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _editProfile(BuildContext context, UserProfile profile) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) =>
          EditProfileSheet(profile: profile, onSave: viewModel.save),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.profileUpdated)));
  }

  Future<void> _editAvatar(BuildContext context, UserProfile profile) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _AvatarUrlDialog(initialValue: profile.avatarUrl),
    );
    if (!context.mounted || value == null || value.isEmpty) return;
    final success = await viewModel.save(profile.copyWith(avatarUrl: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? context.l10n.profileUpdated : context.l10n.errorUnknown,
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  String _genderLabel(BuildContext context, int gender) => switch (gender) {
    1 => context.l10n.male,
    2 => context.l10n.female,
    _ => context.l10n.notSpecified,
  };
}

class _AvatarUrlDialog extends StatefulWidget {
  const _AvatarUrlDialog({this.initialValue});

  final String? initialValue;

  @override
  State<_AvatarUrlDialog> createState() => _AvatarUrlDialogState();
}

class _AvatarUrlDialogState extends State<_AvatarUrlDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.avatarUrl),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(hintText: 'https://...'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(context.l10n.save),
      ),
    ],
  );
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.userId,
    required this.profile,
    required this.onEdit,
  });

  final String userId;
  final UserProfile? profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      UserAvatar(
        userId: userId,
        radius: 68,
        foregroundImage: profile?.effectiveAvatarUrl == null
            ? null
            : NetworkImage(profile!.effectiveAvatarUrl!),
      ),
      Positioned(
        right: -2,
        bottom: 4,
        child: Material(
          color: AppColors.brandBlueLight,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onEdit,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(9),
              child: Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onCopy});

  final String label;
  final String? value;
  final ValueChanged<String>? onCopy;

  @override
  Widget build(BuildContext context) {
    final shown = value?.trim();
    final display = shown == null || shown.isEmpty
        ? context.l10n.notSpecified
        : shown;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: shown == null || shown.isEmpty
                    ? AppColors.hint
                    : const Color(0xFF303440),
                fontSize: 16,
              ),
            ),
          ),
          if (onCopy != null && shown != null && shown.isNotEmpty)
            IconButton(
              tooltip: context.l10n.copy,
              onPressed: () => onCopy!(shown),
              icon: const Icon(
                Icons.content_copy_rounded,
                size: 19,
                color: Color(0xFF303440),
              ),
            ),
        ],
      ),
    );
  }
}

String? _displayBirthday(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(raw.trim());
  if (iso != null) {
    return '${iso.group(3)!.padLeft(2, '0')}/'
        '${iso.group(2)!.padLeft(2, '0')}/${iso.group(1)}';
  }
  return raw;
}
