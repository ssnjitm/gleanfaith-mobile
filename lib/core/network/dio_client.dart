import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';
import 'api_interceptors.dart';
import 'cache/http_cache_interceptor.dart';

class DioClient {
  static ({
    Dio dio,
    TokenRefreshInterceptor refreshInterceptor,
    HttpCacheInterceptor? cacheInterceptor,
  }) create({
    required StorageService storageService,
    HttpCacheInterceptor? cacheInterceptor,
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

    // Order is load-bearing:
    //   Auth    — attaches the bearer token before anything reads the request.
    //   Cache   — may resolve the request without it ever reaching the network.
    //   Logging — only sees requests that are actually going out.
    //   Refresh — reacts to 401s last, after the cache has declined to mask one.
    dio.interceptors.add(AuthInterceptor(storageService: storageService));
    if (cacheInterceptor != null) {
      dio.interceptors.add(cacheInterceptor);
    }
    dio.interceptors.addAll([
      LoggingInterceptor(),
      tokenRefreshInterceptor,
    ]);

    return (
      dio: dio,
      refreshInterceptor: tokenRefreshInterceptor,
      cacheInterceptor: cacheInterceptor,
    );
  }
}
