import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;

  Future<User?> signInWithEmailAndPassword(String email, String password);

  Future<User?> registerWithEmailAndPassword(String email, String password);

  Future<void> signOut();

  Future<void> saveFcmToken(String uid);
}

class AuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  @override
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> saveFcmToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }
}