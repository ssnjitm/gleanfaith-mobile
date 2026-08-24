import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/notification_models.dart';

class NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSource(this._dio);

  Future<NotificationListModel> getMyNotifications({
    required int limit,
    required int skip,
    required String currentUserId,
  }) async {
    final response = await _dio.get(
      ApiConstants.notificationsUser,
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return NotificationListModel.fromJson(
      _extractMap(response.data),
      currentUserId,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch(ApiConstants.notificationMarkRead(notificationId));
  }

  Future<void> markAllAsRead() async {
    await _dio.patch(ApiConstants.notificationsUserReadAll);
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        if (data['notifications'] is List) return data;
      }
      if (response['notifications'] is List) return response;
    }
    return {};
  }
}
