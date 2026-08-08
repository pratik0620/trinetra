import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_model.dart';
import '../models/safety_event_model.dart';

class EmergencyRepository {
  final FirebaseFirestore _firestore;

  EmergencyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _emergencies =>
      _firestore.collection('emergencies');

  CollectionReference<Map<String, dynamic>> get _safetyEvents =>
      _firestore.collection('safety_events');

  Future<String> createEmergency({
    required String userId,
    required String deviceId,
    required String triggerType,
    double latitude = 28.6139,
    double longitude = 77.2090,
    double accuracy = 5.0,
  }) async {
    final docRef = _emergencies.doc();
    final emergency = EmergencyModel(
      id: docRef.id,
      userId: userId,
      deviceId: deviceId,
      triggerType: triggerType,
      status: 'active',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );

    await docRef.set(emergency.toMap());

    // Also log safety event
    final eventRef = _safetyEvents.doc();
    final safetyEvent = SafetyEventFirestoreModel(
      id: eventRef.id,
      userId: userId,
      type: triggerType == 'manual_sos' ? 'sos_triggered' : 'manual_stomp',
      status: 'Critical',
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      emergencyId: docRef.id,
    );

    await eventRef.set(safetyEvent.toMap());

    return docRef.id;
  }

  Future<void> respondToEmergency({
    required String emergencyId,
    required String guardianUid,
  }) async {
    await _emergencies.doc(emergencyId).update({
      'status': 'responding',
      'respondingGuardianId': guardianUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveEmergency(String emergencyId) async {
    final doc = await _emergencies.doc(emergencyId).get();
    final data = doc.data() ?? {};
    final userId = data['userId'] ?? '';

    await _emergencies.doc(emergencyId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId.isNotEmpty) {
      final eventRef = _safetyEvents.doc();
      final safetyEvent = SafetyEventFirestoreModel(
        id: eventRef.id,
        userId: userId,
        type: 'sos_cancelled',
        status: 'Resolved',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 28.6139,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 77.2090,
        timestamp: DateTime.now(),
        emergencyId: emergencyId,
      );
      await eventRef.set(safetyEvent.toMap());
    }
  }

  Future<void> cancelEmergency(String emergencyId) async {
    await resolveEmergency(emergencyId);
  }

  Stream<EmergencyModel?> streamEmergency(String emergencyId) {
    return _emergencies.doc(emergencyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return EmergencyModel.fromFirestore(doc);
    });
  }

  Stream<EmergencyModel?> streamActiveEmergencyForUser(String userId) {
    return _emergencies
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'verifying', 'responding'])
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return EmergencyModel.fromFirestore(snap.docs.first);
    });
  }

  Stream<List<SafetyEventFirestoreModel>> streamSafetyHistory(String userId) {
    return _safetyEvents
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SafetyEventFirestoreModel.fromFirestore(doc))
            .toList());
  }
}
