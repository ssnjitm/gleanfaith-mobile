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

  /// Header set on a request that has already been retried after a token
  /// refresh. Prevents an infinite refresh loop when the retried request
  /// fails with 401 again (e.g. the endpoint rejects the user entirely).
  static const String _retryMarker = 'x-token-retried';

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

    // A retried request that still fails with 401 must not trigger another
    // refresh (or it would deadlock the pending queue forever).
    if (err.requestOptions.headers[_retryMarker] == 'true') {
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

      // Retry the original request with the fresh token. Any error here is a
      // "retry failed" case (e.g. the endpoint still rejects the user), NOT a
      // refresh failure, so tokens must be preserved.
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      err.requestOptions.headers[_retryMarker] = 'true';
      try {
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (retryError) {
        for (final pending in _pendingRequests) {
          pending.handler.next(err);
        }
        _pendingRequests.clear();
        handler.next(err);
        return;
      }

      for (final pending in _pendingRequests) {
        try {
          pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
          pending.options.headers[_retryMarker] = 'true';
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
