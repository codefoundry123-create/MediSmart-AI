// ════════════════════════════════════════════════════════════
// FILE LOCATION: lib/core/models/user_model.dart
// ════════════════════════════════════════════════════════════

class UserModel {
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String dob;
  final String age;
  final String bloodGroup;
  final String height;
  final String weight;
  final String? profileImageUrl;

  const UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.age,
    required this.bloodGroup,
    required this.height,
    required this.weight,
    this.profileImageUrl,
  });

  // ── Used now: dummy/local data ──────────────────────────
  factory UserModel.dummy() {
    return const UserModel(
      name: 'Annie Duffy',
      email: 'Annieduffy@gmail.com',
      phone: '(760) 653-5300',
      gender: 'Male',
      dob: 'July 12, 1998',
      age: '48 years',
      bloodGroup: 'AB+',
      height: '198 cm',
      weight: '66 KG',
    );
  }

  // ── Used later: parse data FROM your API response ───────
  // Example: UserModel.fromJson(response.data['user'])
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      age: json['age'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      height: json['height'] ?? '',
      weight: json['weight'] ?? '',
      profileImageUrl: json['profile_image_url'],
    );
  }

  // ── Used later: send data TO your API ───────────────────
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'dob': dob,
        'age': age,
        'blood_group': bloodGroup,
        'height': height,
        'weight': weight,
        'profile_image_url': profileImageUrl,
      };

  // ── Used when editing: update only changed fields ────────
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? dob,
    String? age,
    String? bloodGroup,
    String? height,
    String? weight,
    String? profileImageUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}