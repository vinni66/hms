import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/book_appointment_dialog.dart';
import '../../widgets/liquid_background.dart';
import '../../../data/services/call_service.dart';

class PatientAppointments extends StatefulWidget {
  const PatientAppointments({super.key});
  @override
  State<PatientAppointments> createState() => _PatientAppointmentsState();
}

class _PatientAppointmentsState extends State<PatientAppointments> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabC;
  List _pending = [];
  List _confirmed = [];
  List _completed = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabC = TabController(length: 3, vsync: this); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.getAppointments();
      _pending = r.where((a) => a['status'] == 'pending').toList();
      _confirmed = r.where((a) => a['status'] == 'confirmed').toList();
      _completed = r.where((a) => a['status'] == 'completed' || a['status'] == 'cancelled').toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                Text('Appointments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => BookAppointmentDialog.show(context, onBooked: _load),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabC,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'Pending (${_pending.length})'),
                Tab(text: 'Confirmed (${_confirmed.length})'),
                Tab(text: 'Past (${_completed.length})'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(controller: _tabC, children: [
                      _buildList(_pending, isDark, 'No pending appointments'),
                      _buildList(_confirmed, isDark, 'No confirmed appointments'),
                      _buildList(_completed, isDark, 'No past appointments'),
                    ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List items, bool isDark, String empty) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.calendarOff, size: 50, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
        const SizedBox(height: 12),
        Text(empty, style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (_, i) => _aptCard(items[i], isDark, i),
      ),
    );
  }

  Widget _aptCard(dynamic apt, bool isDark, int i) {
    final dt = DateTime.tryParse(apt['date_time'] ?? '') ?? DateTime.now();
    final status = apt['status'] ?? 'pending';
    final statusColor = status == 'completed' ? AppColors.success : status == 'confirmed' ? AppColors.primary : status == 'cancelled' ? AppColors.error : AppColors.warning;

    return Dismissible(
      key: Key(apt['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(18)),
        child: const Icon(LucideIcons.trash2, color: AppColors.error),
      ),
      onDismissed: (_) async { await _api.deleteAppointment(apt['id']); _load(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: statusColor.withAlpha(50)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 12), blurRadius: 25)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(LucideIcons.stethoscope, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(apt['doctor_name'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
              Text(apt['specialty'] ?? '', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Icon(LucideIcons.calendar, size: 15, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            const SizedBox(width: 6),
            Text(DateFormat('MMM dd, yyyy').format(dt), style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            const SizedBox(width: 16),
            Icon(LucideIcons.clock, size: 15, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            const SizedBox(width: 6),
            Text(DateFormat('hh:mm a').format(dt), style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          ]),
          
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => CallService().startCall(apt['doctor_id'], _api.currentUser?['name'] ?? 'Patient', 'patient'),
                icon: const Icon(LucideIcons.video, color: Colors.white, size: 18),
                label: const Text('Join Video Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          if (apt['consultation_notes'] != null && apt['consultation_notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.success.withAlpha(10), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Doctor Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                const SizedBox(height: 4),
                Text(apt['consultation_notes'], style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDark : AppColors.textLight)),
              ]),
            ),
          ],
        ]),
      ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1),
    );
  }
}
