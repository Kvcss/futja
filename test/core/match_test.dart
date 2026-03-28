import 'package:flutter_test/flutter_test.dart';
import 'package:futja_app/models/match.dart';

void main() {
  group('Match', () {
    test('spotsLeft deve calcular corretamente', () {
      final match = Match(
        id: '1',
        title: 'Fut 7',
        city: 'Campinas',
        locationName: 'Quadra XPTO',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        level: 'intermediário',
        maxPlayers: 10,
        organizerId: 'organizer',
        participants: const ['a', 'b', 'c'],
      );

      expect(match.spotsLeft, 7);
    });

    test('isFull deve ser true quando não há vagas', () {
      final match = Match(
        id: '1',
        title: 'Fut 7',
        city: 'Campinas',
        locationName: 'Quadra XPTO',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        level: 'intermediário',
        maxPlayers: 2,
        organizerId: 'organizer',
        participants: const ['a', 'b'],
      );

      expect(match.isFull, true);
    });
  });
}