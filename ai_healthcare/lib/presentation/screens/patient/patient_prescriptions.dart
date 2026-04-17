import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/colors.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/liquid_background.dart';

class PatientPrescriptions extends StatefulWidget {
  const PatientPrescriptions({super.key});
  @override
  State<PatientPrescriptions> createState() => _PatientPrescriptionsState();
}

class _PatientPrescriptionsState extends State<PatientPrescriptions> {
  final _api = ApiService();
  List _prescriptions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _prescriptions = await _api.getPrescriptions(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _checkPharmacies(String medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PharmacyBottomSheet(medicine: medicine, api: _api),
    );
  }

  Future<void> _downloadPdf(dynamic rx) async {
    try {
      final patient = _api.currentUser ?? {};
      await PdfService.generatePrescriptionPdf(rx, patient);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidBackground(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(children: [
              Text('Prescriptions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: Text('${_prescriptions.length}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _prescriptions.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.fileX, size: 50, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                        const SizedBox(height: 12),
                        Text('No prescriptions yet', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _prescriptions.length,
                          itemBuilder: (_, i) => _rxCard(_prescriptions[i], isDark, i),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _rxCard(dynamic rx, bool isDark, int i) {
    final dt = DateTime.tryParse(rx['date_issued'] ?? '') ?? DateTime.now();
    List meds = [];
    try { meds = rx['medications'] is String ? jsonDecode(rx['medications']) : (rx['medications'] ?? []); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withAlpha(50)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 12), blurRadius: 25)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.pill, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rx['diagnosis'] ?? 'Diagnosis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
            Text('Dr. ${rx['doctor_name'] ?? 'Unknown'}', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(DateFormat('MMM dd').format(dt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _downloadPdf(rx),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ]),
        ]),

        if (meds.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...meds.map((m) {
            final medName = m is Map ? m['name'].toString() : m.toString();
            final medDisplay = m is Map ? '${m['name']} — ${m['dosage']}' : m.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  medDisplay,
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDark : AppColors.textLight),
                )),
                TextButton.icon(
                  onPressed: () => _checkPharmacies(medName.split(" ")[0]), // Use first word for better search
                  icon: const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                  label: const Text('Find Local', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                )
              ]),
            );
          }),
        ],

        if (rx['instructions'] != null && rx['instructions'].toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.info.withAlpha(10), borderRadius: BorderRadius.circular(10)),
            child: Text(rx['instructions'], style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontStyle: FontStyle.italic)),
          ),
        ],
      ]),
    ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1);
  }
}

class _PharmacyBottomSheet extends StatefulWidget {
  final String medicine;
  final ApiService api;
  const _PharmacyBottomSheet({required this.medicine, required this.api});
  @override
  State<_PharmacyBottomSheet> createState() => _PharmacyBottomSheetState();
}

class _PharmacyBottomSheetState extends State<_PharmacyBottomSheet> {
  List _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.api.checkPharmacyStock(widget.medicine);
      if (mounted) setState(() { _results = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkSecondary.withAlpha(200) : Colors.white.withAlpha(220),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Colors.white.withAlpha(isDark ? 20 : 100), width: 1.5))
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Local Availability', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
          IconButton(icon: Icon(LucideIcons.x, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary), onPressed: () => Navigator.pop(context))
        ]),
        Text('Searching for: ${widget.medicine}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_results.isEmpty) Expanded(child: Center(child: Text('No local stock found', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))))
        else Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (ctx, i) {
              final p = _results[i];
              final inStock = p['stock_status'] == 'In Stock';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: inStock ? AppColors.success.withAlpha(50) : AppColors.error.withAlpha(50))
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(p['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: inStock ? AppColors.success.withAlpha(20) : AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Text(p['stock_status'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: inStock ? AppColors.success : AppColors.error))
                    )
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${p['distance_km']} km away • ${p['address']}', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Price: \$${p['price'].toString()}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    Text('Phone: ${p['phone']}', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                  ])
                ])
              );
            }
          )
        )
      ]),
    )));
  }
}
