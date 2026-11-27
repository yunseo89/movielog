import 'package:flutter/foundation.dart';

import 'auth_view_model.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.auth,
    required this.version,
    this.enrichmentConcurrency = 5,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final AuthViewModel auth;
  final int version;
  bool get active => !isDisposed && auth.isSignedInVersion(version);
  final int enrichmentConcurrency;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  int _refreshGeneration = 0;

  // 즐겨찾기 목록을 다시 조회하고 TMDB 영화 정보를 최대 5개씩 보충합니다.
  Future<void> refresh() async {
    if (!active) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();
    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!active || refreshGeneration != _refreshGeneration) {
        return;
      }
      final enriched = await mapBounded(favorites, enrichmentConcurrency, (
        favorite,
      ) async {
        try {
          final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
          return FavoriteListItem(favorite: favorite, movie: movie);
        } catch (_) {
          return FavoriteListItem(
            favorite: favorite,
            errorMessage: '영화 정보를 불러오지 못했습니다.',
          );
        }
      });
      if (!active || refreshGeneration != _refreshGeneration) {
        return;
      }
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (_) {
      if (!active || refreshGeneration != _refreshGeneration) {
        return;
      }
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    } finally {
      if (active && refreshGeneration == _refreshGeneration) {
        notifyIfAlive();
      }
    }
  }
}
