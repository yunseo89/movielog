import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';

class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.selectedGenre,
  });

  final List<Movie> movies;
  final String selectedGenre;
}

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];

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

    final savedGenre = results[1] as String;
    if (genres.contains(savedGenre)) {
      _selectedGenre = savedGenre;
    }

    return MovieListInitialData(
      movies: results[0] as List<Movie>,
      selectedGenre: _selectedGenre,
    );
  }

  Future<MovieListInitialData> _loadMovies() async {
    final movies = await _movieService.fetchMovies(mode: _loadMode);
    // TODO(5주차 유저별 평점 조회 API): 실제 API Service로 교체할 경계입니다.
    return MovieListInitialData(
      movies: movies,
      selectedGenre: _selectedGenre,
    );
  }

  void _retry() {
    setState(() {
      // 데모에서는 Retry가 성공으로 회복되는 흐름을 확인합니다.
      _loadMode = MovieLoadMode.success;
      _moviesFuture = _loadMovies();
    });
  }

  Future<void> _selectGenre(String genre) async {
    setState(() {
      _selectedGenre = genre;
    });
    await _genrePreference.save(genre);
  }

  void _changeLoadMode(MovieLoadMode mode) {
    // PopupMenuButton은 선택 후 스스로 메뉴를 닫습니다.
    // Navigator.pop()을 호출하면 MainShell까지 닫힐 수 있으므로 호출하지 않습니다.
    setState(() {
      _loadMode = mode;
      _moviesFuture = _loadMovies();
    });
  }

  List<Movie> _filterMovies(List<Movie> movies) {
    if (_selectedGenre == '전체') {
      return movies;
    }
    return movies.where((movie) => movie.genre == _selectedGenre).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          _MovieListHeader(
            textTheme: textTheme,
            colors: colors,
            onLoadModeSelected: _changeLoadMode,
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
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
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<MovieListInitialData>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                final movies = _filterMovies(
                  snapshot.data?.movies ?? const <Movie>[],
                );

                if (movies.isEmpty) {
                  return const MovieListEmpty();
                }

                return CustomScrollView(
                  slivers: [
                    MovieGrid(movies: movies),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieListHeader extends StatelessWidget {
  const _MovieListHeader({
    required this.textTheme,
    required this.colors,
    required this.onLoadModeSelected,
  });

  final TextTheme textTheme;
  final ColorScheme colors;
  final ValueChanged<MovieLoadMode> onLoadModeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
      child: Row(
        children: [
          Text(
            '영화',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          PopupMenuButton<MovieLoadMode>(
            tooltip: '상태 테스트',
            icon: const Icon(Icons.science_outlined),
            onSelected: onLoadModeSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: MovieLoadMode.success,
                child: Text('Success 테스트'),
              ),
              PopupMenuItem(
                value: MovieLoadMode.empty,
                child: Text('Empty 테스트'),
              ),
              PopupMenuItem(
                value: MovieLoadMode.failure,
                child: Text('Error 테스트'),
              ),
            ],
          ),
          IconButton(
            tooltip: '검색',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
