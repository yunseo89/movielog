import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  int? selectedGenreId;

  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  bool get isLoading => status == MovieListLoadStatus.loading;

  bool _disposed = false;
  int _requestVersion = 0;

  // 처음 화면에 진입했을 때 장르와 영화 목록을 불러온다.
  Future<void> loadInitial() async {
    await _load(genreId: selectedGenreId, loadGenres: true);
  }

  // 장르를 선택하면 해당 장르의 영화를 다시 요청한다.
  // null이면 전체 목록을 요청한다.
  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return;

    selectedGenreId = genreId;

    await _load(genreId: genreId, loadGenres: false);
  }

  // 기본적인 오류 재시도 기능
  Future<void> retry() async {
    if (isLoading) return;

    if (genres.isEmpty) {
      await loadInitial();
    } else {
      await selectGenre(selectedGenreId);
    }
  }

  Future<void> _load({required int? genreId, required bool loadGenres}) async {
    final version = ++_requestVersion;

    status = MovieListLoadStatus.loading;
    message = null;

    // Challenge의 기존 목록 유지 기능은 구현하지 않는다.
    movies = const [];

    notifyListeners();

    try {
      if (loadGenres) {
        genres = await _service.fetchGenres();
      }

      if (_disposed || version != _requestVersion) return;

      final result = await _fetchUpToThirtyMovies(genreId: genreId);

      if (_disposed || version != _requestVersion) return;

      movies = result;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;

      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (_disposed || version != _requestVersion) return;

      status = MovieListLoadStatus.error;
      message = '영화 정보를 처리하는 중 문제가 발생했어요.';
    }

    if (!_disposed && version == _requestVersion) {
      notifyListeners();
    }
  }

  // Discover API를 이용해 중복 없는 영화 최대 30개를 만든다.
  Future<List<TmdbMovieDto>> _fetchUpToThirtyMovies({
    required int? genreId,
  }) async {
    final moviesById = <int, TmdbMovieDto>{};

    var pageNumber = 1;
    var hasNextPage = true;

    while (moviesById.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        moviesById[movie.id] = movie;

        if (moviesById.length == 30) {
          break;
        }
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;

      pageNumber++;
    }

    return moviesById.values.take(30).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
