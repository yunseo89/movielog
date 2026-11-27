import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import 'response_parser.dart';

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio;
  final Dio _authDio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v8/members/$memberId/ratings');
    if (response.statusCode != 200 || response.data is! List) {
      throw StateError('공개 평점 조회 응답 오류');
    }
    return (response.data as List)
        .map((e) => RatingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async =>
      parseResult(
        await _authDio.post('/v8/ratings', data: request.toJson()),
        201,
        (v) => RatingDto.fromJson(v as Map<String, dynamic>),
      );
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final trimmed = comment?.trim();
    if ((trimmed?.length ?? 0) > 500) throw ArgumentError('코멘트는 500자 이하입니다.');
    return parseResult(
      await _authDio.patch(
        '/v8/ratings/$ratingId',
        data: {
          'score': score,
          'comment': trimmed == null || trimmed.isEmpty ? null : trimmed,
        },
      ),
      200,
      (v) => RatingDto.fromJson(v as Map<String, dynamic>),
    );
  }

  Future<void> deleteRating(int ratingId) async =>
      parseEmptyResult(await _authDio.delete('/v8/ratings/$ratingId'));
}
