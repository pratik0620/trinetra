import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection_request_model.dart';
import '../models/user_model.dart';

class ConnectionRepository {
  final FirebaseFirestore _firestore;

  ConnectionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('connectionRequests');

  CollectionReference<Map<String, dynamic>> _userConnections(String userId) =>
      _firestore.collection('users').doc(userId).collection('connections');

  /// Sends a connection request from sender to receiver.
  /// Checks for existing pending requests first to prevent duplicates.
  Future<void> sendConnectionRequest({
    required UserModel sender,
    required UserModel receiver,
  }) async {
    // 1. Check for duplicate pending requests
    final existingSnap = await _requests
        .where('senderId', isEqualTo: sender.uid)
        .where('receiverId', isEqualTo: receiver.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingSnap.docs.isNotEmpty) {
      throw 'A connection request is already pending for this contact.';
    }

    // Also check reverse pending request
    final reverseSnap = await _requests
        .where('senderId', isEqualTo: receiver.uid)
        .where('receiverId', isEqualTo: sender.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (reverseSnap.docs.isNotEmpty) {
      throw 'This contact has already sent you a connection request.';
    }

    // 2. Create new connection request
    final docRef = _requests.doc();
    final request = ConnectionRequestModel(
      id: docRef.id,
      senderId: sender.uid,
      senderPhone: sender.phone,
      senderName: sender.name,
      receiverId: receiver.uid,
      receiverPhone: receiver.phone,
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

  /// Accepts a connection request and creates bidirectional Firestore entries in users/{uid}/connections.
  Future<void> acceptRequest(ConnectionRequestModel request) async {
    // 1. Update request status to accepted
    await _requests.doc(request.id).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create entry in sender's connections
    final senderConnItem = UserConnectionItem(
      userId: request.receiverId,
      phoneNumber: request.receiverPhone,
      displayName: 'RAKSHA Contact',
      createdAt: DateTime.now(),
    );

    await _userConnections(request.senderId)
        .doc(request.receiverId)
        .set(senderConnItem.toMap(), SetOptions(merge: true));

    // 3. Create entry in receiver's connections
    final receiverConnItem = UserConnectionItem(
      userId: request.senderId,
      phoneNumber: request.senderPhone,
      displayName: request.senderName,
      createdAt: DateTime.now(),
    );

    await _userConnections(request.receiverId)
        .doc(request.senderId)
        .set(receiverConnItem.toMap(), SetOptions(merge: true));
  }

  /// Rejects a connection request.
  Future<void> rejectRequest(String requestId) async {
    await _requests.doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams accepted connections for a user from users/{userId}/connections subcollection.
  Stream<List<UserConnectionItem>> streamUserConnections(String userId) {
    return _userConnections(userId).snapshots().map((snap) => snap.docs
        .map((doc) => UserConnectionItem.fromFirestore(doc))
        .toList());
  }
}
