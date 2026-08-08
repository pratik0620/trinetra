import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final String relationship;
  final bool canReceiveSOS;
  final bool canShareLocation;
  final String status; // 'pending', 'accepted', 'rejected', 'blocked'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConnectionModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.relationship,
    this.canReceiveSOS = true,
    this.canShareLocation = true,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory ConnectionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ConnectionModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      relationship: data['relationship'] ?? 'Friend',
      canReceiveSOS: data['canReceiveSOS'] ?? true,
      canShareLocation: data['canShareLocation'] ?? true,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'relationship': relationship,
      'canReceiveSOS': canReceiveSOS,
      'canShareLocation': canShareLocation,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
