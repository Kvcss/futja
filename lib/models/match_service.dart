import 'package:cloud_firestore/cloud_firestore.dart';

import 'match.dart';

abstract class IMatchService {
  String newMatchId();

  Future<void> createMatch(Match match);

  Stream<List<Match>> watchMatches({
    String? city,
  });

  Future<void> joinMatch({
    required String matchId,
    required String userId,
  });

  Future<void> leaveMatch({
    required String matchId,
    required String userId,
  });

  Future<void> cancelMatch({
    required String matchId,
    required String organizerId,
  });
}

class MatchService implements IMatchService {
  final FirebaseFirestore _firestore;

  MatchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matchesRef =>
      _firestore.collection('matches');

  @override
  String newMatchId() {
    return _matchesRef.doc().id;
  }

  @override
  Future<void> createMatch(Match match) {
    return _matchesRef.doc(match.id).set(match.toMap());
  }

  @override
  Stream<List<Match>> watchMatches({
    String? city,
  }) {
    final now = DateTime.now();

    final query = _matchesRef
        .where(
      'dateTime',
      isGreaterThanOrEqualTo: Timestamp.fromDate(
        DateTime(now.year, now.month, now.day),
      ),
    )
        .orderBy('dateTime');

    return query.snapshots().map((snapshot) {
      final matches = snapshot.docs.map(Match.fromDocument).toList();

      return matches.where((match) {
        final matchesCity = city == null || city.isEmpty || match.city == city;
        final isActive = !match.cancelled;
        return matchesCity && isActive;
      }).toList();
    });
  }

  @override
  Future<void> joinMatch({
    required String matchId,
    required String userId,
  }) async {
    final docRef = _matchesRef.doc(matchId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final participants =
      (data['participants'] as List<dynamic>? ?? []).cast<String>();
      final maxPlayers = (data['maxPlayers'] as num?)?.toInt() ?? 10;

      if (participants.contains(userId)) {
        return;
      }

      if (participants.length >= maxPlayers) {
        throw Exception('Partida lotada.');
      }

      tx.update(docRef, {
        'participants': FieldValue.arrayUnion([userId]),
      });
    });
  }

  @override
  Future<void> leaveMatch({
    required String matchId,
    required String userId,
  }) async {
    await _matchesRef.doc(matchId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Future<void> cancelMatch({
    required String matchId,
    required String organizerId,
  }) async {
    final docRef = _matchesRef.doc(matchId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      if (data['organizerId'] != organizerId) {
        throw Exception('Apenas o organizador pode cancelar.');
      }

      tx.update(docRef, {
        'cancelled': true,
      });
    });
  }
}