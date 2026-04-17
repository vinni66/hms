import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import 'glass_container.dart';

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final String role;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    required this.role,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(180),
                      Colors.black.withAlpha(240),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 40),
                
                // Ringing / Header
                Column(
                  children: [
                    const Icon(LucideIcons.radio, color: Colors.white54, size: 24)
                        .animate(onPlay: (c) => c.repeat())
                        .fade(duration: 1.seconds),
                    const SizedBox(height: 12),
                    const Text(
                      'INCOMING CALL',
                      style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 40, spreadRadius: 10)
                        ],
                      ),
                      child: Center(
                        child: Text(
                          callerName.isNotEmpty ? callerName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 1.seconds),
                    const SizedBox(height: 30),
                    Text(
                      role == 'doctor' ? 'Dr. $callerName' : callerName,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role == 'doctor' ? 'Tele-consultation' : 'Patient Session',
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onDecline,
                            child: GlassContainer(
                              padding: const EdgeInsets.all(24),
                              opacity: 0.15,
                              blur: 20,
                              borderRadius: 100,
                              color: Colors.red,
                              border: Border.all(color: Colors.red.withAlpha(100), width: 2),
                              child: const Icon(LucideIcons.phoneOff, color: Colors.white, size: 36),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Decline', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        ],
                      ).animate().slideY(begin: 1.0, duration: 400.ms),

                      // Accept
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onAccept,
                            child: GlassContainer(
                              padding: const EdgeInsets.all(24),
                              opacity: 0.15,
                              blur: 20,
                              borderRadius: 100,
                              color: AppColors.success,
                              border: Border.all(color: AppColors.success.withAlpha(100), width: 2),
                              child: const Icon(LucideIcons.phone, color: Colors.white, size: 36),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
                          ),
                          const SizedBox(height: 12),
                          const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ).animate().slideY(begin: 1.0, delay: 100.ms, duration: 400.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
