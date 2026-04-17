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
          top: -100, left: -100,
          child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.primary.withAlpha(200), AppColors.primary.withAlpha(0)])))
            .animate(onPlay: (c) => c.repeat(reverse: true)).scale(end: const Offset(1.2, 1.2), duration: 10.seconds, curve: Curves.easeInOut),
        ),
        // Bottom Right Blob
        Positioned(
          bottom: -50, right: -50,
          child: Container(width: 550, height: 550, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.accent.withAlpha(180), AppColors.accent.withAlpha(0)])))
            .animate(onPlay: (c) => c.repeat(reverse: true)).slide(end: const Offset(-0.2, -0.2), duration: 9.seconds, curve: Curves.easeInOut),
        ),
        // Extreme Blur Layer to create liquid blending
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: (isDark ? AppColors.bgDark : AppColors.bgLight).withAlpha(isDark ? 140 : 160),
            ),
          ),
        ),
        // Foreground Content
        child,
      ],
    );
  }
}
