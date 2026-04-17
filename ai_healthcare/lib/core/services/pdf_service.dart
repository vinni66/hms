import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generatePrescriptionPdf(Map<String, dynamic> rx, Map<String, dynamic> patient) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd/MM/yyyy').format(
      DateTime.tryParse(rx['date_issued'] ?? '') ?? DateTime.now(),
    );

    List meds = [];
    try {
      meds = rx['medications'] is String 
          ? jsonDecode(rx['medications']) 
          : (rx['medications'] ?? []);
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0), // Full bleed for header/footer
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 20),
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColor.fromInt(0xFF667EEA), PdfColor.fromInt(0xFF764BA2)],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Dr. ${rx['doctor_name'] ?? 'Doctor Name'}',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.Text('MBBS, MD - Specialist ${rx['diagnosis'] ?? ''}',
                          style: const pw.TextStyle(
                              fontSize: 12, color: PdfColors.white)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('GM HOSPITAL',
                          style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.Text('Smart Healthcare System',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Patient Info Row
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _infoItem('Patient Name', patient['name'] ?? 'N/A'),
                        _infoItem('Age/Sex', '${patient['age'] ?? 'N/A'} / ${patient['gender'] ?? 'N/A'}'),
                        _infoItem('Date', dateStr),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _infoItem('Diagnosis', rx['diagnosis'] ?? 'General Consultation'),
                  
                  pw.SizedBox(height: 40),

                  // Rx Icon and Content
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Rx',
                          style: pw.TextStyle(
                              fontSize: 40,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF667EEA))),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 15),
                            if (meds.isEmpty)
                              pw.Text('No specific medications listed.',
                                  style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic))
                            else
                              ...meds.map((m) {
                                final name = m is Map ? m['name'] : m.toString();
                                final dosage = m is Map ? (m['dosage'] ?? '') : '';
                                final time = m is Map ? (m['timing'] ?? '') : '';
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 12),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(name, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                                      if (dosage.isNotEmpty || time.isNotEmpty)
                                        pw.Text('$dosage - $time', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 40),

                  // Instructions
                  if (rx['instructions'] != null && rx['instructions'].toString().isNotEmpty) ...[
                    pw.Text('Instructions:',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(rx['instructions'],
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                    ),
                  ],
                  
                  pw.SizedBox(height: 60),

                  // Signature Placeholder
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('Doctor\'s Signature', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GM Hospital & Research Center',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('123 Medical Square, Healthcare City, IN',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Phone: +91 98765 43210', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Email: prescriptions@gmhospital.com', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Trigger printing/saving
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prescription_${rx['id'] ?? 'Doc'}.pdf',
    );
  }

  static pw.Widget _infoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
