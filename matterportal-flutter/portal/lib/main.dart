import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:portal/Screens/Login/login_screen.dart';
import 'package:portal/Screens/Home/home_screen.dart';
import 'firebase_options.dart';
import 'package:just_audio_background/just_audio_background.dart';
//import 'package:portal/Services/audio_player_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portal/Screens/Login/forgot_password_screen.dart';
//import 'package:portal/Services/api_service.dart';
import 'package:portal/constants/fonts.dart';
import 'package:provider/provider.dart';
import 'package:portal/Services/theme_provider.dart';
import 'package:portal/Models/project.dart';

// Global flag to control the visibility of the Under Construction overlay
bool showUnderConstructionOverlay = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await JustAudioBackground.init(
    androidNotificationChannelId: 'lat.matter.portal.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider<Project>(
          create: (context) => Project(id: 'default'),
        ),
      ],
      child: const PortalApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loggingIn = state.fullPath == '/login';
    final forgotPassword = state.fullPath == '/forgot-password';
    if (user == null) {
      return (loggingIn || forgotPassword) ? null : '/login';
    }
    if (loggingIn || forgotPassword) return '/home';
    return null;
  },
);

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BlackMatter Portal',
      theme: ThemeData(
        cardColor: const Color(0xFF070709),
        useMaterial3: true,
        fontFamily: fontNameBold,
        textTheme: ThemeData.light().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          displayMedium: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          displaySmall: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          headlineLarge: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          headlineMedium: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          headlineSmall: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          titleLarge: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          titleMedium: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          titleSmall: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          bodyMedium: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          bodySmall: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          labelLarge: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          labelMedium: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
          labelSmall: const TextStyle(
            fontFamily: fontNameBold,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF0C1014),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => LoadingIndicatorOverlay(child: child!),
    );
  }
}

class LoadingIndicatorOverlay extends StatelessWidget {
  final Widget child;
  const LoadingIndicatorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // TODO: Optionally show global loading overlay using Bloc
    return child;
  }
}
