import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/colors.dart';
import 'glass_container.dart';

class LiquidNavItem {
  final IconData icon;
  final String label;

  LiquidNavItem({required this.icon, required this.label});
}

class LiquidNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidNavItem> items;
  final Color activeColor;

  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GlassContainer(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        opacity: isDark ? 0.08 : 0.6,
        blur: 25,
        borderRadius: 32,
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(15),
          width: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isActive = currentIndex == index;
            final item = items[index];

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: isActive ? 18 : 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withAlpha(35) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: isActive ? activeColor : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ).animate(target: isActive ? 1 : 0)
                      .scale(end: const Offset(1.15, 1.15), duration: 250.ms, curve: Curves.easeOutBack),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(duration: 250.ms).slideX(begin: -0.1, end: 0, duration: 250.ms, curve: Curves.easeOut),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
