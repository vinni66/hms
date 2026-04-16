import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../login_screen.dart';
import '../../widgets/liquid_nav_bar.dart';
import '../../widgets/liquid_background.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _api = ApiService();
  Map<String, dynamic> _stats = {};
  List _users = [];
  bool _loading = true;
  int _index = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([_api.getAdminStats(), _api.getAdminUsers()]);
      _stats = Map<String, dynamic>.from(r[0] as Map);
      _users = r[1] as List;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: [
        _buildDashboard(isDark),
        _buildUsers(isDark),
        _buildSettings(isDark),
      ]),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        activeColor: AppColors.adminColor,
        items: [
          LiquidNavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
          LiquidNavItem(icon: LucideIcons.users, label: 'Users'),
          LiquidNavItem(icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    return LiquidBackground(
      child: SafeArea(child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Panel', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
              Text('System Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
            ])),
            Container(width: 54, height: 54, decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(18)),
              child: const Icon(LucideIcons.shield, color: Colors.white, size: 26)),
          ]).animate().fadeIn(),

          const SizedBox(height: 24),

          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.adminColor)))
          else ...[
            // Stats grid
            Row(children: [
              _statCard('Patients', '${_stats['totalUsers'] ?? 0}', LucideIcons.users, AppColors.primary, isDark),
              const SizedBox(width: 12),
              _statCard('Doctors', '${_stats['totalDoctors'] ?? 0}', LucideIcons.stethoscope, AppColors.doctorColor, isDark),
            ]).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Row(children: [
              _statCard('Appointments', '${_stats['totalAppointments'] ?? 0}', LucideIcons.calendar, AppColors.warning, isDark),
              const SizedBox(width: 12),
              _statCard('Prescriptions', '${_stats['totalPrescriptions'] ?? 0}', LucideIcons.pill, AppColors.success, isDark),
            ]).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Row(children: [
              _statCard('Pending', '${_stats['pendingAppointments'] ?? 0}', LucideIcons.clock, AppColors.error, isDark),
              const SizedBox(width: 12),
              _statCard('Completed', '${_stats['completedAppointments'] ?? 0}', LucideIcons.checkCircle, AppColors.success, isDark),
            ]).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 28),
            Text('Recent Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
            const SizedBox(height: 12),
            ..._users.take(5).toList().asMap().entries.map((e) {
              final u = e.value;
              final roleColor = u['role'] == 'admin' ? AppColors.adminColor : u['role'] == 'doctor' ? AppColors.doctorColor : AppColors.primary;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 80)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 10), blurRadius: 20)],
                ),
                child: Row(children: [
                  CircleAvatar(backgroundColor: roleColor.withAlpha(25), child: Text((u['name'] ?? 'U')[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    Text(u['email'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: roleColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                    child: Text(u['role'] ?? '', style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ).animate().fadeIn(delay: (400 + e.key * 60).ms);
            }),
          ],
        ]),
      )),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(200) : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(isDark ? 20 : 50)),
        boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 20)],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
        ]),
      ]),
    ));
  }

  Widget _buildUsers(bool isDark) {
    return LiquidBackground(
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), child: Row(children: [
          Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          const Spacer(),
          Text('${_users.length} users', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
        ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
          : RefreshIndicator(onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final u = _users[i];
                final roleColor = u['role'] == 'admin' ? AppColors.adminColor : u['role'] == 'doctor' ? AppColors.doctorColor : AppColors.primary;
                return Dismissible(
                  key: Key(u['id']),
                  direction: u['role'] == 'admin' ? DismissDirection.none : DismissDirection.endToStart,
                  background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.trash2, color: AppColors.error)),
                  onDismissed: (_) async { await _api.deleteUser(u['id']); _load(); },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 80)),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 10), blurRadius: 20)],
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: u['role'] == 'admin' ? AppColors.adminColor 
                          : u['role'] == 'doctor' ? AppColors.doctorColor 
                          : u['role'] == 'receptionist' ? const Color(0xFFF5A623) 
                          : AppColors.primary,
                        child: Text((u['name'] ?? '?')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                        Text('${u['role']} • ${u['email']}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                      ])),
                    ]),
                  ).animate().fadeIn(delay: (i * 50).ms),
                );
              },
            ))),
      ])),
    );
  }

  Widget _buildSettings(bool isDark) {
    return LiquidBackground(
      child: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 90, height: 90, decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(28)),
            child: const Icon(LucideIcons.shield, color: Colors.white, size: 40)),
          const SizedBox(height: 16),
          Text('System Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          Text(_api.currentUser?['email'] ?? '', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error.withAlpha(60)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () async {
              await _api.logout();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          )),
        ]),
      ))),
    );
  }
}
