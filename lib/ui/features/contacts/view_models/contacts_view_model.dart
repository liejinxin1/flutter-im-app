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
  final Map<String, FriendRequestUpdate> _requestHistory = {};
  List<FriendRequestUpdate> get requestHistory =>
      _sortedRequests(_requestHistory.values);
  List<FriendRequestUpdate> get pendingFriendRequests => _sortedRequests(
    _requestHistory.values.where(
      (request) => request.type == FriendRequestUpdateType.received,
    ),
  );
  FriendRequestUpdate? _requestToast;
  FriendRequestUpdate? get requestToast => _requestToast;

  List<FriendRequestUpdate> _sortedRequests(
    Iterable<FriendRequestUpdate> requests,
  ) {
    final result = requests.toList(growable: false);
    result.sort(
      (a, b) =>
          (b.occurredAt ?? DateTime(0)).compareTo(a.occurredAt ?? DateTime(0)),
    );
    return result;
  }

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
    var request = _requestHistory['contact:$userId'];
    if (request == null) {
      for (final item in pendingFriendRequests) {
        if (item.userId == userId && !item.isGroup) {
          request = item;
          break;
        }
      }
    }
    if (request == null) return false;
    return respondToRequest(request, accept: accept);
  }

  Future<bool> respondToRequest(
    FriendRequestUpdate request, {
    required bool accept,
  }) async {
    try {
      if (request.isGroup) {
        final groupId = request.groupId;
        final inviter = request.inviter ?? request.userId;
        if (groupId == null ||
            groupId.isEmpty ||
            inviter.isEmpty ||
            request.type != FriendRequestUpdateType.received) {
          return false;
        }
        if (accept) {
          await _contacts.acceptGroupInvitation(groupId, inviter);
        } else {
          await _contacts.declineGroupInvitation(groupId, inviter);
        }
      } else {
        if (request.type != FriendRequestUpdateType.received) return false;
        if (accept) {
          await _contacts.acceptContactRequest(request.userId);
        } else {
          await _contacts.declineContactRequest(request.userId);
        }
      }
      _recordRequest(
        request.copyWith(
          type: accept
              ? FriendRequestUpdateType.accepted
              : FriendRequestUpdateType.declined,
          occurredAt: DateTime.now(),
        ),
      );
      _persistRequests();
      notifyListeners();
      return true;
    } catch (error) {
      _error = AppError.from(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRemark(String userId, String remark) async {
    try {
      await _contacts.updateRemark(userId, remark);
      await _profiles.updateRemark(userId, remark);
      _items = _items
          .map(
            (profile) => profile.userId == userId
                ? profile.copyWith(remark: remark)
                : profile,
          )
          .toList(growable: false);
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
        _recordRequest(request);
      }
      if (_requestHistory.isNotEmpty) notifyListeners();
    } catch (_) {
      // Corruption or unavailable storage should not block contacts.
    }
  }

  void _persistRequests() {
    unawaited(
      _store.save(
        _currentUserId,
        _requestHistory.values.toList(growable: false),
      ),
    );
  }

  void _recordRequest(FriendRequestUpdate update) {
    if (update.targetId.isEmpty) return;
    final previous = _requestHistory[update.targetKey];
    if (previous?.occurredAt != null &&
        update.occurredAt != null &&
        update.occurredAt!.isBefore(previous!.occurredAt!)) {
      return;
    }
    _requestHistory[update.targetKey] = update;
  }

  void _onFriendRequestUpdate(FriendRequestUpdate update) {
    _recordRequest(update);
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
