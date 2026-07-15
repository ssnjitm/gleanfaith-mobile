class User {
  final String id;
  final String customerID;
  final String email;
  final String fullName;
  final String role;
  final String username;
  final String? phoneNumber;
  final bool isVerified;
  final bool isActive;
  final String? avatar;

  const User({
    required this.id,
    required this.customerID,
    required this.email,
    required this.fullName,
    required this.role,
    required this.username,
    this.phoneNumber,
    this.isVerified = false,
    this.isActive = true,
    this.avatar,
  });
}
