/// Mirrors the backend's `publicUser()` payload exactly.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? gender;
  final String avatar;
  final String role; // rider | admin
  final String status; // active | suspended
  final VerifiedFlags verified;
  final KycInfo kyc;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.gender,
    this.avatar = '',
    this.role = 'rider',
    this.status = 'active',
    this.verified = const VerifiedFlags(),
    this.kyc = const KycInfo(),
  });

  bool get isAdmin => role == 'admin';
  bool get isKycVerified => verified.govId;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        gender: json['gender'] as String?,
        avatar: json['avatar'] as String? ?? '',
        role: json['role'] as String? ?? 'rider',
        status: json['status'] as String? ?? 'active',
        verified: VerifiedFlags.fromJson(
            json['verified'] as Map<String, dynamic>? ?? const {}),
        kyc:
            KycInfo.fromJson(json['kyc'] as Map<String, dynamic>? ?? const {}),
      );

  AppUser copyWith({String? name, String? phone, String? gender, String? avatar}) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        gender: gender ?? this.gender,
        avatar: avatar ?? this.avatar,
        role: role,
        status: status,
        verified: verified,
        kyc: kyc,
      );
}

class VerifiedFlags {
  final bool email;
  final bool phone;
  final bool govId;
  const VerifiedFlags({this.email = false, this.phone = false, this.govId = false});

  factory VerifiedFlags.fromJson(Map<String, dynamic> j) => VerifiedFlags(
        email: j['email'] as bool? ?? false,
        phone: j['phone'] as bool? ?? false,
        govId: j['govId'] as bool? ?? false,
      );
}

class KycInfo {
  final String status; // none | pending | verified | rejected
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final bool hasSelfie;

  const KycInfo({
    this.status = 'none',
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.hasSelfie = false,
  });

  factory KycInfo.fromJson(Map<String, dynamic> j) => KycInfo(
        status: j['status'] as String? ?? 'none',
        submittedAt: DateTime.tryParse(j['submittedAt']?.toString() ?? ''),
        reviewedAt: DateTime.tryParse(j['reviewedAt']?.toString() ?? ''),
        rejectionReason: j['rejectionReason'] as String?,
        hasSelfie: j['hasSelfie'] as bool? ?? false,
      );
}
