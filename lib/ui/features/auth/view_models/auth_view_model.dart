import 'dart:async';

import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

import '../../../../domain/errors/app_failure.dart';
import '../../../../domain/repositories/session_repository.dart';

class AuthViewModel extends ViewModel {
  AuthViewModel(this._session) {
    _sessionSubscription = _session.sessionInvalidated.listen((_) {
      _sessionVersion++;
      _userId = null;
      _error = const AppError(AppErrorCode.sessionExpired);
      notifyListeners();
    });
  }

  final SessionRepository _session;
  late final StreamSubscription<void> _sessionSubscription;
  int _sessionVersion = 0;

  String? _userId;
  String? get userId => _userId;
  AppError? _error;
  AppError? get error => _error;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isRestoring = true;
  bool get isRestoring => _isRestoring;
  bool get isLoggedIn => _userId != null;

  Future<void> restoreSession() async {
    final version = ++_sessionVersion;
    try {
      final userId = await _session.restoreSession();
      if (!isDisposed && version == _sessionVersion) _userId = userId;
    } catch (error) {
      if (!isDisposed && version == _sessionVersion) {
        _error = AppError.from(error);
        _userId = null;
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String userId,
    required String credential,
    required bool usePassword,
  }) async {
    if (isDisposed || _isLoading) return false;
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || credential.isEmpty) {
      _error = AppError(
        usePassword
            ? AppErrorCode.missingPasswordCredentials
            : AppErrorCode.missingTokenCredentials,
      );
      notifyListeners();
      return false;
    }

    _isLoading = true;
    final version = ++_sessionVersion;
    _error = null;
    notifyListeners();
    try {
      await _session.login(
        userId: normalizedUserId,
        credential: credential,
        usePassword: usePassword,
      );
      if (isDisposed || version != _sessionVersion) return false;
      _userId = normalizedUserId;
      return true;
    } catch (error) {
      if (version == _sessionVersion) _error = AppError.from(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _sessionVersion++;
    try {
      await _session.logout();
      _userId = null;
      _error = null;
    } catch (error) {
      _error = AppError(
        AppErrorCode.logoutFailed,
        detail: friendlyError(error),
      );
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }
}
