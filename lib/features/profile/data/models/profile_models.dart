import '../../domain/entities/profile_entities.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

class UserProfileModel {
  final String id;
  final String customerID;
  final String email;
  final String fullName;
  final String role;
  final String username;
  final String? phoneNumber;
  final String? avatar;
  final bool isVerified;
  final bool isActive;

  const UserProfileModel({
    required this.id,
    required this.customerID,
    required this.email,
    required this.fullName,
    required this.role,
    required this.username,
    this.phoneNumber,
    this.avatar,
    this.isVerified = false,
    this.isActive = true,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      customerID: json['customerID'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatar: (json['avatar'] as String?)?.isNotEmpty == true
          ? json['avatar'] as String
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      customerID: customerID,
      email: email,
      fullName: fullName,
      role: role,
      username: username,
      phoneNumber: phoneNumber,
      avatar: avatar,
      isVerified: isVerified,
      isActive: isActive,
    );
  }
}

class AccountStatsModel {
  final String customerID;
  final DateTime? memberSince;
  final bool isVerified;
  final bool isActive;
  final String role;

  const AccountStatsModel({
    required this.customerID,
    this.memberSince,
    this.isVerified = false,
    this.isActive = true,
    this.role = 'user',
  });

  factory AccountStatsModel.fromJson(Map<String, dynamic> json) {
    return AccountStatsModel(
      customerID: json['customerID'] as String? ?? '',
      memberSince: _parseDate(json['memberSince']),
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      role: json['role'] as String? ?? 'user',
    );
  }

  AccountStats toEntity() {
    return AccountStats(
      customerID: customerID,
      memberSince: memberSince,
      isVerified: isVerified,
      isActive: isActive,
      role: role,
    );
  }
}
