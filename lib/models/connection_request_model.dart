import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String senderPhone;
  final String senderName;
  final String receiverId;
  final String receiverPhone;
  final String receiverName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime? createdAt;

  const ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.senderPhone,
    required this.senderName,
    required this.receiverId,
    required this.receiverPhone,
    this.receiverName = '',
    this.status = 'pending',
    this.createdAt,
  });

  factory ConnectionRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final sFName = data['senderFirstName'] ?? '';
    final sLName = data['senderLastName'] ?? '';
    final sFull = '$sFName $sLName'.trim();
    final sName = sFull.isNotEmpty
        ? sFull
        : (data['senderName'] ?? data['senderDisplayName'] ?? data['senderPhone'] ?? '');

    final rFName = data['receiverFirstName'] ?? '';
    final rLName = data['receiverLastName'] ?? '';
    final rFull = '$rFName $rLName'.trim();
    final rName = rFull.isNotEmpty
        ? rFull
        : (data['receiverName'] ?? data['receiverDisplayName'] ?? data['receiverPhone'] ?? '');

    return ConnectionRequestModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderPhone: data['senderPhone'] ?? '',
      senderName: sName.isNotEmpty ? sName : (data['senderPhone'] ?? ''),
      receiverId: data['receiverId'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      receiverName: rName.isNotEmpty ? rName : (data['receiverPhone'] ?? ''),
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
      'receiverName': receiverName,
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
    final fName = data['firstName'] ?? '';
    final lName = data['lastName'] ?? '';
    final full = '$fName $lName'.trim();
    final name = full.isNotEmpty
        ? full
        : (data['displayName'] ?? data['name'] ?? (data['phoneNumber'] ?? data['phone'] ?? doc.id));

    return UserConnectionItem(
      userId: data['userId'] ?? doc.id,
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      displayName: name,
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

  UserConnectionItem copyWith({
    String? displayName,
    String? phoneNumber,
  }) {
    return UserConnectionItem(
      userId: userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
    );
  }
}
