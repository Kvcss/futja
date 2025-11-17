// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:futja_app/services/profile_service.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'models/match_service.dart';
import 'models/storage_service.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_view_model.dart';

/// Handler para mensagens em BACKGROUND (quando o app está fechado/minimizado)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    'BG MESSAGE -> title: ${message.notification?.title}, '
        'body: ${message.notification?.body}, data: ${message.data}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  final token = await messaging.getToken();
  print('FCM TOKEN ATUAL: $token');

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

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
          ),
        ),
        Provider<MatchService>(
          create: (_) => MatchService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
