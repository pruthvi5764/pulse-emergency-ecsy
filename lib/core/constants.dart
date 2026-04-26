import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'PULSE';
  static const String appVersion = '1.0.0';

  // Cloud Function base URL — injected at build time via --dart-define
  // Example: flutter build appbundle --dart-define=CLOUD_FUNCTIONS_URL=https://us-central1-YOUR_ID.cloudfunctions.net
  static const String cloudFunctionsBaseUrl = String.fromEnvironment(
    'CLOUD_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net',
  );

  // Storage Buckets
  static const String evidenceBucket = 'lifeline-nexus-evidence';

  // Timeout values
  static const int sosRecognitionTimeoutSeconds = 5;
  static const int gpsUpdateIntervalSeconds = 10;

  // Feature Toggles — controlled at compile time, NOT by code change
  // Usage: flutter run --dart-define=USE_MOCK=true
  static const bool useMockServices = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );
}

class ApiKeys {
  // API keys are injected via --dart-define-from-file at build time.
  // They are NOT loaded from .env at runtime (which bundles the file into the APK).
  // Build command: flutter build appbundle --dart-define-from-file=dart_defines.json
  //
  // dart_defines.json (gitignored):
  // {
  //   "GOOGLE_MAPS_KEY": "your_maps_key",
  //   "GEMINI_API_KEY": "your_gemini_key"
  // }

  static const String googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_KEY');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Call this once at startup (after main()) to validate keys are present.
  static void assertKeysPresent() {
    if (googleMapsKey.isEmpty) {
      // In debug: throw loudly so dev is immediately aware
      assert(false, '[FATAL] GOOGLE_MAPS_KEY is not set. Run with --dart-define-from-file=dart_defines.json');
      // In release: log silently — do not crash the app on key validation
      debugPrint('[WARNING] GOOGLE_MAPS_KEY is missing. Maps features will not function.');
    }
    if (geminiApiKey.isEmpty) {
      assert(false, '[FATAL] GEMINI_API_KEY is not set. Run with --dart-define-from-file=dart_defines.json');
      debugPrint('[WARNING] GEMINI_API_KEY is missing. Direct AI calls will not function.');
    }
  }
}

class AppStrings {
  static const String sosTriggerPhrase = "Emergency help me";
  static const String welcomeMessage = "System Initialized. Stay Calm.";
}
