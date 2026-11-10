import 'package:dio/dio.dart';

Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'MOVIELOG_BASE_URL',
        defaultValue: 'https://workbook.devnoco.com',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
