import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/liquid_background.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  Future<void> _makeCall(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF8B0000), // Emergency Red
      body: Stack(
        children: [
          // Background Animation
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFFFF0000), Color(0xFF4B0000)],
                  radius: 1.2,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .tint(color: Colors.black, end: 0.3, duration: 2.seconds),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                    const SizedBox(width: 48),
                  ]),
                  
                  const Spacer(),
                  
                  // SOS Button
                  Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.white.withAlpha(80), blurRadius: 40, spreadRadius: 10),
                      ],
                    ),
                    child: const Center(
                      child: Text('SOS', style: TextStyle(color: Color(0xFFCC0000), fontSize: 48, fontWeight: FontWeight.w900)),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut)
                   .boxShadow(begin: BoxShadow(color: Colors.white.withAlpha(50), blurRadius: 20), end: BoxShadow(color: Colors.white.withAlpha(150), blurRadius: 60)),

                  const SizedBox(height: 48),
                  const Text('Help is being requested...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  
                  const Spacer(),

                  // Critical Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        const Text('CRITICAL MEDICAL INFO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _infoItem('BLOOD', user['blood_group'] ?? 'N/A', LucideIcons.droplets, Colors.red),
                          _infoItem('ALLERGIES', user['allergies'] ?? 'None', LucideIcons.shieldAlert, Colors.orange),
                        ]),
                        const SizedBox(height: 20),
                        _contactItem('Emergency Contact', user['emergency_contact'] ?? '+91 98XXX XXXXX', LucideIcons.phoneCall),
                      ],
                    ),
                  ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),

                  // Quick Dial Buttons
                  Row(children: [
                    Expanded(child: _actionButton('AMBULANCE', '102', LucideIcons.activity)),
                    const SizedBox(width: 12),
                    Expanded(child: _actionButton('HOSPITAL', '+91 12345 67890', LucideIcons.building2)),
                  ]).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
    ]);
  }

  Widget _contactItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        ]),
        const Spacer(),
        IconButton(onPressed: () => _makeCall(value), icon: const Icon(LucideIcons.phone, color: Colors.green)),
      ]),
    );
  }

  Widget _actionButton(String label, String number, IconData icon) {
    return Material(
      color: Colors.white.withAlpha(40),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _makeCall(number),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
