import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/auth_view_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final TextEditingController _userController;
  late final TextEditingController _credentialController;
  bool _usePassword = const String.fromEnvironment('AGORA_TOKEN').isEmpty;
  bool _obscureCredential = true;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(
      text: const String.fromEnvironment('AGORA_USER_ID'),
    );
    _credentialController = TextEditingController(
      text: _usePassword
          ? const String.fromEnvironment('AGORA_PASSWORD')
          : const String.fromEnvironment('AGORA_TOKEN'),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await widget.viewModel.login(
      userId: _userController.text,
      credential: _credentialController.text,
      usePassword: _usePassword,
    );
  }

  void _setCredentialMode(bool usePassword) {
    setState(() {
      _usePassword = usePassword;
      _credentialController.clear();
      _obscureCredential = usePassword;
    });
    widget.viewModel.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkStatus,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        bottomNavigationBar: const SystemNavBarInset(),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14192E45),
                          blurRadius: 28,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.brandBlueLight,
                                  AppColors.brandBlue,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            l10n.loginTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.brandBlue,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF838A96)),
                          ),
                          const SizedBox(height: 28),
                          _input(
                            controller: _userController,
                            label: l10n.userIdLabel,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: true,
                                label: Text(l10n.passwordLogin),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text(l10n.tokenLogin),
                              ),
                            ],
                            selected: {_usePassword},
                            onSelectionChanged: (selection) =>
                                _setCredentialMode(selection.first),
                          ),
                          const SizedBox(height: 16),
                          _input(
                            controller: _credentialController,
                            label: _usePassword
                                ? l10n.passwordLabel
                                : l10n.tokenLabel,
                            icon: _usePassword
                                ? Icons.lock_outline_rounded
                                : Icons.key_rounded,
                            obscure: _obscureCredential,
                            suffix: IconButton(
                              tooltip: _obscureCredential
                                  ? l10n.showPassword
                                  : l10n.hidePassword,
                              onPressed: () => setState(
                                () => _obscureCredential = !_obscureCredential,
                              ),
                              icon: Icon(
                                _obscureCredential
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          if (widget.viewModel.error case final error?) ...[
                            const SizedBox(height: 14),
                            Text(
                              localizedError(l10n, error),
                              style: const TextStyle(color: Color(0xFFB5443D)),
                            ),
                          ],
                          if (kIsWeb) ...[
                            const SizedBox(height: 14),
                            Text(
                              l10n.webPreviewNote,
                              style: const TextStyle(
                                color: Color(0xFF838A96),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: widget.viewModel.isLoading
                                ? null
                                : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandBlueLight,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: widget.viewModel.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.loginButton),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _usePassword ? l10n.passwordHint : l10n.tokenHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF9297A3),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(color: Color(0xFF282C36)),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF838A96)),
      prefixIcon: Icon(icon, color: AppColors.brandBlueLight),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE6EDF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.send),
      ),
    ),
    onChanged: (_) => widget.viewModel.clearError(),
  );
}
