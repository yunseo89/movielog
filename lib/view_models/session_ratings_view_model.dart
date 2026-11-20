import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';

class SessionRatingsViewModel extends ChangeNotifier {
  SessionRatingsViewModel(this._api, this._auth)
    : _version = _auth.sessionVersion {
    _auth.addListener(_sessionChanged);
  }
  final RatingApiService _api;
  final AuthViewModel _auth;
  int _version;
  bool _disposed = false;
  bool isWriting = false;
  final List<RatingDto> _ratings = [];
  final Map<int, TmdbMovieDto> _movies = {};
  List<RatingDto> get ratings => List.unmodifiable(_ratings);
  TmdbMovieDto? movieFor(int movieId) => _movies[movieId];
  void _sessionChanged() {
    if (_version == _auth.sessionVersion) return;
    _version = _auth.sessionVersion;
    _ratings.clear();
    _movies.clear();
    isWriting = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> create(
    TmdbMovieDto movie, {
    required int score,
    String? comment,
  }) => _write(() async {
    final result = await _api.createRating(
      CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
    );
    return () {
      _ratings.removeWhere((r) => r.ratingId == result.ratingId);
      _ratings.insert(0, result);
      _movies[movie.id] = movie;
    };
  });
  Future<void> update(int ratingId, {required int score, String? comment}) =>
      _write(() async {
        final result = await _api.updateRating(
          ratingId: ratingId,
          score: score,
          comment: comment,
        );
        return () {
          final index = _ratings.indexWhere((r) => r.ratingId == ratingId);
          if (index >= 0) _ratings[index] = result;
        };
      }, missingRatingId: ratingId);
  Future<void> delete(int ratingId) => _write(() async {
    await _api.deleteRating(ratingId);
    return () => _ratings.removeWhere((r) => r.ratingId == ratingId);
  }, missingRatingId: ratingId);
  Future<void> _write(
    Future<void Function()> Function() action, {
    int? missingRatingId,
  }) async {
    final version = _auth.sessionVersion;
    if (_disposed || !_auth.isSignedInVersion(version) || isWriting) {
      throw StateError('로그인 상태와 진행 중인 요청을 확인해 주세요.');
    }
    isWriting = true;
    notifyListeners();
    try {
      final apply = await action();
      if (_disposed || !_auth.isSignedInVersion(version)) {
        throw StateError('로그인 세션이 변경되었습니다.');
      }
      apply();
    } catch (error) {
      if (!_disposed && _auth.isSignedInVersion(version)) {
        final code = apiErrorCode(error);
        if (isSessionError(error)) {
          await _auth.expireSession(expectedVersion: version);
        } else if (code == 'RATING404_1') {
          _ratings.removeWhere((r) => r.ratingId == missingRatingId);
        }
      }
      throw StateError(userErrorMessage(error));
    } finally {
      if (!_disposed && version == _auth.sessionVersion) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_sessionChanged);
    super.dispose();
  }
}
