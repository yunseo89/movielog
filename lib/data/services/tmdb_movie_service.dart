import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_page.dart';

class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  // 인기 영화 목록을 요청한다.
  Future<TmdbMoviePageDto> fetchPopular({
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
      },
    );

    return TmdbMoviePageDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // 영화 목록을 요청한다.
  // genreId가 있으면 해당 장르의 영화만 요청한다.
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        'with_genres': ?genreId,
      },
    );

    return TmdbMoviePageDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // TMDB에서 실제 장르 목록을 가져온다.
  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get(
      '/genre/movie/list',
      queryParameters: {
        'language': 'ko',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>? ?? const [];

    return genres
        .map(
          (item) => TmdbGenreDto.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}