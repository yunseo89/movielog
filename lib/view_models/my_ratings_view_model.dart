import '../data/services/api_error.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;

  final Map<int, TmdbMovieDto?> _movieCache = {};

  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  bool isWriting = false;
  bool refreshPending = false;
  String? writeMessage;

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) => _write(
    () => _service.updateRating(
      memberId: memberId,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ),
  );
  Future<void> deleteRating(int ratingId) => _write(
    () => _service.deleteRating(memberId: memberId, ratingId: ratingId),
  );

  Future<void> _write(Future<void> Function() action) async {
    if (_disposed || isWriting || refreshPending) {
      throw StateError('목록을 새로고침한 뒤 다시 시도해 주세요.');
    }
    isWriting = true;
    writeMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      if (_disposed) return;
      writeMessage = apiErrorMessage(error);
      if (shouldRefreshAfterRatingError(error)) await load();
      if (_disposed) return;
      isWriting = false;
      notifyListeners();
      throw StateError(writeMessage!);
    }
    if (_disposed) return;
    // 쓰기는 완료됐습니다. 이 뒤의 GET 실패는 쓰기 실패로 던지지 않습니다.
    refreshPending = true;
    writeMessage = '저장 완료';
    await load();
    if (_disposed) return;
    isWriting = false;
    notifyListeners();
  }

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;

    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final rawRatings = await _service.fetchMyRatings(memberId);

      if (_disposed || version != _requestVersion) return;

      final entries = <RatingWithMovie>[];
      var missingMovies = 0;

      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;

        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // TMDB 조회 실패 시 다음 로딩에서 다시 시도합니다.
          }
        }

        final movie = _movieCache[rating.movieId];

        if (movie == null) {
          missingMovies++;
        }

        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }

      if (_disposed || version != _requestVersion) return;

      ratings = entries;
      refreshPending = false;

      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;

      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } catch (error) {
      if (_disposed || version != _requestVersion) return;

      status = MyRatingsLoadStatus.error;
      message = refreshPending
          ? '저장은 완료됐지만 목록을 불러오지 못했습니다. 목록 새로고침만 재시도해 주세요.'
          : apiErrorMessage(error);
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
