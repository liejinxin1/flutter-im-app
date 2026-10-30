import 'package:flutter/material.dart';

import '../../../../domain/models/user_profile.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final UserProfile profile;
  final Future<bool> Function(UserProfile profile) onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late int _gender;
  DateTime? _birthday;
  String _countryCode = '+44';
  bool _saving = false;
  String? _validationError;

  static const _countries = [('🇬🇧', '+44'), ('🇨🇳', '+86'), ('🇺🇸', '+1')];

  @override
  void initState() {
    super.initState();
    final phone = widget.profile.phone?.trim() ?? '';
    _countryCode = _countries
        .map((entry) => entry.$2)
        .firstWhere(phone.startsWith, orElse: () => '+44');
    _nameController = TextEditingController(text: widget.profile.displayName);
    _phoneController = TextEditingController(
      text: _stripCode(phone, _countryCode),
    );
    _emailController = TextEditingController(text: widget.profile.email);
    _gender = widget.profile.gender;
    _birthday = _parseBirthday(widget.profile.birthday);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _validationError = context.l10n.nameRequired);
      return;
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _validationError = context.l10n.invalidEmail);
      return;
    }
    setState(() {
      _validationError = null;
      _saving = true;
    });
    final updated = widget.profile.copyWith(
      nickname: name,
      phone: '$_countryCode ${_phoneController.text.trim()}'.trim(),
      email: email,
      gender: _gender,
      birthday: _birthday == null ? null : _formatStorageDate(_birthday!),
    );
    final success = await widget.onSave(updated);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _validationError = context.l10n.errorUnknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DAE1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.editProfile,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _FieldLabel(context.l10n.name),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 14),
            _FieldLabel(context.l10n.phoneNumber),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    initialValue: _countryCode,
                    isExpanded: true,
                    items: [
                      for (final country in _countries)
                        DropdownMenuItem(
                          value: country.$2,
                          child: Text(
                            '${country.$1} ${country.$2}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _countryCode = value ?? '+44'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: '20 1234 5689'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FieldLabel(context.l10n.gender),
            DropdownButtonFormField<int>(
              initialValue: _gender,
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(context.l10n.notSpecified),
                ),
                DropdownMenuItem(value: 1, child: Text(context.l10n.male)),
                DropdownMenuItem(value: 2, child: Text(context.l10n.female)),
              ],
              onChanged: (value) => setState(() => _gender = value ?? 0),
            ),
            const SizedBox(height: 14),
            _FieldLabel(context.l10n.birthday),
            InkWell(
              onTap: _pickBirthday,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                child: Text(
                  _birthday == null
                      ? context.l10n.notSpecified
                      : _displayDate(_birthday!),
                  style: TextStyle(
                    color: _birthday == null
                        ? AppColors.mutedText
                        : const Color(0xFF252936),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FieldLabel(context.l10n.email),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                hintText: 'john.lennon@mail.com',
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 10),
              Text(
                _validationError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE9F8FF),
                      foregroundColor: AppColors.brandBlueLight,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandBlueLight,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
    ),
  );
}

DateTime? _parseBirthday(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
  if (iso != null) {
    return DateTime(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }
  final display = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
  if (display != null) {
    return DateTime(
      int.parse(display.group(3)!),
      int.parse(display.group(2)!),
      int.parse(display.group(1)!),
    );
  }
  return null;
}

String _displayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _stripCode(String phone, String code) {
  final value = phone.trim();
  if (!value.startsWith(code)) return value;
  return value.substring(code.length).trim();
}

String _formatStorageDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
