import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> createOrUpdateUser(UserModel user) async {
    final docRef = _users.doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set(user.toMap());
    } else {
      await docRef.update({
        'name': user.name,
        'phone': user.phone,
        'photoUrl': user.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserModel?> searchUserByPhone(String phone) async {
    final query = await _users.where('phone', isEqualTo: phone).limit(1).get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  Future<void> saveFcmToken(String uid, String token) async {
    final tokenRef = _users.doc(uid).collection('fcm_tokens').doc(token);
    await tokenRef.set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUsed': FieldValue.serverTimestamp(),
    });

    final deviceRef = _users.doc(uid).collection('devices').doc(token);
    await deviceRef.set({
      'fcmToken': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _users.doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> removeFcmToken(String uid, String token) async {
    await _users.doc(uid).collection('fcm_tokens').doc(token).delete();
    await _users.doc(uid).collection('devices').doc(token).delete();
    await _users.doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  Future<String?> getRecipientFcmToken(String uid) async {
    final userDoc = await _users.doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data() ?? {};
      final fcmTokens = data['fcmTokens'];
      if (fcmTokens is List && fcmTokens.isNotEmpty) {
        return fcmTokens.first.toString();
      }
    }

    final devicesSnap = await _users.doc(uid).collection('devices').get();
    if (devicesSnap.docs.isNotEmpty) {
      final token = devicesSnap.docs.first.data()['fcmToken'];
      if (token != null && token.toString().isNotEmpty) return token.toString();
    }

    final tokensSnap = await _users.doc(uid).collection('fcm_tokens').get();
    if (tokensSnap.docs.isNotEmpty) {
      final token = tokensSnap.docs.first.data()['token'];
      if (token != null && token.toString().isNotEmpty) return token.toString();
    }

    return null;
  }
}
