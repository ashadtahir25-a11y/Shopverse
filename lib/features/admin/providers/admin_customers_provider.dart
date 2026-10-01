import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available roles a customer's account can be assigned. `customer` is
/// the default for every new signup; the rest grant Admin Dashboard
/// access (see AdminGuard + firestore.rules `isAdmin()`).
const kAvailableRoles = [
  'customer',
  'support_staff',
  'product_manager',
  'order_manager',
  'manager',
  'admin',
];

class AdminCustomer {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isBlocked;
  final String? avatarUrl;
  final DateTime? createdAt;

  const AdminCustomer({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isBlocked,
    this.avatarUrl,
    this.createdAt,
  });

  bool get isStaff => role != 'customer';

  factory AdminCustomer.fromFirestore(String uid, Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) createdAt = createdAtRaw.toDate();

    return AdminCustomer(
      uid: uid,
      name: data['fullName'] as String? ?? 'Unnamed',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      isBlocked: data['isBlocked'] as bool? ?? false,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: createdAt,
    );
  }
}

/// Streams every registered user for the Admin Dashboard's Customers
/// screen. Unlike `userProfileProvider` (which tracks only the currently
/// signed-in user), this covers everyone.
final adminCustomersProvider = StreamProvider.autoDispose<List<AdminCustomer>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => AdminCustomer.fromFirestore(doc.id, doc.data()))
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
      );
});

/// Admin write operations on customer accounts. Firestore Rules
/// independently enforce that only admin-role users can actually change
/// another user's `role`/`isBlocked` fields (see firebase/firestore.rules
/// — regular users can update their own profile but not those two fields).
class AdminCustomersService {
  final _db = FirebaseFirestore.instance;

  Future<void> setBlocked(String uid, bool isBlocked) async {
    await _db.collection('users').doc(uid).update({'isBlocked': isBlocked});
  }

  Future<void> setRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
}

final adminCustomersService = AdminCustomersService();
