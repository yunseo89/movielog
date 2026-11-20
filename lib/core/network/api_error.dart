import 'package:dio/dio.dart';

String? apiErrorCode(Object error) {
  final data = error is DioException ? error.response?.data : null;
  return data is Map && data['code'] is String ? data['code'] as String : null;
}

String? apiErrorMessage(Object error) {
  final data = error is DioException ? error.response?.data : null;
  return data is Map && data['message'] is String
      ? data['message'] as String
      : null;
}

bool isSessionError(Object error) =>
    error is DioException &&
    error.response?.statusCode == 401 &&
    const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(apiErrorCode(error));
String userErrorMessage(Object error) =>
    apiErrorMessage(error) ?? '요청을 완료하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
