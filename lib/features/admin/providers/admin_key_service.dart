import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The admin's personal key — an extra "are you really the admin?" step
/// in front of the password-change form.
///
/// * Stored as a salted, repeatedly-hashed digest in `adminKeys/{uid}` —
///   the key itself is never saved anywhere.
/// * Set once. The Firestore rule allows `create` but never `update` or
///   `delete`, so the app (or anyone who steals a logged-in session)
///   cannot replace it. Only the Firebase Console owner can.
///
/// Honest limit: the comparison happens in the app, so this is a second
/// gate on top of — not a replacement for — Firebase's own check of the
/// old password, which still happens when the password is changed.
class AdminKeyService {
  static const _rounds = 4000;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('adminKeys').doc(uid);
  }

  Future<bool> hasKey() async {
    final doc = _doc;
    if (doc == null) return false;
    return (await doc.get()).exists;
  }

  String _hash(String key, List<int> salt) {
    var digest = sha256.convert([...salt, ...utf8.encode(key)]).bytes;
    for (var i = 0; i < _rounds; i++) {
      digest = sha256.convert([...digest, ...salt]).bytes;
    }
    return base64Encode(digest);
  }

  /// Saves the key for the first time. Fails (rules) if one already exists.
  Future<void> setKey(String key) async {
    final doc = _doc;
    if (doc == null) throw StateError('Not signed in');
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    await doc.set({
      'salt': base64Encode(salt),
      'hash': _hash(key, salt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> verify(String key) async {
    final doc = _doc;
    if (doc == null) return false;
    final data = (await doc.get()).data();
    if (data == null) return false;
    final salt = base64Decode(data['salt'] as String);
    final expected = data['hash'] as String;
    final actual = _hash(key, salt);
    // Constant-time comparison.
    if (expected.length != actual.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ actual.codeUnitAt(i);
    }
    return diff == 0;
  }
}

final adminKeyService = AdminKeyService();
