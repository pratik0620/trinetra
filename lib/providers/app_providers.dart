import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_model.dart';
import '../models/emergency_model.dart';
import '../models/safety_event_model.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/connection_repository.dart';
import '../repositories/emergency_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(authService: ref.read(authServiceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepository();
});

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(userRepository: ref.read(userRepositoryProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final activeUserUidProvider = StateProvider<String?>((ref) => null);

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final activeUid = ref.watch(activeUserUidProvider);
  final authUser = ref.watch(authStateProvider).value;
  final targetUid = activeUid ?? authUser?.uid;

  if (targetUid == null) return Stream.value(null);

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.streamUserProfile(targetUid);
});

final userConnectionsProvider = StreamProvider<List<ConnectionModel>>((ref) {
  final activeUid = ref.watch(activeUserUidProvider);
  final authUser = ref.watch(authStateProvider).value;
  final targetUid = activeUid ?? authUser?.uid;

  if (targetUid == null) return Stream.value([]);

  final connRepo = ref.watch(connectionRepositoryProvider);
  return connRepo.streamConnectionsForUser(targetUid);
});

final userActiveEmergencyProvider = StreamProvider<EmergencyModel?>((ref) {
  final activeUid = ref.watch(activeUserUidProvider);
  final authUser = ref.watch(authStateProvider).value;
  final targetUid = activeUid ?? authUser?.uid;

  if (targetUid == null) return Stream.value(null);

  final emergencyRepo = ref.watch(emergencyRepositoryProvider);
  return emergencyRepo.streamActiveEmergencyForUser(targetUid);
});

final userSafetyHistoryProvider =
    StreamProvider<List<SafetyEventFirestoreModel>>((ref) {
  final activeUid = ref.watch(activeUserUidProvider);
  final authUser = ref.watch(authStateProvider).value;
  final targetUid = activeUid ?? authUser?.uid;

  if (targetUid == null) return Stream.value([]);

  final emergencyRepo = ref.watch(emergencyRepositoryProvider);
  return emergencyRepo.streamSafetyHistory(targetUid);
});
