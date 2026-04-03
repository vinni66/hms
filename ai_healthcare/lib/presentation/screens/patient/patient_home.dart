import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/book_appointment_dialog.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final _api = ApiService();
  List _appointments = [];
  List _prescriptions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_api.getAppointments(), _api.getPrescriptions()]);
      _appointments = results[0]; _prescriptions = results[1];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _api.currentUser;
    final name = (user?['name'] ?? 'User').toString().split(' ').first;
    final pending = _appointments.where((a) => a['status'] == 'pending').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: Container(
        decoration: BoxDecoration(gradient: isDark ? AppColors.darkGradient : null, color: isDark ? null : AppColors.bgLight),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))
                                .animate().fadeIn(),
                            const SizedBox(height: 4),
                            Text('$name 👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight))
                                .animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                          ],
                        )),
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
                        ).animate().scale(delay: 200.ms),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      children: [
                        _statCard('Appointments', '$pending pending', LucideIcons.calendar, AppColors.primary, isDark),
                        const SizedBox(width: 12),
                        _statCard('Prescriptions', '${_prescriptions.length} total', LucideIcons.pill, AppColors.success, isDark),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _actionCard('Book\nAppointment', LucideIcons.calendarPlus, AppColors.primaryGradient, isDark, () {
                          BookAppointmentDialog.show(context, onBooked: _load);
                        }),
                        const SizedBox(width: 12),
                        _actionCard('View\nDoctors', LucideIcons.stethoscope, AppColors.accentGradient, isDark, () {}),
                        const SizedBox(width: 12),
                        _actionCard('Health\nRecords', LucideIcons.fileHeart, AppColors.warmGradient, isDark, () {}),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),

                    const SizedBox(height: 24),

                    // Upcoming appointments
                    Text('Upcoming Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            )),

            _loading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                : _appointments.where((a) => a['status'] == 'pending').isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(LucideIcons.calendarOff, size: 60, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                            const SizedBox(height: 16),
                            Text('No upcoming appointments', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                          ]),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final pending = _appointments.where((a) => a['status'] == 'pending').toList();
                            if (i >= pending.length) return null;
                            final apt = pending[i];
                            return _appointmentCard(apt, isDark).animate().fadeIn(delay: (400 + i * 80).ms).slideX(begin: 0.1);
                          },
                          childCount: _appointments.where((a) => a['status'] == 'pending').length,
                        )),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [BoxShadow(color: color.withAlpha(15), blurRadius: 20)],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          ]),
        ]),
      ),
    );
  }

  Widget _actionCard(String label, IconData icon, LinearGradient gradient, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: gradient.colors.first.withAlpha(40), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
          ]),
        ),
      ),
    );
  }

  Widget _appointmentCard(dynamic apt, bool isDark) {
    final dt = DateTime.tryParse(apt['date_time'] ?? '') ?? DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 60, padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${dt.day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text(months[dt.month - 1], style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(apt['doctor_name'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
          const SizedBox(height: 4),
          Text(apt['specialty'] ?? '', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(LucideIcons.clock, size: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            const SizedBox(width: 4),
            Text('${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppColors.warning.withAlpha(25), borderRadius: BorderRadius.circular(8)),
          child: const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
