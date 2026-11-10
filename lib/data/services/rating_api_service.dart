import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import 'api_error.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    return (response.data as List<dynamic>)
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _checkWrite(Response<dynamic> response, int status) {
    if (response.statusCode != status) throw StateError('예상하지 못한 평점 응답');
    final common = CommonResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => value,
    );
    if (!common.isSuccess) throw StateError('평점 응답 실패');
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    _checkWrite(response, 201); // result는 숫자 또는 null일 수 있어 캐스팅하지 않습니다.
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final trimmed = comment?.trim();
    if ((trimmed?.length ?? 0) > 500) throw ArgumentError('코멘트는 500자 이하입니다.');
    final response = await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {
        'score': score,
        'comment': trimmed == null || trimmed.isEmpty ? null : trimmed,
      },
    );
    _checkWrite(response, 200);
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) throw StateError('예상하지 못한 삭제 응답');
    // 204 응답에는 본문이 없습니다.
  }
}

String writeMyRatingsErrorMessage(DioException error) => apiErrorMessage(error);
