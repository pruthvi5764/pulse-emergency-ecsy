import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Typed result for sign-in — avoids null-as-error ambiguity in the UI.
enum AuthFailureReason {
  cancelled,
  networkError,
  credentialError,
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  userNotFound,
  wrongPassword,
  unknown
}

class AuthResult {
  final UserCredential? credential;
  final AuthFailureReason? failureReason;
  final String? errorMessage;

  bool get isSuccess => credential != null;

  const AuthResult.success(this.credential)
      : failureReason = null,
        errorMessage = null;

  const AuthResult.failure(this.failureReason, this.errorMessage)
      : credential = null;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Called once at app startup from main.dart.
  static Future<void> initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize();
  }

  /// Sign in with Email and Password.
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(userCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Email Sign-In Error: ${e.code}');
      final reason = switch (e.code) {
        'user-not-found' => AuthFailureReason.userNotFound,
        'wrong-password' => AuthFailureReason.wrongPassword,
        'invalid-email' => AuthFailureReason.invalidEmail,
        'network-request-failed' => AuthFailureReason.networkError,
        _ => AuthFailureReason.credentialError,
      };
      return AuthResult.failure(reason, e.message);
    } catch (e) {
      return AuthResult.failure(AuthFailureReason.unknown, e.toString());
    }
  }

  /// Create Account with Email and Password.
  Future<AuthResult> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(userCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Email Sign-Up Error: ${e.code}');
      final reason = switch (e.code) {
        'email-already-in-use' => AuthFailureReason.emailAlreadyInUse,
        'invalid-email' => AuthFailureReason.invalidEmail,
        'weak-password' => AuthFailureReason.weakPassword,
        'network-request-failed' => AuthFailureReason.networkError,
        _ => AuthFailureReason.credentialError,
      };
      return AuthResult.failure(reason, e.message);
    } catch (e) {
      return AuthResult.failure(AuthFailureReason.unknown, e.toString());
    }
  }

  /// Sign in Anonymously (Emergency Bypass).
  Future<AuthResult> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return AuthResult.success(userCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] Anonymous Sign-In Error: ${e.code}');
      return AuthResult.failure(AuthFailureReason.credentialError, e.message);
    } catch (e) {
      return AuthResult.failure(AuthFailureReason.unknown, e.toString());
    }
  }

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return const AuthResult.failure(AuthFailureReason.cancelled, 'Sign-in cancelled.');
      }
      return AuthResult.failure(AuthFailureReason.credentialError, e.message);
    } on FirebaseAuthException catch (e) {
      final reason = e.code == 'network-request-failed'
          ? AuthFailureReason.networkError
          : AuthFailureReason.credentialError;
      return AuthResult.failure(reason, e.message);
    } catch (e) {
      return AuthResult.failure(AuthFailureReason.unknown, e.toString());
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[AUTH] Sign-out error: $e');
      rethrow;
    }
  }
}
