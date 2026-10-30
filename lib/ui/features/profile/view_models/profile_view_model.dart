import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

class ProfileViewModel extends ViewModel {
  ProfileViewModel(this._profiles, this.userId);

  final ProfileRepository _profiles;
  final String userId;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isSaving = false;
  bool get isSaving => _isSaving;
  AppError? _error;
  AppError? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _profiles.load(userId, forceRefresh: true);
      if (isDisposed) return;
      _profile = profile;
    } catch (_) {
      // Keep the userId fallback rendered by the view.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(UserProfile updated) async {
    if (_isSaving) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _profiles.updateOwnProfile(updated);
      if (isDisposed) return false;
      _profile = updated;
      return true;
    } catch (error) {
      if (!isDisposed) {
        _error = AppError.from(error);
      }
      return false;
    } finally {
      _isSaving = false;
      if (!isDisposed) notifyListeners();
    }
  }
}
