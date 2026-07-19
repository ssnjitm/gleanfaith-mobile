import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import 'api_interceptors.dart';

class DioClient {
  static ({Dio dio, TokenRefreshInterceptor refreshInterceptor}) create({
    required StorageService storageService,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final tokenRefreshInterceptor = TokenRefreshInterceptor(
      dio: dio,
      storageService: storageService,
    );

    dio.interceptors.addAll([
      AuthInterceptor(storageService: storageService),
      LoggingInterceptor(),
      tokenRefreshInterceptor,
    ]);

    return (dio: dio, refreshInterceptor: tokenRefreshInterceptor);
  }
}
