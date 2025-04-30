import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:prosmart/config/theme/scale_theme.dart';
import 'package:prosmart/rota/rota.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';
import 'dart:io' show Platform;

import 'firebase_options.dart';

// Özel router provider
final routerProvider = Provider<GoRouter>((ref) {
  return AppRoutes.createRouter(ref);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Oturum kalıcılığı ayarları
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } else if (Platform.isAndroid || Platform.isIOS) {
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  }

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(currentUser.uid)
            .get();

        if (userData.exists) {
          final durum = userData.data()?['durum'];

          switch (durum) {
            case 'onayBekliyor':
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.pendingApproval;
              break;
            case 'onaylandi':
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.authenticated;
              break;
            case 'reddedildi':
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.rejected;
              break;
            default:
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.pendingApproval;
          }
        }
      } catch (e) {
        print('Kullanıcı durumu kontrol edilirken hata: $e');
      }
    }

    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Router'ı ref üzerinden al
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ProSmart',
      theme: ScaleTheme.theme(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      // GoRouter kullanımı
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
