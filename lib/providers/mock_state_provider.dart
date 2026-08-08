import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';

class RAKSHAAppState {
  final UserProfile currentUser;
  final ShoeStatusModel shoeStatus;
  final SafetyStatusEnum safetyStatus;
  final bool mySosActive;
  final GuardianEmergencyStage guardianStage;
  final bool hasCompletedOnboarding;
  final bool isLoggedIn;
  final List<NetworkContact> peopleIProtect;
  final List<NetworkContact> peopleWhoProtectMe;
  final List<HistoryEventModel> historyEvents;
  final GuardianEmergencySession guardianSession;

  const RAKSHAAppState({
    required this.currentUser,
    required this.shoeStatus,
    required this.safetyStatus,
    required this.mySosActive,
    required this.guardianStage,
    required this.hasCompletedOnboarding,
    required this.isLoggedIn,
    required this.peopleIProtect,
    required this.peopleWhoProtectMe,
    required this.historyEvents,
    required this.guardianSession,
  });

  RAKSHAAppState copyWith({
    UserProfile? currentUser,
    ShoeStatusModel? shoeStatus,
    SafetyStatusEnum? safetyStatus,
    bool? mySosActive,
    GuardianEmergencyStage? guardianStage,
    bool? hasCompletedOnboarding,
    bool? isLoggedIn,
    List<NetworkContact>? peopleIProtect,
    List<NetworkContact>? peopleWhoProtectMe,
    List<HistoryEventModel>? historyEvents,
    GuardianEmergencySession? guardianSession,
  }) {
    return RAKSHAAppState(
      currentUser: currentUser ?? this.currentUser,
      shoeStatus: shoeStatus ?? this.shoeStatus,
      safetyStatus: safetyStatus ?? this.safetyStatus,
      mySosActive: mySosActive ?? this.mySosActive,
      guardianStage: guardianStage ?? this.guardianStage,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      peopleIProtect: peopleIProtect ?? this.peopleIProtect,
      peopleWhoProtectMe: peopleWhoProtectMe ?? this.peopleWhoProtectMe,
      historyEvents: historyEvents ?? this.historyEvents,
      guardianSession: guardianSession ?? this.guardianSession,
    );
  }
}

class MockStateNotifier extends StateNotifier<RAKSHAAppState> {
  MockStateNotifier()
      : super(
          RAKSHAAppState(
            currentUser: const UserProfile(
              id: 'user_current',
              name: 'RAKSHA User',
              phone: '+91 98765 43210',
              avatarUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBSUEL7rzgOUfdodwwHNcQbn_MHokVlIecnYhN8TPN4KhvtW8M3TYZw1KPrm3UUYMfDPD-CyC6H4pnG_wuCRlbFOo0sHv6vRLEmIYBJTMFcxegdK9_q98JjiFSGeh6yTbJScbg111WeZv3X0Od_rjlCtLqLJWkOYc5ePgUjEra3ocWEwQrUEaX1TgYs2NEDlH1A4pxqtvMe0BMaKHD-3BH4qBOTfLnuZERSJxJPt7Kf2ghB4cM1e83C3w',
            ),
            shoeStatus: const ShoeStatusModel(
              isConnected: true,
              batteryPercent: 84,
              isBleConnected: true,
              isGpsAvailable: true,
              is4gConnected: true,
              lastSyncedText: '10s ago',
            ),
            safetyStatus: SafetyStatusEnum.safe,
            mySosActive: false,
            guardianStage: GuardianEmergencyStage.none,
            hasCompletedOnboarding: false,
            isLoggedIn: true,
            peopleIProtect: const [],
            peopleWhoProtectMe: const [],
            historyEvents: const [],
            guardianSession: const GuardianEmergencySession(
              victimName: 'Contact',
              triggerType: 'Manual SOS',
              secondsAgo: 18,
              distanceKm: 2.4,
              locationText: '123 Safety St, City Center',
              responderName: 'You',
              durationText: '4 min 32 sec',
            ),
          ),
        );

  void completeOnboarding() {
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  void login() {
    state = state.copyWith(isLoggedIn: true);
  }

  void toggleShoeConnection() {
    final nextConnected = !state.shoeStatus.isConnected;
    state = state.copyWith(
      shoeStatus: state.shoeStatus.copyWith(
        isConnected: nextConnected,
        batteryPercent: nextConnected ? 84 : 0,
        isBleConnected: nextConnected,
        isGpsAvailable: nextConnected,
        is4gConnected: nextConnected,
        lastSyncedText: nextConnected ? 'Just now' : 'Disconnected',
      ),
    );
  }

  void setSafetyStatus(SafetyStatusEnum newStatus) {
    state = state.copyWith(safetyStatus: newStatus);
  }

  void triggerMySos() {
    state = state.copyWith(
      mySosActive: true,
      safetyStatus: SafetyStatusEnum.emergency,
    );
  }

  void cancelMySos() {
    state = state.copyWith(
      mySosActive: false,
      safetyStatus: SafetyStatusEnum.safe,
    );
  }

  void triggerGuardianNotification() {
    state = state.copyWith(
      guardianStage: GuardianEmergencyStage.incomingNotification,
    );
  }

  void viewGuardianActiveSOS() {
    state = state.copyWith(
      guardianStage: GuardianEmergencyStage.activeSOS,
    );
  }

  void respondToGuardianEmergency() {
    state = state.copyWith(
      guardianStage: GuardianEmergencyStage.responding,
    );
  }

  void resolveGuardianEmergency() {
    state = state.copyWith(
      guardianStage: GuardianEmergencyStage.resolved,
    );
  }

  void dismissGuardianEmergency() {
    state = state.copyWith(
      guardianStage: GuardianEmergencyStage.none,
    );
  }
}

final mockStateProvider =
    StateNotifierProvider<MockStateNotifier, RAKSHAAppState>((ref) {
  return MockStateNotifier();
});
