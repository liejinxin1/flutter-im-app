import 'dart:async';

import '../../../../domain/models/friend_request_update.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/friend_request_store.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

/// Contacts, live friend requests, and persisted pending requests.
///
/// The SDK has no "list pending friend requests" API, so received invitations
/// are restored from [FriendRequestStore] on construction.
class ContactsViewModel extends ViewModel {
  ContactsViewModel(
    this._contacts,
    this._profiles,
    this._store,
    this._currentUserId,
  ) {
    _friendRequestsSubscription = _contacts.friendRequestUpdates.listen(
      _onFriendRequestUpdate,
    );
    unawaited(_restoreRequests());
  }

  final ContactRepository _contacts;
  final ProfileRepository _profiles;
  final FriendRequestStore _store;
  final String _currentUserId;
  late final StreamSubscription<FriendRequestUpdate>
  _friendRequestsSubscription;

  List<UserProfile> _items = const [];
  List<UserProfile> get items => _items;

  UserProfile? profileById(String userId) {
    for (final profile in _items) {
      if (profile.userId == userId) return profile;
    }
    return null;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  AppError? _error;
  AppError? get error => _error;
  final Map<String, FriendRequestUpdate> _pendingFriendRequests = {};
  List<FriendRequestUpdate> get pendingFriendRequests =>
      _pendingFriendRequests.values.toList(growable: false);
  FriendRequestUpdate? _requestToast;
  FriendRequestUpdate? get requestToast => _requestToast;

  void consumeRequestToast() {
    _requestToast = null;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final contacts = await _contacts.loadContacts();
      if (isDisposed) return;
      final profiles = await _profiles.loadAll(
        contacts.map((contact) => contact.userId),
      );
      if (isDisposed) return;
      _items = contacts
          .map((contact) {
            final profile = profiles[contact.userId];
            return UserProfile(
              userId: contact.userId,
              nickname: profile?.nickname,
              avatarUrl: profile?.effectiveAvatarUrl,
              remark: contact.remark,
            );
          })
          .toList(growable: false);
    } catch (error) {
      _error = AppError.from(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> respondToFriendRequest(
    String userId, {
    required bool accept,
  }) async {
    try {
      if (accept) {
        await _contacts.acceptContactRequest(userId);
      } else {
        await _contacts.declineContactRequest(userId);
      }
      _pendingFriendRequests.remove(userId);
      _persistRequests();
      notifyListeners();
      return true;
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> _restoreRequests() async {
    try {
      final stored = await _store.load(_currentUserId);
      if (isDisposed) return;
      for (final request in stored) {
        if (request.type == FriendRequestUpdateType.received) {
          _pendingFriendRequests[request.userId] = request;
        }
      }
      if (_pendingFriendRequests.isNotEmpty) notifyListeners();
    } catch (_) {
      // Corruption or unavailable storage should not block contacts.
    }
  }

  void _persistRequests() {
    unawaited(
      _store.save(
        _currentUserId,
        _pendingFriendRequests.values.toList(growable: false),
      ),
    );
  }

  void _onFriendRequestUpdate(FriendRequestUpdate update) {
    switch (update.type) {
      case FriendRequestUpdateType.received:
        _pendingFriendRequests[update.userId] = update;
      case FriendRequestUpdateType.accepted:
      case FriendRequestUpdateType.declined:
      case FriendRequestUpdateType.contactAdded:
        _pendingFriendRequests.remove(update.userId);
    }
    _persistRequests();
    _requestToast = update;
    notifyListeners();
  }

  @override
  void dispose() {
    _friendRequestsSubscription.cancel();
    super.dispose();
  }
}
