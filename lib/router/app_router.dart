import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/main_shell.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../profile_screen.dart';
import '../sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/tmdb_movie_detail_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../screens/favorites_screen.dart';
import '../screens/movie_search_screen.dart';
import '../data/services/favorite_api_service.dart';

String? authRedirect(AuthStatus status, String location) {
  final start = location == '/start';
  final public = const {'/login', '/register'}.contains(location);
  return switch (status) {
    AuthStatus.initializing ||
    AuthStatus.retryRequired => start ? null : '/start',
    AuthStatus.signedOut ||
    AuthStatus.authenticating => public ? null : '/login',
    AuthStatus.signedIn => start || public ? '/home' : null,
  };
}

GoRouter createAppRouter(AuthViewModel auth) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/start',
    refreshListenable: auth,
    redirect: (_, state) => authRedirect(auth.status, state.uri.path),
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const StartScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const SignUpScreen()),
      ShellRoute(
        builder: (_, state, child) => MainShell(
          key: ValueKey(auth.sessionVersion),
          currentIndex: state.uri.path.startsWith('/movies')
              ? 1
              : state.uri.path.startsWith('/my')
              ? 2
              : 0,
          child: child,
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/movies',
            builder: (context, _) => ChangeNotifierProvider(
              create: (_) => PagedMoviesViewModel(
                tmdbApi: context.read<TmdbMovieService>(),
              )..loadInitial(),
              child: const MovieListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'search',
                parentNavigatorKey: rootKey,
                builder: (context, _) => ChangeNotifierProvider(
                  key: ValueKey(auth.sessionVersion),
                  create: (_) => PagedMoviesViewModel(
                    tmdbApi: context.read<TmdbMovieService>(),
                  ),
                  child: MovieSearchScreen(
                    onOpenMovie: (movie) =>
                        context.push<void>('/movie/${movie.id}', extra: movie),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/my',
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'favorites',
                parentNavigatorKey: rootKey,
                builder: (context, _) => ChangeNotifierProvider(
                  key: ValueKey(auth.sessionVersion),
                  create: (_) => FavoritesViewModel(
                    favoriteApi: context.read<FavoriteApiService>(),
                    tmdbApi: context.read<TmdbMovieService>(),
                    auth: auth,
                    version: auth.sessionVersion,
                  ),
                  child: FavoritesScreen(
                    onOpenMovie: (movie) =>
                        context.push<void>('/movie/${movie.id}', extra: movie),
                  ),
                ),
              ),
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootKey,
                builder: (_, _) => const MyRatingsScreen(),
              ),
              GoRoute(
                path: 'profile/edit',
                parentNavigatorKey: rootKey,
                builder: (_, _) => const _EditProfileGate(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) {
          final movie = state.extra;
          if (movie is! TmdbMovieDto) {
            return Scaffold(
              appBar: AppBar(title: const Text('영화 정보')),
              body: const Center(child: Text('영화 목록에서 다시 선택해 주세요.')),
            );
          }
          return ChangeNotifierProvider(
            key: ValueKey((auth.sessionVersion, movie.id)),
            create: (_) => FavoriteDetailViewModel(
              movieId: movie.id,
              favoriteApi: context.read<FavoriteApiService>(),
              auth: auth,
              version: auth.sessionVersion,
            )..load(),
            child: TmdbMovieDetailScreen(movie: movie),
          );
        },
      ),
    ],
  );
}

class _EditProfileGate extends StatelessWidget {
  const _EditProfileGate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('프로필 수정')),
        body: Center(
          child: auth.memberStatus == MemberLoadStatus.error
              ? FilledButton(
                  onPressed: () => auth.loadMember(force: true),
                  child: const Text('다시 시도'),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    return ChangeNotifierProvider(
      create: (_) =>
          EditProfileViewModel(context.read<MemberApiService>(), auth),
      child: const EditProfileScreen(),
    );
  }
}
