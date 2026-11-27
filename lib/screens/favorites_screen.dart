import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_movie_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesViewModel>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('내 즐겨찾기'), centerTitle: true),
    body: Consumer<FavoritesViewModel>(
      builder: (context, vm, _) {
        if (vm.phase == LoadPhase.idle || vm.phase == LoadPhase.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.phase == LoadPhase.empty) {
          return const Center(child: Text('아직 즐겨찾기한 영화가 없습니다.'));
        }

        if (vm.phase == LoadPhase.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vm.errorMessage ?? '조회 오류입니다.'),
                MovieLogButton(label: '다시 시도', onPressed: vm.refresh),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.50,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: vm.items.length,
            itemBuilder: (context, index) {
              final item = vm.items[index], movie = item.movie;

              if (movie == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TMDB #${item.favorite.movieId}'),
                      Text(item.errorMessage ?? '정보가 없습니다.'),
                      TextButton(
                        onPressed: vm.refresh,
                        child: const Text('정보 재조회'),
                      ),
                    ],
                  ),
                );
              }
              return TmdbMovieCard(
                movie: movie,
                onTap: () async {
                  await widget.onOpenMovie(movie);

                  if (!mounted) return;

                  await vm.refresh(); // ViewModel도 같은 현재 세션인지 다시 확인합니다.
                },
              );
            },
          ),
        );
      },
    ),
  );
}
