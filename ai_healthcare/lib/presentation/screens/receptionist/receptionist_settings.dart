import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../login_screen.dart';
import '../../widgets/liquid_background.dart';

class ReceptionistSettings extends StatelessWidget {
  const ReceptionistSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final api = ApiService();
    final user = api.currentUser ?? {};
    
    return LiquidBackground(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(28)),
                child: const Icon(LucideIcons.userCheck, color: Colors.white, size: 40),
              ).animate().scale(),
              const SizedBox(height: 16),
              Text(user['name'] ?? 'Front Desk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
              Text(user['email'] ?? '', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF5A623).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: const Text('Receptionist', style: TextStyle(color: Color(0xFFF5A623), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 54,
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withAlpha(60)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    await api.logout();
                    if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  },
                ),
              ).animate().fadeIn(delay: 200.ms),
            ]),
          ),
        ),
      ),
    );
  }
}
