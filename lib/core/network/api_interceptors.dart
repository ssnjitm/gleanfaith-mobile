import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService? _storageService;

  AuthInterceptor({StorageService? storageService})
      : _storageService = storageService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_storageService != null) {
      final token = await _storageService.read(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final StorageService _storageService;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  TokenRefreshInterceptor({
    required Dio dio,
    required StorageService storageService,
  })  : _dio = dio,
        _storageService = storageService;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.path.contains(ApiConstants.refreshToken)) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _pendingRequests.add(_PendingRequest(
        options: err.requestOptions,
        handler: handler,
      ));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storageService.read(AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        LoggerService.warning('No refresh token available - cannot refresh');
        await _clearTokens();
        handler.next(err);
        return;
      }

      LoggerService.info('Refreshing expired token...');
      final refreshDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));

      final refreshResponse = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data['data'] as Map<String, dynamic>? ?? refreshResponse.data;
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw DioException(
          requestOptions: err.requestOptions,
          message: 'Refresh failed - no access token returned',
        );
      }

      await _storageService.write(AppConstants.tokenKey, newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storageService.write(AppConstants.refreshTokenKey, newRefreshToken);
      }

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      handler.resolve(retryResponse);

      for (final pending in _pendingRequests) {
        try {
          pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
          final response = await _dio.fetch(pending.options);
          pending.handler.resolve(response);
        } catch (e) {
          pending.handler.reject(e as DioException);
        }
      }
      _pendingRequests.clear();
    } catch (_) {
      await _clearTokens();
      for (final pending in _pendingRequests) {
        pending.handler.next(err);
      }
      _pendingRequests.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearTokens() async {
    await _storageService.delete(AppConstants.tokenKey);
    await _storageService.delete(AppConstants.refreshTokenKey);
    await _storageService.delete(AppConstants.userIdKey);
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.options, required this.handler});
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LoggerService.info('REQUEST: ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LoggerService.info('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggerService.error('ERROR: ${err.message} ${err.requestOptions.path}');
    handler.next(err);
  }
}
