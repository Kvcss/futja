import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:futja_app/models/match.dart';
import 'package:futja_app/services/match_service.dart';
import 'package:futja_app/viewmodels/match_list_view_model.dart';

class FakeMatchListService implements IMatchService {
  final controller = StreamController<List<Match>>.broadcast();
  String? lastRequestedCity;

  @override
  Future<void> cancelMatch({
    required String matchId,
    required String organizerId,
  }) async {}

  @override
  Future<void> createMatch(Match match) async {}

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
  String newMatchId() => 'id';

  @override
  Stream<List<Match>> watchMatches({String? city}) {
    lastRequestedCity = city;
    return controller.stream;
  }
}

void main() {
  group('MatchListViewModel', () {
    test('deve carregar partidas recebidas do serviço', () async {
      final service = FakeMatchListService();
      final viewModel = MatchListViewModel(
        matchService: service,
        initialCity: 'São Paulo',
      );

      service.controller.add([
        Match(
          id: '1',
          title: 'Fut de domingo',
          city: 'São Paulo',
          locationName: 'Quadra B',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          level: 'intermediário',
          maxPlayers: 10,
          organizerId: 'org_1',
          participants: const [],
        ),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.lastRequestedCity, 'São Paulo');
      expect(viewModel.matches.length, 1);
      expect(viewModel.isLoading, false);

      await service.controller.close();
      viewModel.dispose();
    });
  });
}