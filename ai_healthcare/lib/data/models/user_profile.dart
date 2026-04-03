class UserProfile {
  final String name;
  final int age;
  final String bloodGroup;
  final String allergies;
  final String emergencyContact;
  final bool onboarded;

  UserProfile({
    this.name = 'User',
    this.age = 0,
    this.bloodGroup = '',
    this.allergies = '',
    this.emergencyContact = '',
    this.onboarded = false,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? bloodGroup,
    String? allergies,
    String? emergencyContact,
    bool? onboarded,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      onboarded: onboarded ?? this.onboarded,
    );
  }
}
