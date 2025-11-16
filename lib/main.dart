// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'models/match_service.dart';
import 'models/storage_service.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_view_model.dart';

/// Handler para mensagens em BACKGROUND (quando o app está fechado/minimizado)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Opcional: logs de debug
  // ignore: avoid_print
  print(
    'BG MESSAGE -> title: ${message.notification?.title}, '
        'body: ${message.notification?.body}, data: ${message.data}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp();

  // Registra o handler de background (obrigatório antes do runApp)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  // Pede permissão pro usuário (iOS e Android 13+)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // iOS: mostrar notificação mesmo com app em foreground
  if (Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // (Opcional, mas útil pra debug) – ver o token no console
  final token = await messaging.getToken();
  // ignore: avoid_print
  print('FCM TOKEN ATUAL: $token');

  // Mensagem que abriu o app quando ele estava TERMINATED
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
      'APP ABERTO POR NOTIF (TERMINATED): '
          '${initialMessage.notification?.title} - '
          '${initialMessage.notification?.body} | data: ${initialMessage.data}',
    );
  }

  // Listener de mensagens com app em primeiro plano (foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
      'Mensagem em FOREGROUND: '
          '${message.notification?.title} - ${message.notification?.body} | '
          'data: ${message.data}',
    );

    // Aqui depois você pode mostrar um SnackBar ou dialog se quiser
    // usando um GlobalKey<NavigatorState> ou algo assim.
  });

  // Listener quando o usuário clica na notificação com app em background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Usuário clicou na notificação (BACKGROUND): ${message.data}');

    // Aqui dá pra navegar pra alguma tela com base em message.data['matchId']
    // por enquanto só vamos logar, pra não quebrar tua navegação atual.
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
      ],
      child: const MyApp(),
    ),
  );
}
