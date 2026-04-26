import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeline_nexus/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Singleton provider for AuthService.
/// keepAlive: true ensures it is never disposed mid-session by Riverpod.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(() {
    // AuthService holds no disposable resources directly;
    // Firebase streams are managed by the SDK. Placeholder for future cleanup.
    debugPrint('[AuthService] provider disposed.');
  });
  return service;
}, dependencies: []);

/// StreamProvider that emits the current Firebase auth state (T-13).
/// Consumed in main.dart to drive LoginScreen ↔ HomeScreen routing (T-15).
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
}, dependencies: [authServiceProvider]);
