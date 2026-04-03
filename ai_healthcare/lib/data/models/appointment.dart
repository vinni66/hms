class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final String location;
  final String notes;
  final bool isCompleted;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    this.location = '',
    this.notes = '',
    this.isCompleted = false,
  });

  Appointment copyWith({
    String? id,
    String? doctorName,
    String? specialty,
    DateTime? dateTime,
    String? location,
    String? notes,
    bool? isCompleted,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'notes': notes,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      doctorName: map['doctorName'],
      specialty: map['specialty'],
      dateTime: DateTime.parse(map['dateTime']),
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
