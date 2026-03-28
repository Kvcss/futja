import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? position;
  final int? age;
  final double? weight;
  final String? photoUrl;
  final String? email;

  UserProfile({
    required this.uid,
    this.displayName,
    this.position,
    this.age,
    this.weight,
    this.photoUrl,
    this.email,
  });

  factory UserProfile.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      position: data['position'] as String?,
      age: (data['age'] as num?)?.toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      photoUrl: data['photoUrl'] as String?,
      email: data['email'] as String?,
    );
  }
}