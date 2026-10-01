/// Tells the rest of the app whether Firebase has actually been wired up
/// yet (i.e. whether `flutterfire configure` has been run — see
/// firebase/FIREBASE_SETUP.md). Until then, every screen keeps working on
/// local/mock state so nothing breaks mid-development.
class FirebaseStatus {
  FirebaseStatus._();

  /// Flipped to true in main.dart after Firebase.initializeApp() succeeds.
  static bool isInitialized = false;
}
