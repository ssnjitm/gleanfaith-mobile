class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com/v1';
  static const String tokenRefreshEndpoint = '/auth/refresh';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
