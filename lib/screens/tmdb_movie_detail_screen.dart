import 'package:provider/provider.dart';

import '../data/services/rating_api_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/rating_dialog.dart';

import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../widgets/tmdb_poster_image.dart';

class TmdbMovieDetailScreen extends StatelessWidget {
  const TmdbMovieDetailScreen({super.key, required this.movie});

  final TmdbMovieDto movie;

  String get _releaseDate {
    final date = movie.releaseDate;
    if (date == null || date.isEmpty) return '개봉일 미정';
    return date;
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    final vm = MovieDetailViewModel(
      context.read<RatingApiService>(),
      context.read<LearningMemberSession>().memberId,
      movie,
    );
    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RatingDialog(
          onSubmit: (score, comment) async {
            await vm.createRating(score: score, comment: comment);
            if (vm.submitStatus != SubmitStatus.success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.submitMessage ?? '저장 실패')),
                );
              }
              throw StateError(vm.submitMessage ?? '저장 실패');
            }
          },
        ),
      );
      if (!context.mounted || saved != true) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.submitMessage!)));
    } finally {
      vm.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('영화 정보')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 380,
              child: TmdbPosterImage(
                posterPath: movie.backdropPath ?? movie.posterPath,
                width: double.infinity,
                height: 380,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_releaseDate),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(movie.voteAverage.toStringAsFixed(1)),
                    ],
                  ),
                  const Divider(height: 36),
                  Text(
                    '줄거리',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.overview.isEmpty ? '등록된 줄거리가 없어요.' : movie.overview,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showRatingDialog(context),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('평점 남기기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
