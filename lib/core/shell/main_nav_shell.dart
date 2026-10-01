import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../features/home/home_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/cart/providers/cart_provider.dart';

/// Bottom-nav shell per PRD Section 61: Home | Categories | Wishlist | Cart | Profile.
/// Uses IndexedStack so each tab keeps its scroll position / state when switching.
class MainNavShell extends ConsumerStatefulWidget {
  const MainNavShell({super.key});

  @override
  ConsumerState<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends ConsumerState<MainNavShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CategoriesScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view_rounded), label: 'Categories'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), activeIcon: Icon(Icons.favorite_rounded), label: 'Wishlist'),
          BottomNavigationBarItem(
            icon: badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 9)),
              badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: const Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
