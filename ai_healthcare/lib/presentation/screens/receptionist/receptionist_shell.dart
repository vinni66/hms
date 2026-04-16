import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'receptionist_dashboard.dart';
import 'receptionist_patients.dart';
import 'receptionist_settings.dart';
import '../../widgets/liquid_nav_bar.dart';

class ReceptionistShell extends StatefulWidget {
  const ReceptionistShell({super.key});
  @override
  State<ReceptionistShell> createState() => _ReceptionistShellState();
}

class _ReceptionistShellState extends State<ReceptionistShell> {
  int _index = 0;
  final _screens = const [ReceptionistDashboard(), ReceptionistPatients(), ReceptionistSettings()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        activeColor: const Color(0xFFF5A623),
        items: [
          LiquidNavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
          LiquidNavItem(icon: LucideIcons.users, label: 'Patients'),
          LiquidNavItem(icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
