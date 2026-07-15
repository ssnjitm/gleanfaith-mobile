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
  final dio = DioClient.create(storageService: storage);
  final talker = ref.watch(talkerProvider);
  dio.interceptors.add(TalkerDioLogger(talker: talker));
  return dio;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(ref.watch(connectivityProvider));
});
