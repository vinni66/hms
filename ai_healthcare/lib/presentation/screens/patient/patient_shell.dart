import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import 'patient_home.dart';
import 'patient_appointments.dart';
import 'patient_prescriptions.dart';
import 'patient_profile.dart';
import 'ai_chat_screen.dart';
import '../../widgets/liquid_nav_bar.dart';

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
    return Scaffold(
      extendBody: true,
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
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        activeColor: AppColors.primary,
        items: [
          LiquidNavItem(icon: LucideIcons.home, label: 'Home'),
          LiquidNavItem(icon: LucideIcons.calendar, label: 'Visits'),
          LiquidNavItem(icon: LucideIcons.pill, label: 'Rx'),
          LiquidNavItem(icon: LucideIcons.user, label: 'Profile'),
        ],
      ),
    );
  }
}
