import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  final FirebaseFirestore _firestore;

  MatchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matchesRef =>
      _firestore.collection('matches');

  /// Gera um novo id de partida (sem gravar ainda)
  String newMatchId() {
    return _matchesRef.doc().id;
  }

  /// Cria partida já com id definido
  Future<void> createMatchWithId(Map<String, dynamic> data, String matchId) {
    return _matchesRef.doc(matchId).set(data);
  }

  /// Stream de partidas, filtrando por cidade (se informado) e só futuras/não canceladas
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchMatchDocs({
    String? city,
  }) {
    final now = DateTime.now();

    Query<Map<String, dynamic>> query = _matchesRef
        .where(
      'dateTime',
      isGreaterThanOrEqualTo:
      Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
    )
        .where('cancelled', isEqualTo: false)
        .orderBy('dateTime');

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

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
        return; // já está
      }

      if (participants.length >= maxPlayers) {
        throw Exception('Partida lotada.');
      }

      tx.update(docRef, {
        'participants': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> leaveMatch({
    required String matchId,
    required String userId,
  }) async {
    await _matchesRef.doc(matchId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

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
