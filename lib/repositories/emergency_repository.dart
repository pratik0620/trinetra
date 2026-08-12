import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/config/location_config.dart';
import '../models/emergency_location_model.dart';
import '../models/emergency_model.dart';
import '../models/offline_emergency_model.dart';
import '../models/safety_event_model.dart';
import '../services/live_location_service.dart';

class EmergencyRepository {
  final FirebaseFirestore _firestore;
  static final Map<String, OfflineEmergencyModel> _localCache = {};
  static final Map<String, Map<String, dynamic>> _pendingSyncQueue = {};

  EmergencyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _emergencies =>
      _firestore.collection('emergencies');

  CollectionReference<Map<String, dynamic>> get _safetyEvents =>
      _firestore.collection('safety_events');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Registers an offline or payload emergency in local cache for immediate rendering.
  void registerOfflineEmergency(OfflineEmergencyModel model) {
    final existing = _localCache[model.emergencyId];
    if (existing == null) {
      _localCache[model.emergencyId] = model;
    } else {
      // Merge properties without overriding a 'responding' or 'resolved' status with stale 'active'
      final statusRank = {'active': 1, 'responding': 2, 'resolved': 3};
      final newRank = statusRank[model.status.toLowerCase()] ?? 1;
      final oldRank = statusRank[existing.status.toLowerCase()] ?? 1;

      _localCache[model.emergencyId] = existing.copyWith(
        userName: existing.userName.isNotEmpty && existing.userName != 'RAKSHA Contact'
            ? existing.userName
            : model.userName,
        phoneNumber: existing.phoneNumber ?? model.phoneNumber,
        latitude: model.latitude ?? existing.latitude,
        longitude: model.longitude ?? existing.longitude,
        isFallback: model.isFallback,
        status: newRank >= oldRank ? model.status : existing.status,
      );
    }
  }

