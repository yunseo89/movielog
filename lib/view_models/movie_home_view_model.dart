import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus {
  idle,
  loading,
  success,
  empty,
  error,
}

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message;

  bool _disposed = false;
  int _requestVersion = 0;

  Future<void> loadPopular() async {
    final version = ++_requestVersion;

    status = MovieHomeLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();

      if (_disposed || version != _requestVersion) return;

      popularMovies = page.results.take(5).toList();

      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;

      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    } catch (_) {
      if (_disposed || version != _requestVersion) return;

      status = MovieHomeLoadStatus.error;
      message = '영화 정보를 처리하는 중 문제가 발생했어요.';
    }

    if (!_disposed && version == _requestVersion) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}