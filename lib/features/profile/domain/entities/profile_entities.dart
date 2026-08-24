class UserProfile {
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

  const UserProfile({
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
}

class AccountStats {
  final String customerID;
  final DateTime? memberSince;
  final bool isVerified;
  final bool isActive;
  final String role;

  const AccountStats({
    required this.customerID,
    this.memberSince,
    this.isVerified = false,
    this.isActive = true,
    this.role = 'user',
  });
}
