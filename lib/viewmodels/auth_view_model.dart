import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_error_mapper.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final IAuthService authService;

  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthViewModel({
    required this.authService,
  }) {
    _authSubscription = authService.authStateChanges.listen((firebaseUser) {
      _handleAuthStateChanged(firebaseUser);
    });
  }

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      _user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
      );
      await authService.saveFcmToken(firebaseUser.uid);
    } else {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final firebaseUser = await authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (firebaseUser != null) {
        _user = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
        );
        await authService.saveFcmToken(firebaseUser.uid);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthErrorMapper.map(e.code);
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

      final firebaseUser = await authService.registerWithEmailAndPassword(
        email,
        password,
      );

      if (firebaseUser != null) {
        _user = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
        );
        await authService.saveFcmToken(firebaseUser.uid);
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthErrorMapper.map(e.code);
    } catch (_) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _errorMessage = null;
    await authService.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}