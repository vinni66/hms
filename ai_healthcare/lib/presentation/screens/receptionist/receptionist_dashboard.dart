import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/liquid_background.dart';
import '../../widgets/glass_container.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});
  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  final _api = ApiService();
  List _appointments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _appointments = await _api.getAppointments();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _api.currentUser ?? {};
    final pending = _appointments.where((a) => a['status'] == 'pending').length;
    final confirmed = _appointments.where((a) => a['status'] == 'confirmed').length;

    return LiquidBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Front Desk', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                  Text(user['name'] ?? 'Receptionist', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
                ])),
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(LucideIcons.clipboardList, color: Colors.white, size: 26),
                ),
              ]).animate().fadeIn(),

              const SizedBox(height: 24),

              Row(children: [
                _stat('Pending', '$pending', AppColors.warning, isDark),
                const SizedBox(width: 12),
                _stat('Confirmed', '$confirmed', AppColors.primary, isDark),
                const SizedBox(width: 12),
                _stat('Total', '${_appointments.length}', AppColors.success, isDark),
              ]).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 28),
              Text("Today's Appointments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
              const SizedBox(height: 12),

              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFF5A623))))
              else if (_appointments.isEmpty)
                Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('No appointments yet', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))))
              else ..._appointments.take(10).toList().asMap().entries.map((e) {
                final apt = e.value;
                final dt = DateTime.tryParse(apt['date_time'] ?? '') ?? DateTime.now();
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  opacity: isDark ? 0.08 : 0.6,
                  blur: 15,
                  borderRadius: 24,
                  border: Border.all(color: AppColors.primary.withAlpha(isDark ? 30 : 80)),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.calendar, color: AppColors.primary, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${apt['patient_name']} with ${apt['doctor_name']}', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                      Text(DateFormat('MMM dd, hh:mm a').format(dt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                    ])),
                    _statusBadge(apt['status'] ?? 'pending'),
                  ]),
                ).animate().fadeIn(delay: (300 + e.key * 80).ms);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        opacity: isDark ? 0.08 : 0.6,
        blur: 15,
        border: Border.all(color: color.withAlpha(isDark ? 40 : 100)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
      ]),
    ));
  }

  Widget _statusBadge(String status) {
    final color = status == 'completed' ? AppColors.success : status == 'confirmed' ? AppColors.primary : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
