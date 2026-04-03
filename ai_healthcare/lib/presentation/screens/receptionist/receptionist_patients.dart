import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';

import '../../widgets/book_appointment_dialog.dart';

class ReceptionistPatients extends StatefulWidget {
  const ReceptionistPatients({super.key});
  @override
  State<ReceptionistPatients> createState() => _ReceptionistPatientsState();
}

class _ReceptionistPatientsState extends State<ReceptionistPatients> {
  final _api = ApiService();
  List _patients = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _patients = await _api.getPatients();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(gradient: isDark ? AppColors.darkGradient : null, color: isDark ? null : AppColors.bgLight),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(children: [
              Text('Patients Directory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
              const Spacer(),
            ]),
          ),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5A623)))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _patients.length,
                  itemBuilder: (_, i) {
                    final p = _patients[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: AppColors.primary.withAlpha(30), child: Text((p['name'] ?? 'P')[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                          Text(p['email'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                        ])),
                        IconButton(
                          icon: const Icon(LucideIcons.calendarPlus, color: Color(0xFFF5A623)),
                          tooltip: 'Book Appointment',
                          onPressed: () => BookAppointmentDialog.show(context, patient: p, onBooked: _load),
                        ),
                      ]),
                    ).animate().fadeIn(delay: (i * 60).ms);
                  },
                ),
              ),
          ),
        ]),
      ),
    );
  }
}

