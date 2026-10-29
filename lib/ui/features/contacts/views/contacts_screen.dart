import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../../domain/models/user_profile.dart';
import '../view_models/contacts_view_model.dart';
import '../widgets/remark_dialog.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({
    super.key,
    required this.viewModel,
    required this.onOpenConversation,
    this.onOpenProfile,
  });

  final ContactsViewModel viewModel;
  final ValueChanged<String> onOpenConversation;
  final ValueChanged<String>? onOpenProfile;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppSystemUi.lightStatus,
    child: Scaffold(
      backgroundColor: AppColors.canvas,
      bottomNavigationBar: const SystemNavBarInset(),
      body: Column(
        children: [
          GradientHeader(
            title: context.l10n.contactsTitle,
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
              maxWidth: 820,
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  if (viewModel.isLoading && viewModel.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (viewModel.error != null && viewModel.items.isEmpty) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: viewModel.load,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.contactsLoadFailed),
                      ),
                    );
                  }
                  if (viewModel.items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: viewModel.load,
                      child: ListView(
                        children: [
                          const SizedBox(height: 200),
                          Center(
                            child: Text(
                              context.l10n.noContacts,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: viewModel.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: viewModel.items.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 78,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final profile = viewModel.items[index];
                        final avatarUrl = profile.effectiveAvatarUrl;
                        return ListTile(
                          onTap: () => onOpenConversation(profile.userId),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 6,
                          ),
                          leading: UserAvatar(
                            userId: profile.userId,
                            radius: 24,
                            foregroundImage: avatarUrl == null
                                ? null
                                : NetworkImage(avatarUrl),
                          ),
                          title: Text(profile.displayName),
                          subtitle: Text(
                            profile.displayName == profile.userId
                                ? context.l10n.agoraChatContact
                                : profile.userId,
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.mutedText,
                            ),
                            itemBuilder: (context) => [
                              if (onOpenProfile != null)
                                PopupMenuItem(
                                  value: 'profile',
                                  child: Text(context.l10n.friendProfile),
                                ),
                              PopupMenuItem(
                                value: 'chat',
                                child: Text(context.l10n.sendMessage),
                              ),
                              PopupMenuItem(
                                value: 'remark',
                                child: Text(context.l10n.editRemark),
                              ),
                            ],
                            onSelected: (action) {
                              if (action == 'profile') {
                                onOpenProfile?.call(profile.userId);
                              } else if (action == 'chat') {
                                onOpenConversation(profile.userId);
                              } else {
                                _editRemark(context, profile);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _editRemark(BuildContext context, UserProfile profile) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => RemarkDialog(initialRemark: profile.remark),
    );
    if (value == null || !context.mounted) return;

    final success = await viewModel.updateRemark(profile.userId, value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? context.l10n.remarkUpdated
                : context.l10n.requestUpdateFailed,
          ),
        ),
      );
  }
}
