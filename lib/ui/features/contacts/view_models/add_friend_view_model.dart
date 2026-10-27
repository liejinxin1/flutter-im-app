import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

class AddFriendViewModel extends ViewModel {
  AddFriendViewModel(this._contacts, this._profiles);

  final ContactRepository _contacts;
  final ProfileRepository _profiles;
  UserProfile? _candidate;
  UserProfile? get candidate => _candidate;
  AppError? _error;
  AppError? get error => _error;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _added = false;
  bool get added => _added;

  Future<void> search(String userId) async {
    final id = userId.trim();
    _candidate = null;
    _added = false;
    if (id.isEmpty) {
      _error = const AppError(AppErrorCode.addFriendIdRequired);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _contacts.addContact(id);
      _candidate = await _profiles.load(id);
      _added = true;
    } catch (error) {
      _error = AppError.from(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
