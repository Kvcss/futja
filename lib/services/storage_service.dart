import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

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

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final taskSnapshot = await ref.putFile(file, metadata);
      final url = await taskSnapshot.ref.getDownloadURL();

      debugPrint(
        '[StorageService] uploadMatchImage OK | matchId=$matchId | url=$url',
      );

      return url;
    } on FirebaseException catch (e) {
      debugPrint(
        '[StorageService] uploadMatchImage FirebaseException | '
            'code=${e.code} | message=${e.message}',
      );

      throw Exception(
        'Não foi possível enviar a imagem da partida. Verifique o Firebase Storage e tente novamente.',
      );
    } catch (e) {
      debugPrint('[StorageService] uploadMatchImage erro inesperado | $e');

      throw Exception(
        'Erro inesperado ao enviar a imagem da partida.',
      );
    }
  }
}