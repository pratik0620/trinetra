import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String name;
  final String phone;
  final String photoUrl;
  final List<String> emergencyContacts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.phone,
    required this.photoUrl,
    this.emergencyContacts = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => name;
  String get phoneNumber => phone;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final fName = data['firstName'] ?? '';
    final lName = data['lastName'] ?? '';
    final fullName = data['displayName'] ?? data['name'] ?? (fName.isNotEmpty ? '$fName $lName'.trim() : 'RAKSHA User');
    final phoneNum = data['phoneNumber'] ?? data['phone'] ?? '';
    final eContactsRaw = data['emergency_contacts'] ?? data['emergencyContacts'];
    final List<String> eContacts = eContactsRaw is List ? List<String>.from(eContactsRaw) : [];

    return UserModel(
      uid: data['uid'] ?? doc.id,
      firstName: fName.isNotEmpty ? fName : (fullName.split(' ').first),
      lastName: lName.isNotEmpty ? lName : (fullName.split(' ').length > 1 ? fullName.split(' ').last : ''),
      name: fullName,
      phone: phoneNum,
      photoUrl: data['photoUrl'] ??
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBSUEL7rzgOUfdodwwHNcQbn_MHokVlIecnYhN8TPN4KhvtW8M3TYZw1KPrm3UUYMfDPD-CyC6H4pnG_wuCRlbFOo0sHv6vRLEmIYBJTMFcxegdK9_q98JjiFSGeh6yTbJScbg111WeZv3X0Od_rjlCtLqLJWkOYc5ePgUjEra3ocWEwQrUEaX1TgYs2NEDlH1A4pxqtvMe0BMaKHD-3BH4qBOTfLnuZERSJxJPt7Kf2ghB4cM1e83C3w',
      emergencyContacts: eContacts,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': name,
      'name': name,
      'phoneNumber': phone,
      'phone': phone,
      'photoUrl': photoUrl,
      'emergency_contacts': emergencyContacts,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) {
    final fName = firstName ?? this.firstName;
    final lName = lastName ?? this.lastName;
    return UserModel(
      uid: uid,
      firstName: fName,
      lastName: lName,
      name: '$fName $lName'.trim(),
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
