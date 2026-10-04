import 'package:firebase_auth/firebase_auth.dart';

/// Changes the signed-in user's password. Firebase requires the user to
/// prove they know the CURRENT password first (re-authentication), which
/// is exactly the "enter old password" step — so a stolen, already
/// logged-in phone can't be used to silently take over the account.
Future<void> changeCurrentUserPassword({
  required String oldPassword,
  required String newPassword,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email;
  if (user == null || email == null) {
    throw FirebaseAuthException(code: 'no-current-user');
  }
  await user.reauthenticateWithCredential(
    EmailAuthProvider.credential(email: email, password: oldPassword),
  );
  await user.updatePassword(newPassword);
}

/// Firebase error codes -> messages a person can act on.
String friendlyPasswordError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password (at least 8 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'requires-recent-login':
        return 'For security, please log out, log in again, and retry.';
    }
  }
  return 'Could not change the password. Please try again.';
}
