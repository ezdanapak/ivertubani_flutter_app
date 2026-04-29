import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';

/// Centralized Dio factory.
///
/// Creates a [Dio] instance with:
///  • Explicit connect / receive / send timeouts
///  • RetryInterceptor (3 attempts, exponential back-off: 1 s → 2 s → 3 s)
class DioService {
  DioService._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: (msg) => debugPrint('[Dio Retry] $msg'),
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryableExtraStatuses: {408, 429, 500, 502, 503, 504},
      ),
    );

    return dio;
  }
}
