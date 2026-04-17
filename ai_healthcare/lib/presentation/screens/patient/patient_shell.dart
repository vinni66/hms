import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import 'patient_home.dart';
import 'patient_profile.dart';
import 'ai_chat_screen.dart';
import 'family_dashboard.dart';
import 'wellness_screen.dart';
import '../../widgets/liquid_nav_bar.dart';
import '../../widgets/glass_container.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});
  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;
  final _screens = [
    const PatientHome(),
    const WellnessScreen(),
    const FamilyDashboard(),
    const PatientProfile(),
  ];

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
        elevation: 0,
        child: GlassContainer(
          width: 56, height: 56,
          borderRadius: 28,
          opacity: 0.1,
          blur: 10,
          padding: EdgeInsets.zero,
          color: AppColors.primary,
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
          border: Border.all(color: AppColors.primary.withAlpha(100), width: 2),
          child: const Center(child: Icon(LucideIcons.bot, color: Colors.white, size: 28)),
        ),
      ),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        activeColor: AppColors.primary,
        items: [
          LiquidNavItem(icon: LucideIcons.home, label: 'Home'),
          LiquidNavItem(icon: LucideIcons.activity, label: 'Wellness'),
          LiquidNavItem(icon: LucideIcons.users, label: 'Family'),
          LiquidNavItem(icon: LucideIcons.user, label: 'Profile'),
        ],
      ),
    );
  }
}
