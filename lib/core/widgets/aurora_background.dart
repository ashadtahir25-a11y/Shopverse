import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A layered gradient backdrop with soft, blurred color "blobs" — the
/// canvas glassmorphism cards are designed to float on top of. Used on
/// Splash, Auth, and other hero screens for a premium, modern feel.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const AuroraBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final gradientColors =
        colors ?? const [Color(0xFF4B3FE4), Color(0xFF352DB0)];

    return Stack(
      fit: StackFit.expand,
      children: [
        // The gradient + three heavily-blurred blobs never change, so they
        // get their own RepaintBoundary: screens drawn on top of this (like
        // the splash, which animates a pulsing glow every frame) no longer
        // force these expensive blur layers to be repainted 60 times a
        // second — a real cost on mid-range phones.
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -80,
                right: -60,
                child: _blob(220, AppColors.accent.withValues(alpha: 0.55)),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: _blob(260, Colors.white.withValues(alpha: 0.18)),
              ),
              Positioned(
                top: 180,
                left: -50,
                child: _blob(
                  160,
                  const Color(0xFF16C79A).withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
