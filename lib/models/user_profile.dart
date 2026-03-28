import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? position;
  final int? age;
  final double? weight;
  final String? photoUrl;
  final String? photoBase64;
  final String? email;

  UserProfile({
    required this.uid,
    this.displayName,
    this.position,
    this.age,
    this.weight,
    this.photoUrl,
    this.photoBase64,
    this.email,
  });

  String get displayLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }

    if (email != null && email!.trim().isNotEmpty) {
      return email!.split('@').first;
    }

    return 'Jogador';
  }

  factory UserProfile.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      position: data['position'] as String?,
      age: (data['age'] as num?)?.toInt(),
      weight: (data['weight'] as num?)?.toDouble(),
      photoUrl: data['photoUrl'] as String?,
      photoBase64: data['photoBase64'] as String?,
      email: data['email'] as String?,
    );
  }
}