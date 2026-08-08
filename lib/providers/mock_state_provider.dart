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
              id: 'user_priya',
              name: 'Priya Sharma',
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
            peopleIProtect: const [
              NetworkContact(
                id: 'contact_ananya',
                name: 'Ananya',
                relationship: 'Friend',
                isSafe: true,
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCKpDDJfDRJtsdpEB3jX8EaFb8_jampFIrjlsmlMsC8ZYRCRm2SrZF5VnB5tzOh4WHfGep29CO6xSP0EW8BYaXd8CVJbCgf3iNaAXcTgNnFdjiN05-lUo8khrslYX5O35nIpsCCOyxPuu332wpiioNtf1uxSsaDf2GNhsMrjyhKGSq7ZYpXE6tTBj3PBNLztekKQDNd_xvvCsgrZUiH8Wu4_cwoC2dy3GxuqCjxHY4ejxwpYjSjk-R5Yw',
                isProtectedByMe: true,
                isProtectingMe: true,
              ),
              NetworkContact(
                id: 'contact_sneha',
                name: 'Sneha',
                relationship: 'Colleague',
                isSafe: true,
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaIUmAxPpoRO_X4_rp5FEaysxeeOa1BGJt2CD3BuX4AYnaBN4NwBENTZZKvYcwtCSeNW_M_OApGzXryJSSSINeIpYDPts7NXEjlDR-PYrl9fLsB06y_eGv8DdUuf1Vu3OE_aHIWlUSIV65n7h8_K1YbK4D8UN-1XiuBO-pwNrrwSKUlXJYOqIlTUO5qeJh9xlWtFNicHdrWDuixeik-avk8QXvVZEcTHmE9zmqIcjzHkhlJ1ByvNAjA',
                isProtectedByMe: true,
                isProtectingMe: false,
              ),
            ],
            peopleWhoProtectMe: const [
              NetworkContact(
                id: 'contact_ananya',
                name: 'Ananya',
                relationship: 'Emergency Contact',
                isSafe: true,
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAV_E6ZEBfz5cYaFGENFgiQPxNCphp1Wrj7_Ni5HUzO-Zvi0lNiPXXAEPlPTKpvjfHj01zCmKoqC1L4zrXUBuEkefMnw6DiAK76Ysbp4Qp1NORwQ6VKpvKWiUZnjsEiTaVAxecIgpP2Sb91IHJ7C2muoVrH8e8m0rq-4uLvzedzSXzUPdcC_mhzJuNDpZFckQspSEsR5qD51LsJWcv1OiOqrzfVb6PiXwFuQFQEVLgVOJVFpVf6DaqjbQ',
                isProtectedByMe: true,
                isProtectingMe: true,
              ),
              NetworkContact(
                id: 'contact_riya',
                name: 'Riya',
                relationship: 'Emergency Contact',
                isSafe: true,
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDwpuc6BEsXloqBFzXyZiw_hCDiwtaNDVrb1zkiwXpXYJbC68Pj_rJX32cjVyALwjXmI0b87iEiyWpBSblk1KcpsVlcrKfjmmx_cabvAMRer7YRzwxqG89gfqL4PRSkrSVwcwqH1SMOToT426f-yqWPhASCgR5RMZtYqn6nlMKQnCbKuhKKDqGFqfRlwJrzPcx2pOuqlvFsNKCGGE7HJ-ze-LyBfkNVd2JfdFqqKm5Pp-B0N0Qz1nknpA',
                isProtectedByMe: false,
                isProtectingMe: true,
              ),
            ],
            historyEvents: const [
              HistoryEventModel(
                id: 'h1',
                title: 'Normal activity',
                subtitle: 'Routine location ping',
                timestamp: '10:42 AM',
                badgeText: 'Safe',
                type: EventType.normal,
              ),
              HistoryEventModel(
                id: 'h2',
                title: 'Suspicious movement',
                subtitle: 'Deviation from usual route',
                timestamp: '09:31 AM',
                badgeText: 'Monitored',
                type: EventType.warning,
              ),
              HistoryEventModel(
                id: 'h3',
                title: 'Manual Stomp',
                subtitle: 'SOS Triggered physically',
                timestamp: 'Yesterday, 8:14 PM',
                badgeText: 'Critical',
                type: EventType.critical,
              ),
              HistoryEventModel(
                id: 'h4',
                title: 'SOS Cancelled',
                subtitle: 'Authenticated via PIN',
                timestamp: 'Yesterday, 8:15 PM',
                badgeText: 'Resolved',
                type: EventType.resolved,
              ),
            ],
            guardianSession: const GuardianEmergencySession(
              victimName: 'Priya',
              triggerType: 'Manual Stomp',
              secondsAgo: 18,
              distanceKm: 2.4,
              locationText: '123 Safety St, City Center',
              responderName: 'You (Ananya)',
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

  void addConnection(String name, String relationship) {
    final newContact = NetworkContact(
      id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      relationship: relationship,
      isSafe: true,
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7gV1IUicEKpYk-byk7EBLd1I_g_08STyU9WnRLYq8wZRpwsEtKs_XVx-lwvlOf-AWTPM37PDlnBhHygW_lBbSfLyb32fEIr6qNjmLkQPtpOf6L3NYONOqWhO8xDUoohlW0C_aSyh_wFZ52SGfs98_HWEb7dRInarggo1uUcELOJNSJ1FIltHLiDDh1K8P84Nmd6UrZd8qHaRR6xP-W71jmp__x6JGBJuNKfd-YoJi-1WWtaaGAaYCxw',
      isProtectedByMe: true,
      isProtectingMe: false,
    );

    state = state.copyWith(
      peopleIProtect: [...state.peopleIProtect, newContact],
    );
  }
}

final mockStateProvider =
    StateNotifierProvider<MockStateNotifier, RAKSHAAppState>((ref) {
  return MockStateNotifier();
});
