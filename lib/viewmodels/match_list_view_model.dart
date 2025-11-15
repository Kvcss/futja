import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match.dart';
import '../models/match_service.dart';


class MatchListViewModel extends ChangeNotifier {
  final MatchService matchService;

  List<Match> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCity;
  StreamSubscription<List<QueryDocumentSnapshot<Map<String, dynamic>>>>?
  _subscription;

  MatchListViewModel({
    required this.matchService,
    String? initialCity,
  }) : _selectedCity = initialCity {
    _subscribe();
  }

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCity => _selectedCity;

  void _subscribe() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = matchService
        .watchMatchDocs(city: _selectedCity)
        .listen((docs) {
      _matches = docs.map((doc) => Match.fromDocument(doc)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Erro ao carregar partidas.';
      _isLoading = false;
      notifyListeners();
    });
  }

  void setCity(String? city) {
    _selectedCity = city;
    _subscribe();
  }

  Future<void> joinMatch(String matchId, String userId) async {
    try {
      await matchService.joinMatch(matchId: matchId, userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      await matchService.leaveMatch(matchId: matchId, userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
