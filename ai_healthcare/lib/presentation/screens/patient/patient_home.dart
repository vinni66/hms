import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/book_appointment_dialog.dart';
import '../../widgets/liquid_background.dart';
import 'patient_records.dart';
import 'ai_chat_screen.dart';
import 'medicine_availability_screen.dart';
import 'sos_screen.dart';
import '../../../data/services/call_service.dart';
import '../../../core/services/pdf_service.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});
  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final _api = ApiService();
  List _appointments = [];
  List _prescriptions = [];
  List _metrics = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark.withAlpha(150) : Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success.withAlpha(30)),
                          ),
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

                      // Daily Habits section
                      if (user?['role'] == 'patient') ...[
                        Text('Daily Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _habitChip('Drink Water', LucideIcons.droplets, Colors.blue, isDark),
                              _habitChip('10k Steps', LucideIcons.footprints, Colors.orange, isDark),
                              _habitChip('Log Vitals', LucideIcons.activity, Colors.red, isDark),
                              _habitChip('Meditation', LucideIcons.moon, Colors.purple, isDark),
                            ],
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
                          _actionCard('Find\nPharmacies', LucideIcons.mapPin, 
                            const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)], begin: Alignment.topLeft, end: Alignment.bottomRight), 
                            isDark, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineAvailabilityScreen()));
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen())),
        backgroundColor: Colors.redAccent,
        elevation: 6,
        icon: const Icon(LucideIcons.megaphone, color: Colors.white),
        label: const Text('SOS EMERGENCY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .shimmer(duration: 2.seconds, color: Colors.white.withAlpha(50))
       .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark.withAlpha(200) : Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 80)),
          boxShadow: [BoxShadow(color: color.withAlpha(isDark ? 20 : 15), blurRadius: 25)],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(isDark ? 15 : 100)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 8), blurRadius: 25)],
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
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withAlpha(isDark ? 30 : 50)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 8), blurRadius: 25)],
      ),
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
}
