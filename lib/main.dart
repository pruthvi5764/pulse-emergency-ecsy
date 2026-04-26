import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:lifeline_nexus/features/auth/login_screen.dart';
import 'package:lifeline_nexus/features/home/home_screen.dart';
import 'package:lifeline_nexus/services/auth_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized before any platform calls (T-07)
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: .env removed from pubspec assets (security fix).
  // API keys are now injected via --dart-define-from-file at build time.
  // dotenv.load() call removed — use AppConstants / ApiKeys class with fromEnvironment.

  bool firebaseReady = false;
  String? initError;

  try {
    // Initialize Firebase (T-07)
    await Firebase.initializeApp();

    // T-76: App Check MUST activate before any Firebase service is called
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );

    // Initialize Google Sign-In singleton INSIDE the try block —
    // it depends on a successfully initialized Firebase instance.
    await AuthService.initializeGoogleSignIn();

    firebaseReady = true;
  } catch (e, stack) {
    initError = e.toString();
    // Log full stack in debug — never show raw error to end user in production
    debugPrint('[FATAL] Firebase initialization failed: $e\n$stack');
  }

  runApp(
    // ProviderScope stores the state of all Riverpod providers (T-07)
    ProviderScope(
      child: firebaseReady
          ? const LifelineNexusApp()
          : FatalErrorApp(error: initError ?? 'Unknown initialization error'),
    ),
  );
}

/// Root application widget — only mounted when Firebase is confirmed ready.
class LifelineNexusApp extends ConsumerWidget {
  const LifelineNexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PULSE',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: authState.when(
        data: (user) {
          return user == null ? const LoginScreen() : const HomeScreen();
        },
        loading: () => const LoadingScreen(),
        error: (err, stack) {
          debugPrint('[AUTH ERROR] $err\n$stack');
          return ErrorScreen(
            message: 'Authentication service error:\n$err',
          );
        },
      ),
    );
  }
}

class FatalErrorApp extends StatelessWidget {
  final String error;
  const FatalErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connection Failed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Check your internet connection and restart Pulse.',
                    style: TextStyle(fontSize: 15, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  if (!const bool.fromEnvironment('dart.vm.product'))
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '[DEBUG] $error',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 32),
            Text(
              'PULSE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.white24),
              const SizedBox(height: 24),
              const Text(
                'Access Error',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                message, 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
