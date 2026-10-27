import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/tmdb_poster_image.dart';
import 'tmdb_movie_detail_screen.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.surface,
            surfaceTintColor: colors.surface,
            title: Text(
              '영화',
              style: textTheme.headlineSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: '검색',
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, _) {
                final isLoading = viewModel.isLoading;
                return SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: viewModel.genres.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ChoiceChip(
                          label: const Text('전체'),
                          selected: viewModel.selectedGenreId == null,
                          onSelected: isLoading
                              ? null
                              : (selected) {
                                  if (selected) {
                                    context
                                        .read<MovieListViewModel>()
                                        .selectGenre(null);
                                  }
                                },
                        );
                      }

                      final genre = viewModel.genres[index - 1];
                      return ChoiceChip(
                        label: Text(genre.name),
                        selected: viewModel.selectedGenreId == genre.id,
                        onSelected: isLoading
                            ? null
                            : (selected) {
                                if (selected) {
                                  context
                                      .read<MovieListViewModel>()
                                      .selectGenre(genre.id);
                                }
                              },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, _) {
              switch (viewModel.status) {
                case MovieListLoadStatus.idle:
                case MovieListLoadStatus.loading:
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadingState(),
                  );
                case MovieListLoadStatus.error:
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message:
                          viewModel.message ?? '영화를 불러오지 못했어요. 다시 시도해 주세요.',
                      onRetry: () => context.read<MovieListViewModel>().retry(),
                    ),
                  );
                case MovieListLoadStatus.empty:
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                case MovieListLoadStatus.success:
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _TmdbMovieCard(movie: viewModel.movies[index]),
                        childCount: viewModel.movies.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 18,
                            childAspectRatio: 0.50,
                          ),
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TmdbMovieCard extends StatelessWidget {
  const _TmdbMovieCard({required this.movie});

  final TmdbMovieDto movie;

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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TmdbMovieDetailScreen(movie: movie),
          ),
        );
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('영화 목록을 불러오는 중...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_filter_outlined, size: 44),
          SizedBox(height: 12),
          Text('해당 조건의 영화가 없어요.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
