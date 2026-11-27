import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/tmdb_movie_service.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../widgets/movie_page_footer.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/tmdb_movie_card.dart';

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
                onPressed: () => context.push('/movies/search'),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          SliverToBoxAdapter(child: const _GenreChips()),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          Consumer<PagedMoviesViewModel>(
            builder: (context, viewModel, _) {
              switch (viewModel.phase) {
                case LoadPhase.idle:
                case LoadPhase.loading:
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadingState(),
                  );
                case LoadPhase.error:
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message:
                          viewModel.errorMessage ??
                          '영화를 불러오지 못했어요. 다시 시도해 주세요.',
                      onRetry: () =>
                          context.read<PagedMoviesViewModel>().retry(),
                    ),
                  );
                case LoadPhase.empty:
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                case LoadPhase.ready:
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            TmdbMovieCard(movie: viewModel.movies[index]),
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
          SliverToBoxAdapter(
            child: Consumer<PagedMoviesViewModel>(
              builder: (_, vm, _) => vm.phase == LoadPhase.ready
                  ? MoviePageFooter(vm: vm)
                  : const SizedBox.shrink(),
            ),
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

class _GenreChips extends StatefulWidget {
  const _GenreChips();
  @override
  State<_GenreChips> createState() => _GenreChipsState();
}

class _GenreChipsState extends State<_GenreChips> {
  late Future<List<TmdbGenreDto>> genres = context
      .read<TmdbMovieService>()
      .fetchGenres();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return FutureBuilder<List<TmdbGenreDto>>(
      future: genres,
      builder: (_, snap) {
        if (snap.hasError) {
          return TextButton(
            onPressed: () => setState(() {
              genres = context.read<TmdbMovieService>().fetchGenres();
            }),
            child: const Text('장르 다시 조회'),
          );
        }
        final choices = <TmdbGenreDto?>[null, ...?snap.data];
        return SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: choices.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final genre = choices[index];
              return ChoiceChip(
                label: Text(genre?.name ?? '전체'),
                selected: vm.selectedGenreId == genre?.id,
                onSelected: (selected) {
                  if (selected) vm.loadInitial(genreId: genre?.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}
