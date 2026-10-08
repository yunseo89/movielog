import 'package:flutter/material.dart';

import 'models/movie.dart';
import 'profile_screen.dart';
import 'services/fake_movie_service.dart';
import 'services/genre_preference.dart';
import 'widgets/movie_list_states.dart';

class MovieListInitialData {
  const MovieListInitialData({required this.movies, required this.selectedGenre});
  final List<Movie> movies;
  final String selectedGenre;
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['전체', '드라마', 'SF', '스릴러', '판타지'];

  final FakeMovieService _movieService = const FakeMovieService();
  final GenrePreference _genrePreference = GenrePreference();

  late Future<MovieListInitialData> _moviesFuture;
  String _selectedGenre = '전체';
  MovieLoadMode _loadMode = MovieLoadMode.success;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadInitialData();
  }

  Future<MovieListInitialData> _loadInitialData() async {
    final results = await Future.wait<Object>([
      _movieService.fetchMovies(mode: _loadMode),
      _genrePreference.read(),
    ]);

    final movies = results[0] as List<Movie>;
    final savedGenre = results[1] as String;
    if (genres.contains(savedGenre)) {
      _selectedGenre = savedGenre;
    }

    return MovieListInitialData(
      movies: movies,
      selectedGenre: _selectedGenre,
    );
  }

  void _retry() {
    setState(() {
      _moviesFuture = _loadMovies();
    });
  }

  Future<MovieListInitialData> _loadMovies() async {
    final movies = await _movieService.fetchMovies(mode: _loadMode);
    // TODO(5주차 유저별 평점 조회 API): 실제 API Service로 교체할 경계입니다.
    return MovieListInitialData(
      movies: movies,
      selectedGenre: _selectedGenre,
    );
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    await _genrePreference.save(genre);
  }

  void _changeLoadMode(MovieLoadMode mode) {
    Navigator.of(context).pop();
    setState(() {
      _loadMode = mode;
      _moviesFuture = _loadMovies();
    });
  }

  List<Movie> _filterMovies(List<Movie> movies) {
    if (_selectedGenre == '전체') return movies;
    return movies.where((movie) => movie.genre == _selectedGenre).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('MovieLog', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<MovieLoadMode>(
            tooltip: '상태 테스트',
            icon: const Icon(Icons.science_outlined),
            onSelected: _changeLoadMode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: MovieLoadMode.success, child: Text('Success 테스트')),
              PopupMenuItem(value: MovieLoadMode.empty, child: Text('Empty 테스트')),
              PopupMenuItem(value: MovieLoadMode.failure, child: Text('Error 테스트')),
            ],
          ),
          IconButton(
            tooltip: '프로필',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<MovieListInitialData>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MovieListLoading();
            }

            if (snapshot.hasError) {
              return MovieListError(onRetry: _retry);
            }

            final movies = _filterMovies(snapshot.data?.movies ?? const <Movie>[]);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      '영화 목록',
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: genres.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        return ChoiceChip(
                          label: Text(genre),
                          selected: _selectedGenre == genre,
                          onSelected: (_) => _selectGenre(genre),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                if (movies.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: MovieListEmpty(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => MovieCard(movie: movies[index]),
                        childCount: movies.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.58,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showMovieDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                movie.imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: colors.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 17, color: colors.primary),
              const SizedBox(width: 3),
              
              const SizedBox(width: 6),
              Expanded(child: Text('${movie.year} · ${movie.genre}', maxLines: 1,
                  overflow: TextOverflow.ellipsis, style: textTheme.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }

  void _showMovieDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(movie.imagePath, width: double.infinity, height: 240, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(movie.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${movie.year} · ${movie.genre}'),
            const SizedBox(height: 12),
            Text(movie.description),
          ],
        ),
      ),
    );
  }
}
