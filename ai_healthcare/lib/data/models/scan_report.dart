class ScanFinding {
  final String label;
  final String value;
  final bool isNormal;

  ScanFinding({
    required this.label,
    required this.value,
    this.isNormal = true,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'value': value,
    'isNormal': isNormal,
  };

  factory ScanFinding.fromMap(Map<String, dynamic> map) => ScanFinding(
    label: map['label'],
    value: map['value'],
    isNormal: map['isNormal'] ?? true,
  );
}

class ScanReport {
  final String id;
  final String imagePath;
  final String extractedText;
  final String aiSummary;
  final List<ScanFinding> findings;
  final DateTime timestamp;

  ScanReport({
    required this.id,
    required this.imagePath,
    this.extractedText = '',
    this.aiSummary = '',
    this.findings = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'aiSummary': aiSummary,
      'findings': findings.map((f) => '${f.label}|${f.value}|${f.isNormal}').join(';;'),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanReport.fromMap(Map<String, dynamic> map) {
    final findingsStr = map['findings'] as String? ?? '';
    final parsedFindings = findingsStr.isEmpty
        ? <ScanFinding>[]
        : findingsStr.split(';;').map((f) {
            final parts = f.split('|');
            return ScanFinding(
              label: parts[0],
              value: parts.length > 1 ? parts[1] : '',
              isNormal: parts.length > 2 ? parts[2] == 'true' : true,
            );
          }).toList();

    return ScanReport(
      id: map['id'],
      imagePath: map['imagePath'] ?? '',
      extractedText: map['extractedText'] ?? '',
      aiSummary: map['aiSummary'] ?? '',
      findings: parsedFindings,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
