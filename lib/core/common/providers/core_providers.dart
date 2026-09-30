import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../network/dio_client.dart';
import '../../network/network_info.dart';
import '../../services/logger_service.dart';
import '../../services/storage_service.dart';
import '../../constants/api_constants.dart';

final talkerProvider = Provider<Talker>((ref) {
  final talker = TalkerFlutter.init();
  LoggerService.init(talker);
  return talker;
});

final storageProvider = Provider<StorageService>((ref) {
  return StorageService(const FlutterSecureStorage());
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageProvider);
  final result = DioClient.create(storageService: storage);
  final talker = ref.watch(talkerProvider);
  result.dio.interceptors.add(TalkerDioLogger(talker: talker));
  ref.onDispose(() => result.dio.close());
  return result.dio;
});

/// Plain Dio for the free, keyless Bible API (`ApiConstants.freeBibleBaseUrl`).
///
/// Intentionally *not* built by `DioClient.create`: that client attaches the
/// auth header, the token-refresh interceptor and the 30s timeouts, none of
/// which belong on a third-party host. Keeping it separate also means a slow or
/// dead third party can never stall the app's own requests.
final freeBibleDioProvider = Provider<Dio>((ref) {
  final talker = ref.watch(talkerProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.freeBibleBaseUrl,
      connectTimeout: ApiConstants.freeBibleTimeout,
      receiveTimeout: ApiConstants.freeBibleTimeout,
      sendTimeout: ApiConstants.freeBibleTimeout,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(TalkerDioLogger(talker: talker));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

/// Unauthenticated Dio for the app's own release-check endpoint.
///
/// Separate from `dioProvider` for one reason that matters: `DioClient` attaches
/// the auth header *and* the token-refresh interceptor. A user whose token has
/// expired or whose session is otherwise broken is precisely the person who most
/// needs to update out of a bad release, so the check must never depend on a
/// working token — a 401 here would silently disable updates for exactly the
/// users who need them. `AppUpdateService` also runs before sign-in on some
/// paths.
///
/// Uses the same host as the main API (only the interceptors differ), so a new
/// base URL is not introduced by accident.
final appUpdateDioProvider = Provider<Dio>((ref) {
  final talker = ref.watch(talkerProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.appUpdateTimeout,
      receiveTimeout: ApiConstants.appUpdateTimeout,
      sendTimeout: ApiConstants.appUpdateTimeout,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(TalkerDioLogger(talker: talker));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});


final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(ref.watch(connectivityProvider));
});
