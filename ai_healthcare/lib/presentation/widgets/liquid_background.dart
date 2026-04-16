import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/colors.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Top Left Blob
        Positioned(
          top: -150, left: -100,
          child: Container(width: 400, height: 400, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient))
            .animate(onPlay: (c) => c.repeat(reverse: true)).scale(end: const Offset(1.1, 1.1), duration: 8.seconds, curve: Curves.easeInOut),
        ),
        // Bottom Right Blob
        Positioned(
          bottom: -100, right: -150,
          child: Container(width: 450, height: 450, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.accentGradient))
            .animate(onPlay: (c) => c.repeat(reverse: true)).slide(end: const Offset(-0.1, -0.1), duration: 7.seconds, curve: Curves.easeInOut),
        ),
        // Extreme Blur Layer to create liquid blending
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              color: (isDark ? AppColors.bgDark : AppColors.bgLight).withAlpha(isDark ? 160 : 180),
            ),
          ),
        ),
        // Foreground Content
        child,
      ],
    );
  }
}
