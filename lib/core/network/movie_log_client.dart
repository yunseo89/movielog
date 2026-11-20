import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

const movieLogBaseUrl = String.fromEnvironment(
  'MOVIELOG_BASE_URL',
  defaultValue: 'https://workbook.devnoco.com',
);
BaseOptions _options() => BaseOptions(
  baseUrl: movieLogBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
);
Dio createMovieLogClient() => Dio(_options());
Dio createAuthMovieLogClient(
  TokenStorage storage, {
  required int Function() sessionVersion,
  required Future<void> Function(int) onSessionExpired,
}) {
  return Dio(_options())
    ..interceptors.add(
      AuthInterceptor(
        storage,
        origin: Uri.parse(movieLogBaseUrl),
        sessionVersion: sessionVersion,
        onSessionExpired: onSessionExpired,
      ),
    );
}
