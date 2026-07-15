import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import 'api_interceptors.dart';

class DioClient {
  static Dio create({StorageService? storageService}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storageService: storageService),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    return dio;
  }
}
