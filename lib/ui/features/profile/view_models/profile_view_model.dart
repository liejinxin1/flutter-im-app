import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/view_model.dart';

class ProfileViewModel extends ViewModel {
  ProfileViewModel(this._profiles, this.userId);

  final ProfileRepository _profiles;
  final String userId;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final profile = await _profiles.load(userId);
      if (isDisposed) return;
      _profile = profile;
    } catch (_) {
      // Keep the userId fallback rendered by the view.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
