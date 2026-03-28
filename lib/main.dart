import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/match_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'viewmodels/auth_view_model.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    'BG MESSAGE -> title: ${message.notification?.title}, '
        'body: ${message.notification?.body}, data: ${message.data}',
  );
}

Future<void> _configureFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (Platform.isIOS) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
      'APP ABERTO POR NOTIF (TERMINATED): '
          '${initialMessage.notification?.title} - '
          '${initialMessage.notification?.body} | data: ${initialMessage.data}',
    );
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
      'Mensagem em FOREGROUND: '
          '${message.notification?.title} - ${message.notification?.body} | '
          'data: ${message.data}',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Usuário clicou na notificação (BACKGROUND): ${message.data}');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _configureFirebaseMessaging();

  runApp(
    MultiProvider(
      providers: [
        Provider<IAuthService>(
          create: (_) => AuthService(),
        ),
        Provider<IMatchService>(
          create: (_) => MatchService(),
        ),
        Provider<IStorageService>(
          create: (_) => StorageService(),
        ),
        Provider<IProfileService>(
          create: (_) => ProfileService(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<IAuthService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}