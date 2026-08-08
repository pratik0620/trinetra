import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String senderPhone;
  final String senderName;
  final String receiverId;
  final String receiverPhone;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime? createdAt;

  const ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.senderPhone,
    required this.senderName,
    required this.receiverId,
    required this.receiverPhone,
    this.status = 'pending',
    this.createdAt,
  });

  factory ConnectionRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ConnectionRequestModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderPhone: data['senderPhone'] ?? '',
      senderName: data['senderName'] ?? 'RAKSHA Contact',
      receiverId: data['receiverId'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderPhone': senderPhone,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverPhone': receiverPhone,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class UserConnectionItem {
  final String userId;
  final String phoneNumber;
  final String displayName;
  final DateTime? createdAt;

  const UserConnectionItem({
    required this.userId,
    required this.phoneNumber,
    required this.displayName,
    this.createdAt,
  });

  factory UserConnectionItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserConnectionItem(
      userId: data['userId'] ?? doc.id,
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? 'RAKSHA Contact',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
