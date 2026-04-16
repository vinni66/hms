import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../login_screen.dart';
import '../../widgets/liquid_nav_bar.dart';
import '../../widgets/liquid_background.dart';
import '../../../data/services/call_service.dart';
import 'dart:ui';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});
  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  final _api = ApiService();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: [
        _DoctorHome(api: _api),
        _DoctorAppointments(api: _api),
        _DoctorProfile(api: _api),
      ]),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        activeColor: AppColors.doctorColor,
        items: [
          LiquidNavItem(icon: LucideIcons.home, label: 'Dashboard'),
          LiquidNavItem(icon: LucideIcons.calendarCheck, label: 'Patients'),
          LiquidNavItem(icon: LucideIcons.user, label: 'Profile'),
        ],
      ),
    );
  }
}

class _DoctorHome extends StatefulWidget {
  final ApiService api;
  const _DoctorHome({required this.api});
  @override
  State<_DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<_DoctorHome> {
  List _appointments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { _appointments = await widget.api.getAppointments(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.api.currentUser ?? {};
    final pending = _appointments.where((a) => a['status'] == 'pending').length;
    final completed = _appointments.where((a) => a['status'] == 'completed').length;

    return LiquidBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Doctor Dashboard', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                Text(user['name'] ?? 'Doctor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
                Text(user['specialty'] ?? '', style: const TextStyle(color: AppColors.doctorColor, fontWeight: FontWeight.w500)),
              ])),
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(18)),
                child: const Icon(LucideIcons.stethoscope, color: Colors.white, size: 26),
              ),
            ]).animate().fadeIn(),

            const SizedBox(height: 24),

            Row(children: [
              _stat('Pending', '$pending', AppColors.warning, isDark),
              const SizedBox(width: 12),
              _stat('Completed', '$completed', AppColors.success, isDark),
              const SizedBox(width: 12),
              _stat('Total', '${_appointments.length}', AppColors.primary, isDark),
            ]).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),
            Text("Today's Patients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
            const SizedBox(height: 12),

            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.doctorColor)))
            else if (_appointments.isEmpty)
              Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('No appointments yet', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))))
            else ..._appointments.where((a) => a['status'] == 'pending').take(5).toList().asMap().entries.map((e) => _aptCard(e.value, isDark, e.key)),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color, bool isDark) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(200) : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(isDark ? 20 : 50)),
        boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 20)],
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
      ]),
    ));
  }

  Widget _aptCard(dynamic apt, bool isDark, int i) {
    final dt = DateTime.tryParse(apt['date_time'] ?? '') ?? DateTime.now();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.doctorColor.withAlpha(isDark ? 20 : 50)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 10), blurRadius: 20)],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.doctorColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: const Icon(LucideIcons.user, color: AppColors.doctorColor, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(apt['patient_name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
          Text(DateFormat('MMM dd, hh:mm a').format(dt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
        ])),
        // Video Call button
        IconButton(
          icon: const Icon(LucideIcons.video, color: AppColors.primary),
          tooltip: 'Start Video Call',
          onPressed: () {
            CallService().startCall(apt['patient_id'], widget.api.currentUser?['name'] ?? 'Doctor', 'doctor');
          },
        ),
        // Write prescription button
        IconButton(
          icon: const Icon(LucideIcons.filePlus, color: AppColors.success),
          tooltip: 'Write Prescription',
          onPressed: () => _writePrescription(apt),
        ),
        IconButton(
          icon: const Icon(LucideIcons.checkCircle, color: AppColors.doctorColor),
          tooltip: 'Mark Complete',
          onPressed: () async { await widget.api.updateAppointmentStatus(apt['id'], 'completed'); _load(); },
        ),
      ]),
    ).animate().fadeIn(delay: (i * 80).ms);
  }

  void _writePrescription(dynamic apt) {
    final diagC = TextEditingController();
    final instrC = TextEditingController();
    final medNameC = TextEditingController();
    final medDoseC = TextEditingController();
    List<Map<String, String>> meds = [];

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return StatefulBuilder(builder: (ctx, setS) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary.withAlpha(220) : Colors.white.withAlpha(220),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white.withAlpha(isDark ? 20 : 100), width: 1.5))
            ),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(60), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Write Prescription', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          Text('Patient: ${apt['patient_name']}', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          const SizedBox(height: 16),
          TextField(controller: diagC, decoration: const InputDecoration(hintText: 'Diagnosis', prefixIcon: Icon(LucideIcons.fileSearch, size: 20))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: medNameC, decoration: const InputDecoration(hintText: 'Medicine'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: medDoseC, decoration: const InputDecoration(hintText: 'Dosage'))),
            IconButton(icon: const Icon(LucideIcons.plus, color: AppColors.success), onPressed: () {
              if (medNameC.text.isNotEmpty) { setS(() => meds.add({'name': medNameC.text, 'dosage': medDoseC.text})); medNameC.clear(); medDoseC.clear(); }
            }),
          ]),
          if (meds.isNotEmpty) ...meds.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              const Icon(LucideIcons.pill, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(child: Text('${e.value['name']} — ${e.value['dosage']}', style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight))),
              IconButton(icon: const Icon(LucideIcons.x, size: 16, color: AppColors.error), onPressed: () => setS(() => meds.removeAt(e.key))),
            ]),
          )),
          const SizedBox(height: 12),
          TextField(controller: instrC, maxLines: 2, decoration: const InputDecoration(hintText: 'Instructions')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
            icon: const Icon(LucideIcons.check, size: 20),
            label: const Text('Issue Prescription'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              if (diagC.text.isEmpty) return;
              await widget.api.createPrescription({
                'patient_id': apt['patient_id'], 'appointment_id': apt['id'],
                'diagnosis': diagC.text, 'medications': meds, 'instructions': instrC.text,
              });
              await widget.api.addConsultationNotes(apt['id'], 'Diagnosis: ${diagC.text}');
              if (mounted) { Navigator.pop(ctx); _load(); }
            },
          )),
        ])),
      ))));
    });
  }
}

