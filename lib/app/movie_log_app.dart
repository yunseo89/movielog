import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/token_storage.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/session_ratings_view_model.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});
  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final Dio _public;
  late final Dio _protected;
  late final Dio _tmdb;
  late final TokenStorage _storage;
  late final AuthViewModel _auth;
  late final MemberApiService _memberApi;
  late final RatingApiService _ratingApi;
  late final TmdbMovieService _movies;
  late final MovieHomeViewModel _home;
  late final SessionRatingsViewModel _ratings;
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _storage = SerializedTokenStorage(
      SecureTokenStorage(const FlutterSecureStorage()),
    );
    _public = createMovieLogClient();
    _protected = createAuthMovieLogClient(
      _storage,
      sessionVersion: () => _auth.sessionVersion,
      onSessionExpired: (version) =>
          _auth.expireSession(expectedVersion: version),
    );
    _tmdb = createTmdbClient();
    _memberApi = MemberApiService(_protected);
    _ratingApi = RatingApiService(_public, _protected);
    _auth = AuthViewModel(AuthApiService(_public), _memberApi, _storage);
    _ratings = SessionRatingsViewModel(_ratingApi, _auth);
    _movies = TmdbMovieService(_tmdb);
    _home = MovieHomeViewModel(_movies)..loadPopular();
    _router = createAppRouter(_auth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _auth.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    _ratings.dispose();
    _auth.dispose();
    _home.dispose();
    _public.close(force: true);
    _protected.close(force: true);
    _tmdb.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider(create: (_) => FavoriteApiService(_protected)),
      Provider<TokenStorage>.value(value: _storage),
      Provider<AuthApiService>(create: (_) => AuthApiService(_public)),
      Provider<MemberApiService>.value(value: _memberApi),
      Provider<RatingApiService>.value(value: _ratingApi),
      Provider<SignUpService>(create: (_) => SignUpService(_public)),
      Provider<TmdbMovieService>.value(value: _movies),
      ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
      ChangeNotifierProvider<SessionRatingsViewModel>.value(value: _ratings),
      ChangeNotifierProvider<MovieHomeViewModel>.value(value: _home),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    ),
  );
}
