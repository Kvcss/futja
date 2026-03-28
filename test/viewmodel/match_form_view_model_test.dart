import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futja_app/models/match.dart';
import 'package:futja_app/models/match_service.dart';
import 'package:futja_app/models/storage_service.dart';
import 'package:futja_app/viewmodels/match_form_view_model.dart';

class FakeMatchService implements IMatchService {
  Match? createdMatch;

  @override
  Future<void> cancelMatch({
    required String matchId,
    required String organizerId,
  }) async {}

  @override
  Future<void> createMatch(Match match) async {
    createdMatch = match;
  }

  @override
  Future<void> joinMatch({
    required String matchId,
    required String userId,
  }) async {}

  @override
  Future<void> leaveMatch({
    required String matchId,
    required String userId,
  }) async {}

  @override
  String newMatchId() => 'match_123';

  @override
  Stream<List<Match>> watchMatches({String? city}) {
    return Stream.value([]);
  }
}

class FakeStorageService implements IStorageService {
  @override
  Future<String?> uploadMatchImage(String matchId, File file) async {
    return 'https://fake-url.com/$matchId.jpg';
  }
}

void main() {
  group('MatchFormViewModel', () {
    test('deve criar partida com sucesso', () async {
      final matchService = FakeMatchService();
      final storageService = FakeStorageService();

      final viewModel = MatchFormViewModel(
        matchService: matchService,
        storageService: storageService,
      );

      final result = await viewModel.createMatch(
        title: 'Fut de sábado',
        city: 'Campinas',
        locationName: 'Quadra A',
        dateTime: DateTime(2026, 3, 29, 10, 0),
        level: 'intermediário',
        maxPlayers: 10,
        organizerId: 'user_1',
        organizerName: 'kaio@email.com',
      );

      expect(result, true);
      expect(matchService.createdMatch, isNotNull);
      expect(matchService.createdMatch!.id, 'match_123');
      expect(matchService.createdMatch!.title, 'Fut de sábado');
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isSaving, false);
    });
  });
}