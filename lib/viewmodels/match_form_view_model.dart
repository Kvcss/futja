import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../services/match_service.dart';
import '../services/storage_service.dart';

class MatchFormViewModel extends ChangeNotifier {
  final IMatchService matchService;

  final IStorageService storageService;

  bool _isSaving = false;
  String? _errorMessage;

  MatchFormViewModel({
    required this.matchService,
    required this.storageService,
  });

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<bool> createMatch({
    required String title,
    required String city,
    required String locationName,
    required DateTime dateTime,
    required String level,
    required int maxPlayers,
    required String organizerId,
    String? organizerName,
    File? imageFile,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final matchId = matchService.newMatchId();

      String? imageBase64;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();

        // Limite de segurança para não estourar o documento do Firestore.
        if (bytes.length > 450 * 1024) {
          throw Exception(
            'A imagem ficou muito grande. Escolha uma imagem menor.',
          );
        }

        imageBase64 = base64Encode(bytes);
      }

      final match = Match(
        id: matchId,
        title: title,
        city: city,
        locationName: locationName,
        dateTime: dateTime,
        level: level,
        maxPlayers: maxPlayers,
        organizerId: organizerId,
        organizerName: organizerName,
        imageUrl: null,
        imageBase64: imageBase64,
        participants: const [],
      );

      await matchService.createMatch(match);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (_errorMessage == null || _errorMessage!.trim().isEmpty) {
        _errorMessage = 'Erro ao criar partida. Tente novamente.';
      }
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}