import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// TODO: Replace temporary phone-number authentication with Firebase Phone Authentication/OTP before production.

class AuthRepository {
  final FirebaseAuth _auth;
  final AuthService _authService;

  AuthRepository({
    FirebaseAuth? auth,
    AuthService? authService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _authService = authService ?? AuthService();

  AuthService get authService => _authService;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> findUserByPhone(String rawPhone) async {
    return await _authService.findUserByPhone(rawPhone);
  }

  Future<UserModel> createUser({
    required String rawPhone,
    required String firstName,
    required String lastName,
  }) async {
    return await _authService.createUser(
      rawPhone: rawPhone,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<void> saveLocalSession(String phone, String uid) async {
    await _authService.saveLocalSession(phone: phone, uid: uid);
  }

  Future<String?> getLocalSessionPhone() async {
    return await _authService.getLocalSessionPhone();
  }

  Future<String?> getLocalSessionUid() async {
    return await _authService.getLocalSessionUid();
  }

  Future<void> signOut() async {
    await _authService.clearLocalSession();
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