class _DoctorAppointments extends StatefulWidget {
  final ApiService api;
  const _DoctorAppointments({required this.api});
  @override
  State<_DoctorAppointments> createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<_DoctorAppointments> {
  List _apts = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { _apts = await widget.api.getAppointments(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidBackground(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Text('All Patients', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          ),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.doctorColor))
            : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _apts.length,
                itemBuilder: (_, i) {
                  final a = _apts[i];
                  final dt = DateTime.tryParse(a['date_time'] ?? '') ?? DateTime.now();
                  final status = a['status'] ?? 'pending';
                  final sc = status == 'completed' ? AppColors.success : status == 'confirmed' ? AppColors.primary : AppColors.warning;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 80)),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 10), blurRadius: 20)],
                    ),
                    child: Row(children: [
                      CircleAvatar(backgroundColor: sc.withAlpha(30), child: Icon(LucideIcons.user, color: sc, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['patient_name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                        Text('${DateFormat('MMM dd, hh:mm a').format(dt)} • $status', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                      ])),
                    ]),
                  ).animate().fadeIn(delay: (i * 60).ms);
                },
              )),
          ),
        ]),
      ),
    );
  }
}

class _DoctorProfile extends StatelessWidget {
  final ApiService api;
  const _DoctorProfile({required this.api});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = api.currentUser ?? {};
    return LiquidBackground(
      child: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(width: 90, height: 90, decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(28)),
            child: Center(child: Text((user['name'] ?? 'D')[0], style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 16),
          Text(user['name'] ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
          Text(user['specialty'] ?? '', style: const TextStyle(color: AppColors.doctorColor)),
          Text(user['qualification'] ?? '', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: AppColors.doctorColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Text('${user['experience_years'] ?? 0} years experience', style: const TextStyle(color: AppColors.doctorColor, fontSize: 12, fontWeight: FontWeight.w600))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error.withAlpha(60)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () async {
              await api.logout();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          )),
        ]),
      ))),
    );
  }
}
