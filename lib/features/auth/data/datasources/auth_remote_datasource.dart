import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> registerRequest({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    await _dio.post(
      ApiConstants.registerRequest,
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'username': username,
      },
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await _dio.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> resendOtp(String email) async {
    await _dio.post(
      ApiConstants.resendOtp,
      data: {'email': email},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiConstants.resetPassword,
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _dio.post(ApiConstants.logout);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get(ApiConstants.userMe);
    final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userData);
  }
}
