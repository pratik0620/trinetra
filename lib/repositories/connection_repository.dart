import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection_model.dart';

class ConnectionRepository {
  final FirebaseFirestore _firestore;

  ConnectionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _connections =>
      _firestore.collection('connections');

  Future<void> sendConnectionRequest({
    required String requesterId,
    required String receiverId,
    required String relationship,
    bool canReceiveSOS = true,
    bool canShareLocation = true,
  }) async {
    final docRef = _connections.doc();
    final connection = ConnectionModel(
      id: docRef.id,
      requesterId: requesterId,
      receiverId: receiverId,
      relationship: relationship,
      canReceiveSOS: canReceiveSOS,
      canShareLocation: canShareLocation,
      status: 'pending',
    );
    await docRef.set(connection.toMap());
  }

  Future<void> acceptConnectionRequest(String connectionId) async {
    await _connections.doc(connectionId).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectConnectionRequest(String connectionId) async {
    await _connections.doc(connectionId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ConnectionModel>> streamConnectionsForUser(String uid) {
    // Queries all connections involving uid as requester or receiver
    final requesterStream = _connections
        .where('requesterId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();

    return requesterStream.asyncMap((reqSnap) async {
      final recSnap = await _connections
          .where('receiverId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      final list1 = reqSnap.docs.map((d) => ConnectionModel.fromFirestore(d)).toList();
      final list2 = recSnap.docs.map((d) => ConnectionModel.fromFirestore(d)).toList();

      final combined = [...list1, ...list2];
      final uniqueMap = {for (var item in combined) item.id: item};
      return uniqueMap.values.toList();
    });
  }

  Stream<List<ConnectionModel>> streamPendingRequests(String uid) {
    return _connections
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ConnectionModel.fromFirestore(doc)).toList());
  }
}
