import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../models/match_service.dart';
import '../models/storage_service.dart';

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

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await storageService.uploadMatchImage(matchId, imageFile);
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
        imageUrl: imageUrl,
        participants: const [],
      );

      await matchService.createMatch(match);

      return true;
    } catch (_) {
      _errorMessage = 'Erro ao criar partida. Tente novamente.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}