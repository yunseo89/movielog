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
    final rating = await showDialog<double>(
      context: context,
      builder: (_) =>
          _MovieRatingDialog(movieId: movie.id, movieTitle: movie.title),
    );

    if (!context.mounted || rating == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '영화 ID ${movie.id}: ${rating.toStringAsFixed(1)}점을 선택했어요.',
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

class _MovieRatingDialog extends StatefulWidget {
  const _MovieRatingDialog({required this.movieId, required this.movieTitle});

  final int movieId;
  final String movieTitle;

  @override
  State<_MovieRatingDialog> createState() => _MovieRatingDialogState();
}

class _MovieRatingDialogState extends State<_MovieRatingDialog> {
  double _rating = 3.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      semanticLabel: '${widget.movieTitle} 영화 ID ${widget.movieId} 평점 선택',
      title: Text('${widget.movieTitle} 평점'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_rating.toStringAsFixed(1)} / 5.0'),
          Slider(
            value: _rating,
            min: 0.5,
            max: 5,
            divisions: 9,
            label: _rating.toStringAsFixed(1),
            onChanged: (value) => setState(() => _rating = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_rating),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
