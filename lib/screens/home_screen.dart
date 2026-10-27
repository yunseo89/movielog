import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_home_view_model.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(
                children: [
                  Text(
                    'MovieLog',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '검색',
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/images/posters/hero_under_the_starlight.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '추천 신작',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '별빛 아래 우리',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '로맨스 · 드라마 · 124분',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.info_outline),
                              label: const Text('상세보기'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '인기 영화',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('전체보기')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<MovieHomeViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.status == MovieHomeLoadStatus.idle ||
                    viewModel.status == MovieHomeLoadStatus.loading) {
                  return const SizedBox(
                    height: 205,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (viewModel.status == MovieHomeLoadStatus.error) {
                  return SizedBox(
                    height: 205,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            viewModel.message ??
                                '인기 영화를 불러오지 못했어요.',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                              context
                                  .read<MovieHomeViewModel>()
                                  .loadPopular();
                            },
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (viewModel.status == MovieHomeLoadStatus.empty) {
                  return const SizedBox(
                    height: 205,
                    child: Center(child: Text('인기 영화가 없습니다.')),
                  );
                }

                final movies = viewModel.popularMovies;

                return SizedBox(
                  height: 230,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 112,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: TmdbPosterImage(
                                  posterPath: movie.posterPath,
                                  width: 112,
                                  height: 135,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(movie.voteAverage.toStringAsFixed(1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
