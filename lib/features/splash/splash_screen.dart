import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_background.dart';
import '../../core/widgets/glass_card.dart';

const _kOnboardingSeenKey = 'onboarding_seen';
const _kAuthTokenKey = 'auth_token';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(_kOnboardingSeenKey) ?? false;
    final hasToken = prefs.getString(_kAuthTokenKey) != null;

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    if (!onboardingSeen) {
      context.go(AppRoutes.onboarding);
    } else if (hasToken) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
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
