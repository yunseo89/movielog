import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/api_error.dart';
import '../data/services/rating_api_service.dart';
import 'sign_up_view_model.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.memberId, this.movie);
  final RatingApiService _service;
  final int? memberId;
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;
  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    if (memberId == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 학습용 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _service.createRating(
        memberId: memberId!,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
      submitMessage = '평점을 등록했습니다. 마이페이지에서 확인해 주세요.';
    } catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = apiErrorMessage(error);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
