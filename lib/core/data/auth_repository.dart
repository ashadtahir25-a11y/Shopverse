import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/firebase_config.dart';

/// Thin wrapper around Firebase Auth (PRD §5: Registration, Login,
/// Forgot Password). Screens call these methods instead of talking to
/// Firebase directly, so the auth layer can be swapped/extended (social
/// login, phone auth, etc.) without touching UI code.
class AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  void _requireFirebase() {
    if (!FirebaseStatus.isInitialized) {
      throw StateError(
        'Firebase is not set up yet. Run `flutterfire configure` — see firebase/FIREBASE_SETUP.md',
      );
    }
  }

  /// Registers a new user with email/password, then creates the matching
  /// `users/{uid}` profile document (Firestore doesn't have a database
  /// trigger for this out of the box, so we do it explicitly here).
  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _requireFirebase();
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(fullName);

    // Verify the address right away (best effort — never blocks sign-up). A
    // verified e-mail is what lets Firebase approve a later e-mail change.
    try {
      await credential.user?.sendEmailVerification();
    } catch (_) {}

    await _db.collection('users').doc(credential.user!.uid).set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': null,
      'role': 'customer',
      'isBlocked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> login({required String email, required String password}) async {
    _requireFirebase();
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    if (!FirebaseStatus.isInitialized) return;
    await _auth.signOut();
    // The next login/registration starts from the default
    // ("remember me" on) instead of inheriting this session's choice.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
  }

  /// Sends a password-reset email (Firebase's built-in flow).
  Future<void> sendPasswordResetEmail(String email) async {
    _requireFirebase();
    await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => FirebaseStatus.isInitialized ? _auth.currentUser : null;

  bool get isLoggedIn => currentUser != null;

  Stream<User?>? get authStateChanges => FirebaseStatus.isInitialized ? _auth.authStateChanges() : null;
}

final authRepository = AuthRepository();
