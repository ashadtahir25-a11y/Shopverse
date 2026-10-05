import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_flow.dart';
import '../../core/config/firebase_config.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_background.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/providers/user_profile_provider.dart';

const _kOnboardingSeenKey = 'onboarding_seen';
const _kRememberMeKey = 'remember_me';

/// Minimum time the splash stays on screen, so the logo animation can
/// finish even when the session check completes instantly.
const _kMinSplash = Duration(milliseconds: 1800);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // A slow, continuous breathing glow behind the logo — the kind of
    // subtle, non-distracting motion that makes a splash screen feel
    // alive rather than just a static image on a timer.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bootstrap();
  }

  /// Decides where to go next. The session check and the minimum splash
  /// time run side by side, so the splash never lasts longer than it
  /// has to — and it can never get stuck: every failure path falls
  /// through to a sensible screen instead of hanging here.
  Future<void> _bootstrap() async {
    final minSplash = Future<void>.delayed(_kMinSplash);
    // Load the saved currency + cached exchange rates now, so the first
    // prices on Home already appear in the right currency.
    ref.read(currencyProvider);

    var destination = AppRoutes.login;
    String? notice;
    try {
      final result = await _resolveDestination();
      destination = result.route;
      notice = result.notice;
    } catch (_) {
      // Anything unexpected -> fall back to the login screen.
    }

    await minSplash;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    context.go(destination);
    if (notice != null) {
      messenger.showSnackBar(SnackBar(content: Text(notice)));
    }
  }

  Future<({String route, String? notice})> _resolveDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(_kOnboardingSeenKey) ?? false;
    // Defaults to true so existing sessions keep working; only an
    // explicit "Remember me" untick on the login screen turns it off.
    final rememberMe = prefs.getBool(_kRememberMeKey) ?? true;

    if (FirebaseStatus.isInitialized) {
      // Firebase Auth stores the session on the device by itself. On
      // mobile `currentUser` is normally ready straight away; the stream
      // read is a safety net for platforms that restore it a moment
      // later. (The old code looked for an "auth_token" preference that
      // nothing ever saved — so every launch ended up on Login.)
      var user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (user != null) {
        // If the person tapped the verification link from Settings -> Change
        // Email, only a refresh tells this device about the new address.
        // (A separate non-null variable keeps Dart's null-safety happy.)
        User current = user;
        try {
          await current.reload().timeout(const Duration(seconds: 3));
          current = FirebaseAuth.instance.currentUser ?? current;
        } catch (_) {}
        if (!rememberMe) {
          await FirebaseAuth.instance.signOut();
          // Reset so a stale `false` can't sign out a later account.
          await prefs.remove(_kRememberMeKey);
        } else {
          return _routeForSignedInUser(current);
        }
      }
    }

    // Not signed in: start the login process. By default that begins
    // with the intro screens every time (see kShowOnboardingBeforeLogin).
    return (
      route: loggedOutRoute(onboardingSeen: onboardingSeen),
      notice: null,
    );
  }

  Future<({String route, String? notice})> _routeForSignedInUser(
    User user,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 6));
      final data = doc.data();

      // Enforce "Block Account" for already-signed-in users too — the
      // login screen only checks this at the moment of typing a password.
      if (data?['isBlocked'] == true) {
        await FirebaseAuth.instance.signOut();
        return (
          route: AppRoutes.login,
          notice: 'This account has been blocked. Please contact support.',
        );
      }

      // Keep the profile's e-mail equal to the login e-mail (they differ
      // right after a confirmed e-mail change).
      final authEmail = user.email;
      final storedEmail = data?['email'] as String?;
      if (authEmail != null && data != null && storedEmail?.toLowerCase() != authEmail.toLowerCase()) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({'email': authEmail}).catchError((_) {});
      }

      final role = ((data?['role'] as String?) ?? 'customer')
          .trim()
          .toLowerCase();

      // `ref` must not be used once this widget is gone.
      if (!mounted) return (route: AppRoutes.home, notice: null);

      ref
          .read(userProfileProvider.notifier)
          .update(
            name:
                data?['fullName'] as String? ?? user.displayName ?? 'User',
            email: user.email ?? (data?['email'] as String? ?? ''),
            phone: data?['phone'] as String? ?? '',
            avatarUrl: data?['avatarUrl'] as String?,
            role: role,
          );

      // Staff land on the Admin Dashboard, customers on the store.
      return (
        route: role == 'customer' ? AppRoutes.home : AppRoutes.admin,
        notice: null,
      );
    } catch (_) {
      // Offline or slow network: keep the user signed in and let them
      // in — the profile listener fills in the rest once it connects.
      return (route: AppRoutes.home, notice: null);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final glow = 0.25 + (_pulseController.value * 0.25);
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: glow),
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: GlassCard(
                            borderRadius: 32,
                            padding: const EdgeInsets.all(28),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                        )
                        .animate()
                        .scale(
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                        )
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 28),
                    Text(
                          'ShopVerse',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 8),
                    Text(
                      'Shop Smart. Live Better.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              const _PulsingDots().animate().fadeIn(
                delay: 900.ms,
                duration: 400.ms,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three softly pulsing dots — a lightweight, premium-feeling substitute
/// for a plain spinner, signaling "loading" without competing visually
/// with the logo above it.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final opacity =
                0.3 + (0.7 * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2)));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: opacity.clamp(0.3, 1.0),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
