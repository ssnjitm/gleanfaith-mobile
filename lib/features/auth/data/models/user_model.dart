import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

class UserModel extends Equatable {
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

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      customerID: json['customerID'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customerID': customerID,
      'email': email,
      'fullName': fullName,
      'role': role,
      'username': username,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'isActive': isActive,
      'avatar': avatar,
    };
  }

  User toEntity() {
    return User(
      id: id,
      customerID: customerID,
      email: email,
      fullName: fullName,
      role: role,
      username: username,
      phoneNumber: phoneNumber,
      isVerified: isVerified,
      isActive: isActive,
      avatar: avatar,
    );
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      customerID: entity.customerID,
      email: entity.email,
      fullName: entity.fullName,
      role: entity.role,
      username: entity.username,
      phoneNumber: entity.phoneNumber,
      isVerified: entity.isVerified,
      isActive: entity.isActive,
      avatar: entity.avatar,
    );
  }

  @override
  List<Object?> get props => [id, customerID, email, fullName, role, username];
}
