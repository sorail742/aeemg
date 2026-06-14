class MemberProfile {
  const MemberProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.section,
    this.specialty,
    this.avatarUrl,
    required this.role,
    required this.isProfilePublic,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String? section;
  final String? specialty;
  final String? avatarUrl;
  final String role;
  final bool isProfilePublic;
  final DateTime createdAt;

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      section: json['section'] as String?,
      specialty: json['specialty'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      isProfilePublic: json['is_profile_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'section': section,
        'specialty': specialty,
        'is_profile_public': isProfilePublic,
      };

  bool get isStaff =>
      const {'super_admin', 'admin', 'moderator', 'section_lead'}.contains(role);

  bool get isTreasurer => role == 'treasurer' || isStaff;

  String get roleLabel => switch (role) {
        'super_admin' => 'Super Admin',
        'admin' => 'Administrateur',
        'moderator' => 'Modérateur',
        'treasurer' => 'Trésorier',
        'section_lead' => 'Responsable section',
        'volunteer' => 'Bénévole',
        _ => 'Membre',
      };
}
