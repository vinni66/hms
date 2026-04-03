enum MetricType {
  heartRate,
  bloodPressure,
  weight,
  temperature,
  oxygenLevel,
  bloodSugar,
}

extension MetricTypeExtension on MetricType {
  String get displayName {
    switch (this) {
      case MetricType.heartRate:
        return 'Heart Rate';
      case MetricType.bloodPressure:
        return 'Blood Pressure';
      case MetricType.weight:
        return 'Weight';
      case MetricType.temperature:
        return 'Temperature';
      case MetricType.oxygenLevel:
        return 'SpO2';
      case MetricType.bloodSugar:
        return 'Blood Sugar';
    }
  }

  String get unit {
    switch (this) {
      case MetricType.heartRate:
        return 'bpm';
      case MetricType.bloodPressure:
        return 'mmHg';
      case MetricType.weight:
        return 'kg';
      case MetricType.temperature:
        return '°F';
      case MetricType.oxygenLevel:
        return '%';
      case MetricType.bloodSugar:
        return 'mg/dL';
    }
  }

  String get icon {
    switch (this) {
      case MetricType.heartRate:
        return '❤️';
      case MetricType.bloodPressure:
        return '🩸';
      case MetricType.weight:
        return '⚖️';
      case MetricType.temperature:
        return '🌡️';
      case MetricType.oxygenLevel:
        return '💨';
      case MetricType.bloodSugar:
        return '🍬';
    }
  }
}

class HealthMetric {
  final String id;
  final MetricType type;
  final double value;
  final DateTime timestamp;

  HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'],
      type: MetricType.values[map['type']],
      value: (map['value'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
