import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/group_repository.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';
import '../view_models/create_group_view_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.contacts,
    required this.groups,
  });

  final ContactRepository contacts;
  final GroupRepository groups;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  late final CreateGroupViewModel _viewModel;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CreateGroupViewModel(widget.contacts, widget.groups)
      ..loadContacts();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _chooseMembers() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => _MemberPicker(viewModel: _viewModel),
    );
  }

  Future<void> _create() async {
    final groupId = await _viewModel.create(_nameController.text);
    if (!mounted || groupId == null) return;
    Navigator.pop(context, groupId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightStatus,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        bottomNavigationBar: const SystemNavBarInset(),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Column(
            children: [
              GradientHeader(
                title: l10n.createGroupTitle,
                leading: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .18),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
              Expanded(
                child: AppContentFrame(
                  maxWidth: 760,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                    children: [
                      Text(
                        l10n.groupName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF898E9B),
                        ),
                      ),
                      const SizedBox(height: 9),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: l10n.groupNameHint,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: Color(0xFFE6EDF2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: Color(0xFFE6EDF2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.members,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF898E9B),
                              ),
                            ),
                          ),
                          Text(
                            l10n.selectedCount(_viewModel.selected.length),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9399A4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: _chooseMembers,
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8FD),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: AppColors.brandBlueLight,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _viewModel.selected.isEmpty
                                      ? l10n.addMembersToGroup
                                      : l10n.editSelectedMembers,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.brandBlueLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.brandBlueLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_viewModel.selected.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _viewModel.selected
                              .map((id) {
                                final profile = _viewModel.contactById(id);
                                return Chip(
                                  avatar: UserAvatar(userId: id, radius: 12),
                                  label: Text(profile?.displayName ?? id),
                                  onDeleted: () => _viewModel.toggle(id),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFE6EDF2),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ],
                      if (_viewModel.error case final error?) ...[
                        const SizedBox(height: 18),
                        Text(
                          localizedError(l10n, error),
                          style: const TextStyle(color: Color(0xFFB5443D)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _viewModel.isCreating ? null : _create,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandBlueLight,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: _viewModel.isCreating
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.createGroupButton,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberPicker extends StatefulWidget {
  const _MemberPicker({required this.viewModel});
  final CreateGroupViewModel viewModel;

  @override
  State<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<_MemberPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final contacts = widget.viewModel.contacts
        .where(
          (profile) =>
              profile.displayName.toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              profile.userId.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) => Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDE3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                child: Text(
                  l10n.addMembersTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.searchContacts,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: widget.viewModel.isLoadingContacts
                    ? const Center(child: CircularProgressIndicator())
                    : contacts.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noContactsAddFriend,
                          style: const TextStyle(color: Color(0xFF9399A4)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final profile = contacts[index];
                          final selected = widget.viewModel.selected.contains(
                            profile.userId,
                          );
                          final avatarUrl = profile.effectiveAvatarUrl;
                          return CheckboxListTile(
                            value: selected,
                            activeColor: AppColors.brandBlueLight,
                            onChanged: (_) =>
                                widget.viewModel.toggle(profile.userId),
                            secondary: UserAvatar(
                              userId: profile.userId,
                              radius: 20,
                              foregroundImage: avatarUrl == null
                                  ? null
                                  : NetworkImage(avatarUrl),
                            ),
                            title: Text(
                              profile.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: profile.displayName == profile.userId
                                ? null
                                : Text(profile.userId),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.done),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
