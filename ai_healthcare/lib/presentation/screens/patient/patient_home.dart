import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/services/api_service.dart';
import 'family_dashboard.dart';
import 'patient_records.dart';
import 'ai_chat_screen.dart';
import 'medicine_availability_screen.dart';
import '../../widgets/book_appointment_dialog.dart';
import '../../widgets/liquid_background.dart';
import '../../widgets/glass_container.dart';
import '../../../data/services/call_service.dart';
import '../../../core/services/pdf_service.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final _api = ApiService();
  final _notify = NotificationService();
  List _appointments = [];
  List _prescriptions = [];
  List _metrics = [];
  List _medicationSchedule = [];
  List _logsToday = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _notify.requestPermissions();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getAppointments(),
        _api.getPrescriptions(),
        _api.getMetrics(),
      ]);
      _appointments = results[0];
      _prescriptions = results[1];
      _metrics = results[2];
      final medRes = await _api.getMedicationSchedule();
      _medicationSchedule = medRes['schedule'] ?? [];
      _logsToday = medRes['logs_today'] ?? [];
      _syncNotifications();
      await _api.loadToken(); // Refresh currentUser
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _triggerSOS() async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('🆘 SOS Alert'),
      content: const Text('Trigger emergency alert to all family members?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(ctx);
            await _api.triggerSOS('Home (GPS: 12.9716° N, 77.5946° E)');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🆘 Emergency signal broadcasted to family!'), backgroundColor: Colors.red)
              );
            }
          }, 
          child: const Text('TRIGGER SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        ),
      ],
    ));
  }

  Future<void> _logWellnessMetric(String type, double value, String unit) async {
    try {
      await _api.addMetric({
        'user_id': _api.currentUser?['id'],
        'type': type,
        'value': value,
        'unit': unit,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Logged ${value.toInt()}$unit $type!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log metric')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _api.currentUser;
    final name = (user?['name'] ?? 'User').toString().split(' ').first;
    final pendingAppointments = _appointments.where((a) => a['status'] == 'pending').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _load,
        child: LiquidBackground(
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

                      const SizedBox(height: 16),
                      
                      // Wellness Streak Section
                      InkWell(
                        onTap: () async {
                          final streak = await _api.checkIn();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Streak updated to $streak days! 🔥'),
                              backgroundColor: AppColors.success,
                            ));
                            _load();
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          opacity: isDark ? 0.08 : 0.6,
                          blur: 20,
                          borderRadius: 20,
                          border: Border.all(color: AppColors.success.withAlpha(isDark ? 40 : 80)),
                          child: Row(children: [
                            const Icon(LucideIcons.flame, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text('Wellness Streak: ', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                            Text('${user?['health_streak'] ?? 0} Days', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
                            const Spacer(),
                            const Text('Tap to Check-in  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            const Icon(LucideIcons.award, color: Colors.amber, size: 18),
                          ]),
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),

                      const SizedBox(height: 16),

                      // Wellness Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _quickLogTile(
                              'Drink Water',
                              '+250ml',
                              LucideIcons.droplets,
                              Colors.blueAccent,
                              isDark,
                              () => _logWellnessMetric('Water', 250, 'ml'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _quickLogTile(
                              'Logged Steps',
                              '+1000',
                              LucideIcons.footprints,
                              Colors.orangeAccent,
                              isDark,
                              () => _logWellnessMetric('Steps', 1000, 'steps'),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 280.ms).slideX(begin: -0.05),

                      const SizedBox(height: 16),

                      // Medication Scheduler Section
                      if (user?['role'] == 'patient') ...[
                        Row(children: [
                          Text('My Medicine Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                          const Spacer(),
                          TextButton(onPressed: _showScheduleManager, child: const Text('Manage', style: TextStyle(fontSize: 12))),
                        ]),
                        const SizedBox(height: 12),
                        if (_medicationSchedule.isEmpty)
                          _buildEmptyMedCard(isDark)
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _medicationSchedule.length,
                              itemBuilder: (ctx, i) {
                                final med = _medicationSchedule[i];
                                final isTaken = _logsToday.any((l) => l['schedule_id'] == med['id']);
                                return _medtaskCard(med, isTaken, isDark);
                              },
                            ),
                          ),
                      ],

                      const SizedBox(height: 24),

                      // Stats row
                      Row(
                        children: [
                          _statCard('Appointments', '${pendingAppointments.length} pending', LucideIcons.calendar, AppColors.primary, isDark),
                          const SizedBox(width: 12),
                          _statCard('Prescriptions', '${_prescriptions.length} total', LucideIcons.pill, AppColors.success, isDark),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                      const SizedBox(height: 24),

                      // Quick Actions
                      Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _actionCard('Book\nAppointment', LucideIcons.calendarPlus, AppColors.primaryGradient, isDark, () {
                            BookAppointmentDialog.show(context, onBooked: _load);
                          }),
                          _actionCard('Smart\nScanner', LucideIcons.scan, AppColors.accentGradient, isDark, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                          }),
                          _actionCard('Health\nRecords', LucideIcons.fileHeart, AppColors.warmGradient, isDark, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientRecords()));
                          }),
                          _actionCard('Family\nCircle', LucideIcons.users, 
                            const LinearGradient(colors: [Color(0xFFE100FF), Color(0xFF7F00FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), 
                            isDark, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyDashboard()));
                          }),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),

                      const SizedBox(height: 24),
                      
                      // Vital Statistics Dashboard Section
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Vital Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientRecords())),
                          child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        )
                      ]),
                      const SizedBox(height: 12),
                      
                      if (_metrics.isEmpty && !_loading)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: isDark ? AppColors.cardDark.withAlpha(200) : Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Center(child: Text('No vitals logged. Track your health today!', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
                        )
                      else if (_metrics.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _metrics.length,
                            itemBuilder: (ctx, i) {
                              final m = _metrics[i];
                              return Container(
                                width: 150,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: isDark ? AppColors.darkGradient : null,
                                  color: isDark ? null : Colors.white.withAlpha(240),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withAlpha(isDark ? 20 : 40)),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Row(children: [
                                    Icon(m['metric_type'] == 'Heart Rate' ? LucideIcons.heartPulse : LucideIcons.activity, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(m['metric_type'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text('${m['value']} ${m['unit'] ?? ''}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
                                ]),
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 350.ms),

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
                  : pendingAppointments.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(LucideIcons.calendarOff, size: 40, color: isDark ? AppColors.textDarkSecondary.withAlpha(100) : AppColors.textLightSecondary.withAlpha(100)),
                                const SizedBox(height: 8),
                                Text('No upcoming appointments', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13)),
                              ]),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              if (i >= pendingAppointments.length) return null;
                              final apt = pendingAppointments[i];
                              return _appointmentCard(apt, isDark).animate().fadeIn(delay: (400 + i * 80).ms).slideX(begin: 0.1);
                            },
                            childCount: pendingAppointments.length,
                          )),
                        ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Recent Prescriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              
              _loading
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : _prescriptions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text('No prescriptions found.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              if (i >= _prescriptions.length) return null;
                              final rx = _prescriptions[i];
                              return _prescriptionCard(rx, isDark).animate().fadeIn(delay: (600 + i * 80).ms).slideX(begin: 0.1);
                            },
                            childCount: _prescriptions.length > 3 ? 3 : _prescriptions.length,
                          )),
                        ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _triggerSOS,
        backgroundColor: Colors.redAccent,
        elevation: 6,
        icon: const Icon(LucideIcons.alertTriangle, color: Colors.white),
        label: const Text('SOS EMERGENCY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .shimmer(duration: 2.seconds, color: Colors.white.withAlpha(50))
       .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        opacity: isDark ? 0.08 : 0.6,
        blur: 15,
        borderRadius: 24,
        border: Border.all(color: color.withAlpha(isDark ? 40 : 80)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: gradient.colors.first.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard(dynamic apt, bool isDark) {
    final dt = DateTime.tryParse(apt['date_time'] ?? '') ?? DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      opacity: isDark ? 0.08 : 0.6,
      blur: 15,
      borderRadius: 24,
      border: Border.all(color: Colors.white.withAlpha(isDark ? 30 : 100)),
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
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.warning.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              CallService().startCall(apt['doctor_id'], _api.currentUser?['name'] ?? 'Patient', 'patient');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.video, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('Join Call', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _prescriptionCard(dynamic rx, bool isDark) {
    final dt = DateTime.tryParse(rx['date_issued'] ?? '') ?? DateTime.now();
    return GlassContainer(
      opacity: isDark ? 0.08 : 0.6,
      blur: 15,
      borderRadius: 24,
      border: Border.all(color: AppColors.success.withAlpha(isDark ? 30 : 80)),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.pill, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Prescribed by Dr. ${rx['doctor_name'] ?? 'Doctor'}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
            Text(DateFormat('MMM dd, yyyy').format(dt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          ])),
          IconButton(
            icon: const Icon(LucideIcons.download, color: AppColors.primary, size: 20),
            onPressed: () {
              final user = _api.currentUser ?? {};
              PdfService.generatePrescriptionPdf(rx, user);
            },
          ),
        ]),
        const SizedBox(height: 12),
        Text(rx['diagnosis'] ?? 'General Diagnosis', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
        const SizedBox(height: 16),
        Row(children: [
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.search, size: 14),
            label: const Text('Check Availability'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withAlpha(20),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final meds = rx['medications'] is List ? rx['medications'] : [];
              final firstMed = meds.isNotEmpty ? (meds[0] is Map ? (meds[0]['name'] ?? '') : meds[0].toString()) : '';
              Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineAvailabilityScreen(initialQuery: firstMed)));
            },
          ),
        ]),
      ]),
    );
  }

  Widget _medtaskCard(dynamic med, bool isTaken, bool isDark) {
    return GlassContainer(
      opacity: isTaken ? 0.3 : (isDark ? 0.08 : 0.4),
      blur: 10,
      borderRadius: 20,
      padding: const EdgeInsets.all(12),
      border: Border.all(color: isTaken ? AppColors.success.withAlpha(isDark ? 80 : 120) : AppColors.primary.withAlpha(isDark ? 40 : 80)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.pill, color: isTaken ? AppColors.success : AppColors.primary, size: 20),
        const Spacer(),
        Text(med['med_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
        Text(med['frequency'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        if (!isTaken)
          InkWell(
            onTap: () async {
              await _api.logMedicationDose(med['id']);
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('Take Now', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ),
          )
        else
          Row(children: [
            const Icon(LucideIcons.check, color: AppColors.success, size: 14),
            const SizedBox(width: 4),
            Text('Completed', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
      ]),
    );
  }

  Widget _buildEmptyMedCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark.withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const Icon(LucideIcons.info, color: AppColors.primary),
        const SizedBox(width: 12),
        const Expanded(child: Text('No active medication schedule. Tap Manage to add yours.', style: TextStyle(fontSize: 12))),
      ]),
    );
  }

  void _showScheduleManager() {
    final nameC = TextEditingController();
    final freqC = TextEditingController();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: BoxDecoration(color: isDark ? AppColors.bgDarkSecondary : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Medication', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
          const SizedBox(height: 16),
          TextField(controller: nameC, decoration: const InputDecoration(hintText: 'Medicine Name (e.g. Paracetamol)')),
          const SizedBox(height: 12),
          TextField(controller: freqC, decoration: const InputDecoration(hintText: 'Frequency (e.g. Twice a day)')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () async {
              if (nameC.text.isNotEmpty) {
                await _api.createMedicationSchedule({'med_name': nameC.text, 'frequency': freqC.text});
                await _notify.showNotification(
                  title: 'New Schedule Added',
                  body: 'Reminders set for ${nameC.text}',
                );
                if (mounted) { Navigator.pop(ctx); _load(); }
              }
            },
            child: const Text('Save Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ]),
      );
    });
  }

  void _syncNotifications() async {
    // Schedule reminders for all active medications (e.g. for next 24 hours)
    for (int i = 0; i < _medicationSchedule.length; i++) {
       // i is used for id
    }
  }

  Widget _habitChip(String label, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      ]),
    );
  }

  Widget _quickLogTile(String title, String subtitle, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        opacity: isDark ? 0.08 : 0.6,
        blur: 15,
        borderRadius: 20,
        border: Border.all(color: color.withAlpha(isDark ? 40 : 80)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                  Text(subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
