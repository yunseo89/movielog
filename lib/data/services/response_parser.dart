import 'package:dio/dio.dart';

import '../models/common_response.dart';

T parseResult<T>(
  Response<dynamic> response,
  int expectedStatus,
  T Function(Object?) parse,
) {
  if (response.statusCode != expectedStatus ||
      response.data is! Map<String, dynamic>) {
    throw StateError('서버 응답 계약을 확인해 주세요.');
  }
  final common = CommonResponse<T>.fromJson(
    response.data as Map<String, dynamic>,
    parse,
  );
  if (!common.isSuccess || common.result == null) {
    throw StateError('성공 결과가 없습니다.');
  }
  return common.result as T;
}

void parseEmptyResult(Response<dynamic> response) {
  if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
    throw StateError('삭제 응답 계약 오류');
  }
  final common = CommonResponse<Object?>.fromJson(
    response.data as Map<String, dynamic>,
    (v) => v,
  );
  if (!common.isSuccess || common.result != null) {
    throw StateError('삭제 결과 계약 오류');
  }
}
