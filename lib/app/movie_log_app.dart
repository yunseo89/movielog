import '../view_models/learning_member_session.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_home_view_model.dart';
import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../theme/app_theme.dart';
import '../screens/start_screen.dart';
import '../data/services/rating_api_service.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final movieLogClient = createMovieLogClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LearningMemberSession()),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<SignUpService>(create: (_) => SignUpService(movieLogClient)),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(movieLogClient),
        ),
      ],
      child: ChangeNotifierProvider<MovieHomeViewModel>(
        create: (context) =>
            MovieHomeViewModel(context.read<TmdbMovieService>())..loadPopular(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const StartScreen(),
        ),
      ),
    );
  }
}
