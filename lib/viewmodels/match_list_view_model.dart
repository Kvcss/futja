import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../services/match_service.dart';

class MatchListViewModel extends ChangeNotifier {
  final IMatchService matchService;

  List<Match> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCity;
  StreamSubscription<List<Match>>? _subscription;

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
    _subscription = matchService.watchMatches(city: _selectedCity).listen(
          (matches) {
        _matches = matches;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Erro ao carregar partidas.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setCity(String? city) {
    _selectedCity = city;
    _subscribe();
  }

  Future<void> joinMatch(String matchId, String userId) async {
    try {
      _errorMessage = null;
      await matchService.joinMatch(matchId: matchId, userId: userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      _errorMessage = null;
      await matchService.leaveMatch(matchId: matchId, userId: userId);
      notifyListeners();
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