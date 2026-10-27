import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../domain/services/message_transport.dart';
import '../ui/core/system_ui/app_system_ui.dart';
import '../ui/core/theme/app_theme.dart';
import '../ui/features/auth/view_models/auth_view_model.dart';
import 'app_dependencies.dart';
import 'router/app_router.dart';

class AgoraImApp extends StatefulWidget {
  const AgoraImApp({super.key, this.dependencies, this.attachmentUploader});

  final AppDependencies? dependencies;
  final AttachmentUploader? attachmentUploader;

  @override
  State<AgoraImApp> createState() => _AgoraImAppState();
}

class _AgoraImAppState extends State<AgoraImApp> {
  late final AppDependencies _dependencies;
  late final AuthViewModel _authViewModel;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _dependencies =
        widget.dependencies ??
        AppDependencies.create(attachmentUploader: widget.attachmentUploader);
    _authViewModel = AuthViewModel(_dependencies.session);
    _appRouter = AppRouter(dependencies: _dependencies, auth: _authViewModel);
    unawaited(_authViewModel.restoreSession());
  }

  @override
  void dispose() {
    _appRouter.dispose();
    _authViewModel.dispose();
    if (widget.dependencies == null) unawaited(_dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    routerConfig: _appRouter.router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkStatus,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
