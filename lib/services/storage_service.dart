import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

abstract class IStorageService {
  Future<String?> uploadMatchImage(String matchId, File file);
}

class StorageService implements IStorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String?> uploadMatchImage(String matchId, File file) async {
    try {
      final ref = _storage.ref().child('matches').child('$matchId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } on FirebaseException {
      return null;
    }
  }
}