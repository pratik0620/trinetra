import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection_request_model.dart';
import '../models/user_model.dart';
import '../services/connection_local_storage.dart';

class ConnectionRepository {
  final FirebaseFirestore _firestore;
  final ConnectionLocalStorage _localStorage;

  ConnectionRepository({
    FirebaseFirestore? firestore,
    ConnectionLocalStorage? localStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage ?? ConnectionLocalStorage();

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('connectionRequests');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _userConnections(String userId) =>
      _users.doc(userId).collection('connections');

  /// Sends a connection request from sender to receiver.
  /// Checks for existing pending requests first to prevent duplicates.
  Future<void> sendConnectionRequest({
    required UserModel sender,
    required UserModel receiver,
  }) async {
    final existingSnap = await _requests
        .where('senderId', isEqualTo: sender.uid)
        .where('receiverId', isEqualTo: receiver.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingSnap.docs.isNotEmpty) {
      throw 'A connection request is already pending for this contact.';
    }

    final reverseSnap = await _requests
        .where('senderId', isEqualTo: receiver.uid)
        .where('receiverId', isEqualTo: sender.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (reverseSnap.docs.isNotEmpty) {
      throw 'This contact has already sent you a connection request.';
    }

    final docRef = _requests.doc();
    final request = ConnectionRequestModel(
      id: docRef.id,
      senderId: sender.uid,
      senderPhone: sender.phone,
      senderName: sender.name,
      receiverId: receiver.uid,
      receiverPhone: receiver.phone,
      receiverName: receiver.name,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(request.toMap());
  }

  /// Streams incoming pending requests for a user in real-time.
  Stream<List<ConnectionRequestModel>> streamIncomingRequests(String receiverId) {
    return _requests
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ConnectionRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Resolves actual full name for a user from users/{uid} document.
  Future<String> _resolveUserFullName(String uid, String fallbackPhone) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final fName = data['firstName'] ?? '';
        final lName = data['lastName'] ?? '';
        final full = '$fName $lName'.trim();
        if (full.isNotEmpty) return full;
        final dName = data['displayName'] ?? data['name'];
        if (dName != null && dName.toString().trim().isNotEmpty) {
          return dName.toString().trim();
        }
      }
    } catch (_) {}
    return fallbackPhone;
  }

  /// Accepts a connection request:
  /// 1. Updates request status to 'accepted'
  /// 2. Bidirectionally updates emergency_contacts array using FieldValue.arrayUnion()
  /// 3. Resolves both users' real registered names from users/{uid}
  /// 4. Creates subcollection entries in users/{uid}/connections with real registered names
  /// 5. Updates local storage cache immediately
  Future<void> acceptRequest(ConnectionRequestModel request) async {
    final senderId = request.senderId;
    final receiverId = request.receiverId;

    // Resolve real registered names for both users from users/{uid}
    final senderRealName = await _resolveUserFullName(
      senderId,
      request.senderName.isNotEmpty ? request.senderName : request.senderPhone,
    );
    final receiverRealName = await _resolveUserFullName(
      receiverId,
      request.receiverName.isNotEmpty ? request.receiverName : request.receiverPhone,
    );

    // 1. Update connection request status to accepted
    await _requests.doc(request.id).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Atomically update emergency_contacts array on sender's user document
    await _users.doc(senderId).set({
      'emergency_contacts': FieldValue.arrayUnion([receiverId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Atomically update emergency_contacts array on receiver's user document
    await _users.doc(receiverId).set({
      'emergency_contacts': FieldValue.arrayUnion([senderId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 4. Create subcollection entry in sender's connections (points to Receiver B)
    final senderConnItem = UserConnectionItem(
      userId: receiverId,
      phoneNumber: request.receiverPhone,
      displayName: receiverRealName,
      createdAt: DateTime.now(),
    );

    await _userConnections(senderId)
        .doc(receiverId)
        .set(senderConnItem.toMap(), SetOptions(merge: true));

    // 5. Create subcollection entry in receiver's connections (points to Sender A)
    final receiverConnItem = UserConnectionItem(
      userId: senderId,
      phoneNumber: request.senderPhone,
      displayName: senderRealName,
      createdAt: DateTime.now(),
    );

    await _userConnections(receiverId)
        .doc(senderId)
        .set(receiverConnItem.toMap(), SetOptions(merge: true));

    // 6. Update local storage for receiver immediately with Sender A's real name
    final localItem = LocalConnectionItem(
      userId: senderId,
      phoneNumber: request.senderPhone,
      displayName: senderRealName,
      createdAt: DateTime.now(),
    );
    await _localStorage.upsertConnection(receiverId, localItem);
  }

  /// Rejects a connection request.
  Future<void> rejectRequest(String requestId) async {
    await _requests.doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a connection bidirectionally both locally and in Cloud Firestore:
  /// Uses FieldValue.arrayRemove() for emergency_contacts array.
  Future<void> removeConnection({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // 1. Mark as pending delete in local storage immediately
    await _localStorage.markPendingDelete(currentUserId, targetUserId);

    // 2. Attempt Cloud Firestore deletion
    try {
      // Remove targetUserId from currentUserId's emergency_contacts
      await _users.doc(currentUserId).set({
        'emergency_contacts': FieldValue.arrayRemove([targetUserId]),
      }, SetOptions(merge: true));

      // Remove currentUserId from targetUserId's emergency_contacts
      await _users.doc(targetUserId).set({
        'emergency_contacts': FieldValue.arrayRemove([currentUserId]),
      }, SetOptions(merge: true));

      // Delete connections subcollection documents
      await _userConnections(currentUserId).doc(targetUserId).delete();
      await _userConnections(targetUserId).doc(currentUserId).delete();

      await _localStorage.clearPendingDelete(currentUserId, targetUserId);
    } catch (_) {
      // If offline, deletion remains queued in local storage pending sync
    }
  }

  /// Synchronizes local storage cache with Cloud Firestore real-time snapshots.
  /// Dynamically resolves each contact's real registered name from users/{otherUserUid}.
  Stream<List<UserConnectionItem>> streamUserConnections(String userId) {
    final controller = StreamController<List<UserConnectionItem>>();

    // Initial load from local storage
    _localStorage.getConnections(userId).then((localList) {
      final activeLocal = localList
          .where((item) => item.syncStatus != 'pendingDelete')
          .map((item) => item.toUserConnectionItem())
          .toList();
      if (!controller.isClosed) {
        controller.add(activeLocal);
      }
    });

    // Listen to Cloud Firestore real-time changes
    final subscription = _userConnections(userId).snapshots().listen(
      (snap) async {
        // Process any queued pending deletions first
        final pendingDeletions = await _localStorage.getPendingDeletions(userId);
        for (final targetId in pendingDeletions) {
          try {
            await _users.doc(userId).set({
              'emergency_contacts': FieldValue.arrayRemove([targetId]),
            }, SetOptions(merge: true));
            await _users.doc(targetId).set({
              'emergency_contacts': FieldValue.arrayRemove([userId]),
            }, SetOptions(merge: true));
            await _userConnections(userId).doc(targetId).delete();
            await _userConnections(targetId).doc(targetId).delete();
            await _localStorage.clearPendingDelete(userId, targetId);
          } catch (_) {}
        }

        final rawItems =
            snap.docs.map((doc) => UserConnectionItem.fromFirestore(doc)).toList();

        // Migration/Sync: Ensure all cloud items are present in emergency_contacts array
        final connUids = rawItems.map((c) => c.userId).toList();
        if (connUids.isNotEmpty) {
          try {
            await _users.doc(userId).set({
              'emergency_contacts': FieldValue.arrayUnion(connUids),
            }, SetOptions(merge: true));
          } catch (_) {}
        }

        // Dynamically resolve real registered profile names from users/{otherUid}
        final List<UserConnectionItem> resolvedItems = [];
        for (final item in rawItems) {
          final realName = await _resolveUserFullName(item.userId, item.displayName);
          resolvedItems.add(item.copyWith(displayName: realName));
        }

        final localItems = resolvedItems.map((item) {
          return LocalConnectionItem(
            userId: item.userId,
            phoneNumber: item.phoneNumber,
            displayName: item.displayName,
            createdAt: item.createdAt,
            syncStatus: 'synced',
          );
        }).toList();

        await _localStorage.saveConnections(userId, localItems);

        final activeItems = localItems
            .where((item) => !pendingDeletions.contains(item.userId))
            .map((item) => item.toUserConnectionItem())
            .toList();

        if (!controller.isClosed) {
          controller.add(activeItems);
        }
      },
      onError: (error) async {
        // Offline handling: Fallback to local storage cache
        final localList = await _localStorage.getConnections(userId);
        final activeLocal = localList
            .where((item) => item.syncStatus != 'pendingDelete')
            .map((item) => item.toUserConnectionItem())
            .toList();
        if (!controller.isClosed) {
          controller.add(activeLocal);
        }
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }
}
