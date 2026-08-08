import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// TODO: Replace temporary phone-number authentication with Firebase Phone Authentication/OTP before production.

class AuthService {
  final FirebaseFirestore _firestore;
  static const String _sessionPhoneKey = 'raksha_session_phone';
  static const String _sessionUidKey = 'raksha_session_uid';

  AuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Normalizes phone numbers:
  /// - Removes whitespace and non-digit/non-plus characters.
  /// - Converts 10-digit Indian numbers (e.g. 8369775954) into +918369775954.
  String normalizePhoneNumber(String rawPhone) {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return cleaned;

    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        return '+91$cleaned';
      } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
        return '+$cleaned';
      } else {
        return '+$cleaned';
      }
    }
    return cleaned;
  }

  /// Searches Firestore users collection for an existing user with this phone number.
  Future<UserModel?> findUserByPhone(String rawPhone) async {
    final normalized = normalizePhoneNumber(rawPhone);
    if (normalized.isEmpty) return null;

    // Check by phoneNumber field first
    var query = await _users
        .where('phoneNumber', isEqualTo: normalized)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      // Fallback check by phone field
      query = await _users
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();
    }

    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  /// Creates a new user document in Firestore.
  Future<UserModel> createUser({
    required String rawPhone,
    required String firstName,
    required String lastName,
  }) async {
    final normalized = normalizePhoneNumber(rawPhone);
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final displayName = '$trimmedFirst $trimmedLast'.trim();

    final docRef = _users.doc();
    final user = UserModel(
      uid: docRef.id,
      firstName: trimmedFirst,
      lastName: trimmedLast,
      name: displayName,
      phone: normalized,
      photoUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBSUEL7rzgOUfdodwwHNcQbn_MHokVlIecnYhN8TPN4KhvtW8M3TYZw1KPrm3UUYMfDPD-CyC6H4pnG_wuCRlbFOo0sHv6vRLEmIYBJTMFcxegdK9_q98JjiFSGeh6yTbJScbg111WeZv3X0Od_rjlCtLqLJWkOYc5ePgUjEra3ocWEwQrUEaX1TgYs2NEDlH1A4pxqtvMe0BMaKHD-3BH4qBOTfLnuZERSJxJPt7Kf2ghB4cM1e83C3w',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(user.toMap());
    await saveLocalSession(phone: normalized, uid: user.uid);
    return user;
  }

  /// Persists local login session.
  Future<void> saveLocalSession({required String phone, required String uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionPhoneKey, phone);
    await prefs.setString(_sessionUidKey, uid);
  }

  /// Retrieves persisted local login session phone number.
  Future<String?> getLocalSessionPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionPhoneKey);
  }

  /// Retrieves persisted local login session UID.
  Future<String?> getLocalSessionUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionUidKey);
  }

  /// Clears local login session on logout.
  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionPhoneKey);
    await prefs.remove(_sessionUidKey);
  }
}
