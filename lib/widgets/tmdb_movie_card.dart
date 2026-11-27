import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'tmdb_poster_image.dart';

class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.onTap});

  final TmdbMovieDto movie;
  final VoidCallback? onTap;

  String get _releaseYear {
    final date = movie.releaseDate;
    if (date == null || date.length < 4) return '개봉일 미정';
    return date.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap:
          onTap ??
          () {
            context.push('/movie/${movie.id}', extra: movie);
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: 250,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 3),
              Text(movie.voteAverage.toStringAsFixed(1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _releaseYear,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
