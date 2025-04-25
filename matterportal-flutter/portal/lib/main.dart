import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:portal/models/project.dart';
import 'package:portal/screens/login/login_screen.dart';
import 'package:portal/screens/home/home_screen.dart';
import 'package:portal/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portal/firebase_options.dart';
import 'package:portal/widgets/project_card/product_builder/product_builder.dart';
import 'package:portal/widgets/common/loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portal/bloc/project/project_bloc.dart';
import 'package:portal/bloc/product/product_bloc.dart';
import 'package:portal/services/api_service.dart';
import 'package:portal/screens/home/project_view/responsive_project_view.dart';
import 'package:portal/services/audio_handler.dart';
import 'package:portal/services/audio_player_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:portal/constants/fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Only initialize audio service if not running on web
  if (!identical(0, 0.0)) { // This is a hack, replace with kIsWeb if available
    final AudioHandler audioHandler = await initAudioService();
    setAudioHandlerInstance(audioHandler);
  }
  runApp(const PortalApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        // ResponsiveProjectView will use Bloc to get project details
        return ResponsiveProjectView(
          project: Project(
            id: projectId,
            projectName: "",
            projectArtist: "",
            uid: projectId,
            notes: "",
          ),
          projectId: projectId,
          newProject: false,
        );
      },
    ),
    GoRoute(
      path: '/projects/:projectId/products/new',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        return ProductBuilder(
          selectedProductType: '', // Set via UI
          projectId: projectId,
          productId: '',
          isNewProduct: true,
        );
      },
    ),
    GoRoute(
      path: '/projects/:projectId/products/:productId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        final productId = state.pathParameters['productId']!;
        return ProductBuilder(
          selectedProductType: '', // Set via Bloc/UI
          projectId: projectId,
          productId: productId,
          isNewProduct: false,
        );
      },
    ),
  ],
  redirect: (context, state) {
    final user = AuthService.instance.currentUser;
    final loggingIn = state.uri.path == '/login';
    if (user == null) {
      return loggingIn ? null : '/login';
    }
    if (loggingIn) return '/home';
    return null;
  },
);

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProjectBloc(apiService: ApiService()),
        ),
        BlocProvider(
          create: (context) => ProductBloc(apiService: ApiService()),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'Portal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          cardColor: const Color(0xFF070709),
          useMaterial3: true,
          fontFamily: fontFamilyDefault,
          textTheme: ThemeData.light().textTheme.copyWith(
            displayLarge: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            displayMedium: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            displaySmall: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            headlineLarge: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            headlineMedium: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            headlineSmall: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            titleLarge: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            titleMedium: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            titleSmall: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            bodyLarge: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            bodyMedium: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            bodySmall: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            labelLarge: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            labelMedium: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
            labelSmall: const TextStyle(
              fontFamily: fontFamilyDefault,
              color: Colors.white,
            ),
          ),
          scaffoldBackgroundColor: Color(0xFF0C1014),
        ),
        builder: (context, child) => LoadingIndicatorOverlay(child: child!),
      ),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
