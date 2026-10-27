import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/group_repository.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

class CreateGroupViewModel extends ViewModel {
  CreateGroupViewModel(this._contacts, this._groups);

  final ContactRepository _contacts;
  final GroupRepository _groups;
  List<UserProfile> _contactProfiles = const [];
  List<UserProfile> get contacts => _contactProfiles;
  final Set<String> _selected = {};
  Set<String> get selected => Set.unmodifiable(_selected);
  bool _isLoadingContacts = false;
  bool get isLoadingContacts => _isLoadingContacts;
  bool _isCreating = false;
  bool get isCreating => _isCreating;
  AppError? _error;
  AppError? get error => _error;

  Future<void> loadContacts() async {
    _isLoadingContacts = true;
    _error = null;
    notifyListeners();
    try {
      _contactProfiles = await _contacts.loadContacts();
    } catch (error) {
      _error = AppError.from(error);
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  UserProfile? contactById(String userId) {
    for (final contact in _contactProfiles) {
      if (contact.userId == userId) return contact;
    }
    return null;
  }

  void toggle(String userId) {
    if (!_selected.add(userId)) _selected.remove(userId);
    notifyListeners();
  }

  Future<String?> create(String name) async {
    final groupName = name.trim();
    if (groupName.isEmpty) {
      _error = const AppError(AppErrorCode.groupNameRequired);
      notifyListeners();
      return null;
    }
    if (_selected.isEmpty) {
      _error = const AppError(AppErrorCode.groupMembersRequired);
      notifyListeners();
      return null;
    }
    _isCreating = true;
    _error = null;
    notifyListeners();
    try {
      return await _groups.createGroup(
        name: groupName,
        memberIds: _selected.toList(growable: false),
      );
    } catch (error) {
      _error = AppError.from(error);
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
}