  /// Streams emergency as OfflineEmergencyModel.
  /// Emits cached offline data immediately if present, and updates from Firestore when available.
  Stream<OfflineEmergencyModel?> streamUnifiedEmergency(String emergencyId) {
    final controller = StreamController<OfflineEmergencyModel?>();

    // Initial emission from local cache
    final cached = _localCache[emergencyId];
    if (cached != null) {
      controller.add(cached);
    }

    // Stream Firestore document
    final subscription = _emergencies.doc(emergencyId).snapshots().listen(
      (snap) async {
        if (!snap.exists) {
          if (cached != null) {
            controller.add(cached);
          } else {
            controller.add(null);
          }
          return;
        }

        final model = EmergencyModel.fromFirestore(snap);
        String victimName = 'RAKSHA Contact';
        String? victimPhone;

        try {
          final userDoc = await _users.doc(model.userId).get();
          if (userDoc.exists) {
            final data = userDoc.data() ?? {};
            final fName = data['firstName'] ?? '';
            final lName = data['lastName'] ?? '';
            final full = '$fName $lName'.trim();
            if (full.isNotEmpty) {
              victimName = full;
            } else if (data['displayName'] != null) {
              victimName = data['displayName'].toString();
            } else if (data['name'] != null) {
              victimName = data['name'].toString();
            }
            victimPhone = data['phoneNumber'] ?? data['phone'];
          }
        } catch (_) {}

        final unified = OfflineEmergencyModel.fromEmergencyModel(
          model,
          userName: victimName,
          phoneNumber: victimPhone,
        );

        // Keep local cache updated
        registerOfflineEmergency(unified);

        if (!controller.isClosed) {
          controller.add(_localCache[emergencyId] ?? unified);
        }
      },
      onError: (err) {
        debugPrint('Firestore stream note: $err');
        // Fallback to local cache on error/offline
        if (!controller.isClosed) {
          controller.add(_localCache[emergencyId]);
        }
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  Future<String> createEmergency({
    required String userId,
    required String deviceId,
    required String triggerType,
    double? latitude,
    double? longitude,
    bool isFallback = false,
    double accuracy = 5.0,
  }) async {
    double finalLat = latitude ?? 0.0;
    double finalLng = longitude ?? 0.0;
    bool finalIsFallback = isFallback;

    if (finalLat == 0.0 && finalLng == 0.0) {
      final posResult = await LiveLocationService().getCurrentPositionOrFallback();
      finalLat = posResult.latitude;
      finalLng = posResult.longitude;
      finalIsFallback = posResult.isFallback;
    }

    LocationConfig.logLocationStatus(
      latitude: finalLat,
      longitude: finalLng,
      isFallback: finalIsFallback,
      tag: 'EMERGENCY_REPO_CREATE',
    );

    final docRef = _emergencies.doc();
    final emergency = EmergencyModel(
      id: docRef.id,
      userId: userId,
      deviceId: deviceId,
      triggerType: triggerType,
      status: 'active',
      latitude: finalLat,
      longitude: finalLng,
      accuracy: accuracy,
      isFallback: finalIsFallback,
    );

    try {
      await docRef.set(emergency.toMap());

      final eventRef = _safetyEvents.doc();
      final safetyEvent = SafetyEventFirestoreModel(
        id: eventRef.id,
        userId: userId,
        type: triggerType == 'manual_sos' ? 'sos_triggered' : 'manual_stomp',
        status: 'Critical',
        latitude: finalLat,
        longitude: finalLng,
        timestamp: DateTime.now(),
        emergencyId: docRef.id,
      );

      await eventRef.set(safetyEvent.toMap());
    } catch (e) {
      debugPrint('Emergency create note: $e');
    }

    final localModel = OfflineEmergencyModel(
      emergencyId: docRef.id,
      userId: userId,
      userName: 'You',
      triggerType: triggerType,
      latitude: finalLat,
      longitude: finalLng,
      isFallback: finalIsFallback,
      timestamp: DateTime.now(),
      status: 'active',
      source: 'manual',
    );
    registerOfflineEmergency(localModel);

    return docRef.id;
  }

  /// Updates emergency status to 'responding' (ACKNOWLEDGED)
  Future<void> respondToEmergency({
    required String emergencyId,
    required String guardianUid,
  }) async {
    // 1. Update local cache immediately
    final cached = _localCache[emergencyId];
    if (cached != null) {
      _localCache[emergencyId] = cached.copyWith(
        status: 'responding',
        respondingGuardianId: guardianUid,
      );
    } else {
      _localCache[emergencyId] = OfflineEmergencyModel(
        emergencyId: emergencyId,
        userId: '',
        userName: 'RAKSHA Contact',
        triggerType: 'manual_sos',
        timestamp: DateTime.now(),
        status: 'responding',
        source: 'fcm',
        respondingGuardianId: guardianUid,
      );
    }

    // 2. Update Firestore
    try {
      await _emergencies.doc(emergencyId).update({
        'status': 'responding',
        'respondingGuardianId': guardianUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _pendingSyncQueue.remove(emergencyId);
    } catch (e) {
      debugPrint('Offline queued respond update for $emergencyId: $e');
      _pendingSyncQueue[emergencyId] = {
        'status': 'responding',
        'respondingGuardianId': guardianUid,
      };
    }
  }

  /// Updates emergency status to 'resolved'
  Future<void> resolveEmergency(String emergencyId) async {
    // 1. Update local cache immediately
    final cached = _localCache[emergencyId];
    if (cached != null) {
      _localCache[emergencyId] = cached.copyWith(
        status: 'resolved',
      );
    }

    // 2. Update Firestore
    try {
      final doc = await _emergencies.doc(emergencyId).get();
      final data = doc.data() ?? {};
      final userId = data['userId'] ?? cached?.userId ?? '';

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
          latitude: (data['latitude'] as num?)?.toDouble() ?? cached?.latitude ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? cached?.longitude ?? 0.0,
          timestamp: DateTime.now(),
          emergencyId: emergencyId,
        );
        await eventRef.set(safetyEvent.toMap());
      }
      _pendingSyncQueue.remove(emergencyId);
    } catch (e) {
      debugPrint('Offline queued resolve update for $emergencyId: $e');
      _pendingSyncQueue[emergencyId] = {
        'status': 'resolved',
      };
    }
  }

  /// Attempts to synchronize queued offline responses to Cloud Firestore upon network reconnection.
  Future<void> syncPendingEmergencyUpdates() async {
    if (_pendingSyncQueue.isEmpty) return;

    final keys = List<String>.from(_pendingSyncQueue.keys);
    for (final eId in keys) {
      final data = _pendingSyncQueue[eId];
      if (data == null) continue;

      try {
        await _emergencies.doc(eId).update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _pendingSyncQueue.remove(eId);
        debugPrint('Synced offline update for $eId to Firestore');
      } catch (_) {}
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

  /// Updates live location document under emergencies/{emergencyId}/locations/{userId}
  Future<void> updateUserEmergencyLocation({
    required String emergencyId,
    required String userId,
    required String name,
    required String role, // 'victim' or 'guardian'
    required double latitude,
    required double longitude,
    bool isFallback = false,
  }) async {
    final locationRef = _emergencies
        .doc(emergencyId)
        .collection('locations')
        .doc(userId);

    final data = {
      'userId': userId,
      'name': name,
      'role': role.toLowerCase(),
      'latitude': latitude,
      'longitude': longitude,
      'isFallback': isFallback,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (role.toLowerCase() == 'victim') {
        debugPrint('====================================');
        debugPrint('VICTIM FIRESTORE WRITE:');
        debugPrint('path=${locationRef.path}');
        debugPrint('====================================');
      }

      await locationRef.set(data, SetOptions(merge: true));

      // Also update primary emergency doc if victim
      if (role.toLowerCase() == 'victim') {
        await _emergencies.doc(emergencyId).update({
          'latitude': latitude,
          'longitude': longitude,
          'isFallback': isFallback,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Location update note: $e');
    }
  }

  /// Real-time stream of all location documents in emergencies/{emergencyId}/locations
  Stream<List<EmergencyLocationModel>> streamEmergencyLocations(String emergencyId) {
    return _emergencies
        .doc(emergencyId)
        .collection('locations')
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((doc) => EmergencyLocationModel.fromFirestore(doc))
          .toList();
      debugPrint('====================================');
      debugPrint('GUARDIAN LOCATION LISTENER:');
      debugPrint('documents received=${docs.length}');
      for (final d in docs) {
        debugPrint(' - [${d.role.toUpperCase()}] name=${d.name}, uid=${d.userId}, lat=${d.latitude}, lng=${d.longitude}, isFallback=${d.isFallback}');
      }
      debugPrint('====================================');
      return docs;
    });
  }
}
