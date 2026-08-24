import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/profile_models.dart';

class ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSource(this._dio);

  Future<UserProfileModel> getProfile() async {
    final response = await _dio.get(ApiConstants.userProfile);
    return UserProfileModel.fromJson(_extractUser(response.data));
  }

  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? username,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null && username.isNotEmpty) body['username'] = username;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    final response = await _dio.put(
      ApiConstants.userProfile,
      data: body,
    );
    return UserProfileModel.fromJson(_extractUser(response.data));
  }

  Future<UserProfileModel> updateAvatar(String avatarUrl) async {
    final response = await _dio.patch(
      '${ApiConstants.userProfile}/avatar',
      data: {'avatar': avatarUrl},
    );
    return UserProfileModel.fromJson(_extractUser(response.data));
  }

  Future<void> deleteAvatar() async {
    await _dio.delete('${ApiConstants.userProfile}/avatar');
  }

  Future<AccountStatsModel> getAccountStats() async {
    final response = await _dio.get(ApiConstants.userStats);
    return AccountStatsModel.fromJson(_extractMap(response.data));
  }

  Map<String, dynamic> _extractUser(dynamic response) {
    final map = _extractMap(response);
    final user = map['user'];
    if (user is Map<String, dynamic>) {
      return {
        ...user,
        'avatar': user['avatar'] ?? map['avatar'],
      };
    }
    return map;
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      return response;
    }
    return {};
  }
}
