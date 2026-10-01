import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/firebase_config.dart';
import '../models/address_model.dart';

/// Manages the customer's saved addresses, synced with Firestore
/// (`addresses/{id}`, filtered by `userId`) — same auth-listening pattern
/// as Cart/Wishlist/Orders. Previously this was in-memory only, so saved
/// addresses vanished every time the app restarted, forcing the address
/// to be re-typed on every order.
class AddressNotifier extends StateNotifier<List<Address>> {
  AddressNotifier() : super([]) {
    _listenToAuth();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _addressSub;
  String? _uid;

  void _listenToAuth() {
    if (!FirebaseStatus.isInitialized) {
      return;
    }
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _addressSub?.cancel();
      _uid = user?.uid;

      if (user == null) {
        state = [];
        return;
      }

      _addressSub = FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            state = snapshot.docs
                .map((doc) => Address.fromFirestore(doc.id, doc.data()))
                .toList();
          });
    });
  }

  Future<void> add(Address address) async {
    final makeDefault = state.isEmpty || address.isDefault;

    if (makeDefault) {
      // Unset the previous default locally (optimistic) — Firestore
      // writes below reconcile this properly for every address.
      state = [
        for (final a in state)
          a.isDefault
              ? Address(
                  id: a.id,
                  fullName: a.fullName,
                  phone: a.phone,
                  addressLine: a.addressLine,
                  city: a.city,
                  area: a.area,
                  postalCode: a.postalCode,
                  instructions: a.instructions,
                  label: a.label,
                  isDefault: false,
                )
              : a,
      ];
    }

    final finalAddress = (address.isDefault || makeDefault)
        ? Address(
            id: address.id,
            fullName: address.fullName,
            phone: address.phone,
            addressLine: address.addressLine,
            city: address.city,
            area: address.area,
            postalCode: address.postalCode,
            instructions: address.instructions,
            label: address.label,
            isDefault: true,
          )
        : address;

    state = [...state, finalAddress];

    if (!FirebaseStatus.isInitialized || _uid == null) {
      return;
    }
    try {
      final batch = FirebaseFirestore.instance.batch();
      if (makeDefault) {
        for (final a in state) {
          if (a.id != finalAddress.id) {
            batch.update(
              FirebaseFirestore.instance.collection('addresses').doc(a.id),
              {'isDefault': false},
            );
          }
        }
      }
      batch.set(
        FirebaseFirestore.instance.collection('addresses').doc(finalAddress.id),
        finalAddress.toFirestoreMap(_uid!),
      );
      await batch.commit();
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    state = state.where((a) => a.id != id).toList();
    if (!FirebaseStatus.isInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('addresses').doc(id).delete();
    } catch (_) {}
  }

  void clear() {
    state = [];
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _addressSub?.cancel();
    super.dispose();
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, List<Address>>(
  (ref) => AddressNotifier(),
);

/// Currently selected address for checkout (separate from "default" —
/// the user can pick any saved address at checkout time).
final selectedAddressIdProvider = StateProvider<String?>((ref) => null);
