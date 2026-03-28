import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_profile.dart';

abstract class IProfileService {
  Future<UserProfile?> getProfile(String uid);

  Future<UserProfile> updateProfile({
    required String uid,
    String? displayName,
    String? position,
    int? age,
    double? weight,
    File? photoFile,
  });

  Future<List<UserProfile>> getProfilesForUids(List<String> uids);
}

class ProfileService implements IProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDocument(doc);
  }

  @override
  Future<UserProfile> updateProfile({
    required String uid,
    String? displayName,
    String? position,
    int? age,
    double? weight,
    File? photoFile,
  }) async {
    String? photoUrl;

    if (photoFile != null) {
      final ref = _storage.ref().child('users').child(uid).child('avatar.jpg');
      await ref.putFile(photoFile);
      photoUrl = await ref.getDownloadURL();
    }

    final data = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
      if (position != null && position.isNotEmpty) 'position': position,
      'age': age,
      'weight': weight,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));

    final updated = await _usersRef.doc(uid).get();
    return UserProfile.fromDocument(updated);
  }

  @override
  Future<List<UserProfile>> getProfilesForUids(List<String> uids) async {
    if (uids.isEmpty) return [];

    final futures = uids.map((uid) => _usersRef.doc(uid).get());
    final docs = await Future.wait(futures);

    return docs
        .where((doc) => doc.exists)
        .map(UserProfile.fromDocument)
        .toList();
  }
}