import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/liquid_background.dart';
import '../../widgets/vitals_chart.dart';
import '../../../data/services/ocr_service.dart';

class PatientRecords extends StatefulWidget {
  const PatientRecords({super.key});
  @override
  State<PatientRecords> createState() => _PatientRecordsState();
}

class _PatientRecordsState extends State<PatientRecords> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _picker = ImagePicker();
  late TabController _tabC;
  List _metrics = [];
  List _reports = [];
  bool _loading = true;
  bool _analyzing = false;
  String _selectedMetricType = 'Heart Rate';

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 2, vsync: this);
    _tabC.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_api.getMetrics(), _api.getReports()]);
      _metrics = results[0];
      _reports = results[1];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Health Records', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tabC,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            tabs: const [
              Tab(text: 'Vitals & Metrics'),
              Tab(text: 'Scanned Reports'),
            ],
          ),
        ),
        body: LiquidBackground(
          child: _loading || _analyzing
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: AppColors.primary),
                if (_analyzing) const Padding(padding: EdgeInsets.only(top: 16), child: Text('Rakshak AI is analyzing report...')),
              ]))
            : TabBarView(
                controller: _tabC,
                children: [
                   _buildVitalsFeed(isDark),
                   _buildReportsFeed(isDark),
                ],
              ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: Icon(_tabC.index == 0 ? LucideIcons.plus : LucideIcons.scanLine, color: Colors.white),
          label: Text(_tabC.index == 0 ? 'Log Vital' : 'Smart Scan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => _tabC.index == 0 ? _addVital(context) : _addReport(context),
        ),
      );
  }

  Widget _buildVitalsFeed(bool isDark) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 100, 24, 100),
        itemCount: _metrics.isEmpty ? 1 : _metrics.length + 1, 
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightButton(isDark),
                const SizedBox(height: 16),
                if (_metrics.isNotEmpty) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('$_selectedMetricType Trends', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _metrics.any((m) => (m['metric_type'] ?? m['type']) == _selectedMetricType) 
                        ? _selectedMetricType 
                        : (_metrics.first['metric_type'] ?? _metrics.first['type']),
                      underline: const SizedBox(),
                      items: _metrics.map((m) => (m['metric_type'] ?? m['type']) as String).toSet().map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) => setState(() => _selectedMetricType = val!),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  VitalsChart(metrics: _metrics, type: _selectedMetricType, color: AppColors.primary),
                  const SizedBox(height: 24),
                  const Text('Recent Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ] else 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No vital metrics recorded yet.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
                  ),
              ],
            );
          }
          final m = _metrics[i - 1];
          final dt = DateTime.tryParse(m['date_recorded'] ?? '') ?? DateTime.now();
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                child: Icon(m['metric_type'] == 'Heart Rate' ? LucideIcons.heartPulse : LucideIcons.activity, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['metric_type'] ?? 'Unknown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                Text(DateFormat('MMM dd, yyyy - hh:mm a').format(dt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
              ])),
              Text('${m['value']} ${m['unit'] ?? ''}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]),
          ).animate().fadeIn(delay: (i * 60).ms);
        },
      ),
    );
  }

  Widget _buildReportsFeed(bool isDark) {
    if (_reports.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.fileSearch, size: 50, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
          const SizedBox(height: 12),
          Text('No reports scanned yet.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
          const SizedBox(height: 8),
          Text('Upload medical reports for AI analysis.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 12)),
        ])
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 100, 24, 100),
        itemCount: _reports.length,
        itemBuilder: (ctx, i) {
          final r = _reports[i];
          final dt = DateTime.tryParse(r['upload_date'] ?? '') ?? DateTime.now();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(isDark ? 10 : 80)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 20 : 10), blurRadius: 20)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(r['title'] ?? 'Scanned Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight))),
                Text(DateFormat('MMM dd').format(dt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDark ? Colors.black12 : AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
                child: Text(r['ai_summary'] ?? 'No summary available. Analysis pending.', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, height: 1.4, fontSize: 13)),
              )
            ]),
          ).animate().fadeIn(delay: (i * 60).ms);
        },
      ),
    );
  }

  Widget _buildInsightButton(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Rakshak AI Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Analyze your health trends', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
        ])),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _showAIInsight,
          child: const Text('Analyze'),
        ),
      ]),
    );
  }

  void _showAIInsight() async {
    showDialog(context: context, builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)));
    try {
      final res = await _api.getMetricsAnalysis();
      if (mounted) Navigator.pop(context);
      
      if (res['risk_level'] == 'High' || res['risk_level'] == 'Emergency') {
        NotificationService().showNotification(
          title: 'Critical Health Insight',
          body: 'Low accuracy in vitals detected or high-risk finding identified. Please review.',
          importance: Importance.max,
          priority: Priority.high,
        );
      }

      showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? AppColors.bgDarkSecondary : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(LucideIcons.sparkles, color: AppColors.success),
              const SizedBox(width: 12),
              Text('Health Analysis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
            ]),
            const SizedBox(height: 20),
            Text(res['text'] ?? 'No analysis available.', style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withAlpha(10), borderRadius: BorderRadius.circular(12)), child: Row(children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Disclaimer: AI analysis is for informational purposes only. Always consult a certified physician for diagnosis.', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold))),
            ])),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 12),
          ]),
        );
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _addVital(BuildContext context) {
    final typeC = TextEditingController();
    final valC = TextEditingController();
    final unitC = TextEditingController();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: BoxDecoration(color: isDark ? AppColors.bgDarkSecondary : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Log Vital Metric', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
          const SizedBox(height: 16),
          TextField(controller: typeC, decoration: const InputDecoration(hintText: 'Type (e.g. Heart Rate, Weight)')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: valC, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Value'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: unitC, decoration: const InputDecoration(hintText: 'Unit'))),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () async {
              if (typeC.text.isNotEmpty && valC.text.isNotEmpty) {
                await _api.addMetric({'metric_type': typeC.text, 'value': double.tryParse(valC.text) ?? 0, 'unit': unitC.text});
                if (mounted) { Navigator.pop(ctx); _load(); }
              }
            },
            child: const Text('Save Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ]),
      );
    });
  }

  Future<void> _addReport(BuildContext context) async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img == null) return;
    
    setState(() => _analyzing = true);
    try {
      final bytes = await img.readAsBytes();
      final base64Str = base64Encode(bytes);
      
      // 1. Extract text locally using OCR
      String ocrText = '';
      try { ocrText = await OcrService().extractTextFromImage(img.path); } catch (_) {}

      // 2. Create the record
      final report = await _api.createReport({
        'title': 'Scan - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
        'file_url': 'Local Scan'
      });
      
      // 3. Analyze with AI (sending both image and extracted text)
      await _api.analyzeReport(report['id'], text: ocrText, imageBase64: base64Str);
      
      if (mounted) _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }
}
