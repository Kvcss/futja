import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String?> uploadMatchImage(String matchId, File file) async {
    try {
      final ref = _storage.ref().child('matches').child('$matchId.jpg');
      await ref.putFile(file);

      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      return null;
    }
  }
}
