import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService authService;

  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthViewModel({required this.authService}) {
    _authSubscription =
        authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onAuthStateChanged(User? firebaseUser) {
    _user = firebaseUser != null
        ? AppUser(uid: firebaseUser.uid, email: firebaseUser.email)
        : null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final firebaseUser =
      await authService.signInWithEmailAndPassword(email, password);

      if (firebaseUser != null) {
        _user = AppUser(uid: firebaseUser.uid, email: firebaseUser.email);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapErrorCodeToMessage(e.code);
    } catch (_) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final firebaseUser =
      await authService.registerWithEmailAndPassword(email, password);

      if (firebaseUser != null) {
        _user = AppUser(uid: firebaseUser.uid, email: firebaseUser.email);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapErrorCodeToMessage(e.code);
    } catch (_) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authService.signOut();
  }

  String _mapErrorCodeToMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Usuário desativado.';
      case 'email-already-in-use':
        return 'Já existe uma conta com esse e-mail.';
      case 'weak-password':
        return 'Senha muito fraca.';
      default:
        return 'Falha na autenticação. Tente novamente.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
