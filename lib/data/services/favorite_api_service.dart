import 'package:dio/dio.dart';

import '../models/favorite_response_dto.dart';
import '../models/favorite_check_dto.dart';
import 'response_parser.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio);
  final Dio _dio;
  static const path = '/v8/favorites';
  Future<FavoriteResponseDto> addFavorite({required int movieId}) async =>
      parseResult(
        await _dio.post(path, data: {'movieId': movieId}),
        201,
        FavoriteResponseDto.fromJson,
      );
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async => parseResult(
    await _dio.get(path),
    200,
    (value) => (value as List).map(FavoriteResponseDto.fromJson).toList(),
  );
  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async =>
      parseResult(
        await _dio.get('$path/$movieId'),
        200,
        (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
      );
  Future<void> deleteFavorite({required int movieId}) async =>
      parseEmptyResult(await _dio.delete('$path/$movieId'));
}
