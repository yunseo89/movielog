import '../widgets/rating_write_feedback.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings_view_model.dart';
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
    final vm = context.read<SessionRatingsViewModel>();
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) => reportRatingWrite(
          context,
          () => vm.create(movie, score: score, comment: comment),
        ),
      ),
    );
    if (!context.mounted || !auth.isSignedInVersion(version) || saved != true) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('평점을 등록했어요.'),
        action: SnackBarAction(
          label: '등록한 평점 보기',
          onPressed: () {
            if (context.mounted) context.go('/my/ratings');
          },
        ),
      ),
    );
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
