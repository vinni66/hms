import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/colors.dart';
import '../../data/services/api_service.dart';

class BookAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic>? patient; // Optional: specify patient if receptionist is booking
  final VoidCallback onBooked;

  const BookAppointmentDialog({super.key, this.patient, required this.onBooked});

  static void show(BuildContext context, {Map<String, dynamic>? patient, required VoidCallback onBooked}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookAppointmentDialog(patient: patient, onBooked: onBooked),
    );
  }

  @override
  State<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<BookAppointmentDialog> {
  final _api = ApiService();
  List _doctors = [];
  bool _loading = true;

  String? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final _notesC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      _doctors = await _api.getDoctors();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(60), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(widget.patient == null ? 'Book Appointment' : 'Book for ${widget.patient!['name']}', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else ...[
          // Doctor selector
          Text('Select Doctor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _doctors.length,
              itemBuilder: (_, i) {
                final d = _doctors[i];
                final sel = _selectedDoctor == d['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedDoctor = d['id']),
                  child: Container(
                    width: 130, margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary.withAlpha(20) : (isDark ? AppColors.cardDark : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 2),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(d['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(d['specialty'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary), maxLines: 1),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time
          Row(children: [
            Expanded(child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                if (d != null) setState(() => _selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.surfaceLight, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(DateFormat('MMM dd').format(_selectedDate), style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _selectedTime);
                if (t != null) setState(() => _selectedTime = t);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.surfaceLight, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(LucideIcons.clock, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(_selectedTime.format(context), style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 14),

          TextField(controller: _notesC, maxLines: 2, decoration: const InputDecoration(hintText: 'Notes / symptoms (optional)')),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.calendarCheck, size: 20),
              label: const Text('Book Appointment'),
              style: widget.patient != null ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A623)) : null,
              onPressed: _selectedDoctor == null ? null : () async {
                final dateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
                
                final payload = {
                  'doctor_id': _selectedDoctor,
                  'date_time': dateTime.toIso8601String(),
                  'notes': _notesC.text.trim(),
                };
                if (widget.patient != null) {
                  payload['patient_id'] = widget.patient!['id'];
                }

                await _api.createAppointment(payload);
                if (mounted) {
                  Navigator.pop(context);
                  widget.onBooked();
                }
              },
            ),
          ),
        ],
      ]),
    );
  }
}
