class WellnessGoal {
  final String id;
  final String userId;
  final String type; // 'water', 'steps', 'calories', 'sleep'
  final double targetValue;
  final String unit;
  final DateTime updatedAt;

  WellnessGoal({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.unit,
    required this.updatedAt,
  });

  factory WellnessGoal.fromJson(Map<String, dynamic> json) {
    return WellnessGoal(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      targetValue: (json['target_value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'target_value': targetValue,
      'unit': unit,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
