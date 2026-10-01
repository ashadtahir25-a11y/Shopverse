import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';

const _adminRoles = [
  'admin',
  'manager',
  'order_manager',
  'product_manager',
  'support_staff',
];

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String avatarSeed;
  final String role;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.avatarSeed,
    this.role = 'customer',
  });

  bool get isAdminUser => _adminRoles.contains(role);

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
  }) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    avatarSeed: avatarSeed,
    role: role ?? this.role,
  );
}

/// This notifier's `state` is kept in sync with Firestore in real time —
/// it subscribes to `users/{uid}` and updates automatically whenever that
/// document changes, from *any* source (this app, the Firebase Console,
/// another device). This is what guarantees the app never drifts out of
/// sync with what's actually stored in Firebase: there is exactly one
/// source of truth (Firestore), and this provider mirrors it. It's also
/// how the app knows whether to show the Admin Dashboard entry point
/// (`profile.isAdminUser`) — see firebase/ADMIN_SETUP.md for how the
/// `role` field gets set.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  UserProfileNotifier()
    : super(
        const UserProfile(
          name: 'Guest',
          email: '',
          phone: '',
          avatarSeed: 'guest',
        ),
      ) {
    _listenToAuth();
  }

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) return;

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _profileSub?.cancel();

      if (user == null) {
        state = const UserProfile(
          name: 'Guest',
          email: '',
          phone: '',
          avatarSeed: 'guest',
        );
        return;
      }

      _profileSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            final data = doc.data();
            state = UserProfile(
              name: data?['fullName'] as String? ?? user.displayName ?? 'User',
              email: data?['email'] as String? ?? user.email ?? '',
              phone: data?['phone'] as String? ?? '',
              avatarUrl: data?['avatarUrl'] as String?,
              avatarSeed: user.uid,
              role: data?['role'] as String? ?? 'customer',
            );
          });
    });
  }

  /// Optimistic local update for instant UI feedback right after a
  /// register/login/save action — the Firestore listener above is the
  /// real source of truth and will reconcile shortly after (or
  /// immediately, if Firebase isn't configured yet — see
  /// firebase/FIREBASE_SETUP.md — in which case this IS the only state).
  void update({String? name, String? email, String? phone, String? avatarUrl}) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
      (ref) => UserProfileNotifier(),
    );
