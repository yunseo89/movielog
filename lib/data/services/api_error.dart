import 'package:dio/dio.dart';

import '../models/common_response.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      try {
        return CommonResponse<Object?>.fromJson(data, (value) => value).message;
      } on Object {
        /* 비공통 오류 응답은 일반 안내로 처리합니다. */
      }
    }
    return switch (error.response?.statusCode) {
      400 => '입력값을 확인해 주세요. (400)',
      403 => '본인이 작성한 평점만 변경할 수 있습니다. (403)',
      404 => '회원 또는 평점을 찾을 수 없습니다. (404)',
      409 => '이미 등록된 정보입니다. (409)',
      _ => '서버에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요.',
    };
  }
  return '응답을 확인하지 못했습니다. 다시 전송하기 전에 서버 상태를 확인해 주세요.';
}

bool shouldRefreshAfterRatingError(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  final code = data is Map ? data['code'] : null;
  return code == 'COMMON403' ||
      code == 'COMMON404' ||
      error.response?.statusCode == 403 ||
      error.response?.statusCode == 404;
}
