import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import 'receptionist_dashboard.dart';
import 'receptionist_patients.dart';
import 'receptionist_settings.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
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
                _navItem(0, LucideIcons.layoutDashboard, 'Dashboard', isDark),
                _navItem(1, LucideIcons.users, 'Patients', isDark),
                _navItem(2, LucideIcons.settings, 'Settings', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final active = _index == index;
    // Let's reuse the warning color for receptionist (orange/yellow theme) or a new color
    const activeColor = Color(0xFFF5A623); // Matches avatar color
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? activeColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? activeColor : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            if (active) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: activeColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
