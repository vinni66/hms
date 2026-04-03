import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../login_screen.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});
  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  final _api = ApiService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _api.currentUser ?? {};

    return Container(
      decoration: BoxDecoration(gradient: isDark ? AppColors.darkGradient : null, color: isDark ? null : AppColors.bgLight),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // Avatar & Name
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 25, offset: const Offset(0, 8))],
              ),
              child: Center(child: Text(
                (user['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
              )),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(user['name'] ?? 'User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
            Text(user['email'] ?? '', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Text('Patient', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 28),

            // Info cards
            _infoRow(LucideIcons.heart, 'Blood Group', user['blood_group'] ?? 'Not set', AppColors.error, isDark),
            _infoRow(LucideIcons.cake, 'Age', '${user['age'] ?? 0} years', AppColors.warning, isDark),
            _infoRow(LucideIcons.phone, 'Phone', user['phone']?.toString().isNotEmpty == true ? user['phone'] : 'Not set', AppColors.success, isDark),
            _infoRow(LucideIcons.user, 'Gender', user['gender']?.toString().isNotEmpty == true ? user['gender'] : 'Not set', AppColors.info, isDark),

            const SizedBox(height: 28),

            // Logout
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
                  await _api.logout();
                  if (mounted) Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                },
              ),
            ).animate().fadeIn(delay: 400.ms),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(20)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
        ]),
      ]),
    );
  }
}
