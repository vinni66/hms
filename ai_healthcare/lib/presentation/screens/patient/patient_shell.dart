import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import 'patient_home.dart';
import 'patient_appointments.dart';
import 'patient_prescriptions.dart';
import 'patient_profile.dart';
import 'ai_chat_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});
  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;
  final _screens = const [PatientHome(), PatientAppointments(), PatientPrescriptions(), PatientProfile()];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
        },
        backgroundColor: Colors.transparent,
        elevation: 10,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 15, offset: const Offset(0, 5))
            ]
          ),
          child: const Icon(LucideIcons.bot, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, LucideIcons.home, 'Home', isDark),
                _navItem(1, LucideIcons.calendar, 'Visits', isDark),
                _navItem(2, LucideIcons.pill, 'Rx', isDark),
                _navItem(3, LucideIcons.user, 'Profile', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final active = _index == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            if (active) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
