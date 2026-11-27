import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/session_ratings_view_model.dart';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'week7_test.dart' as api;
import 'week8_test.dart' as auth;

ResponseBody page(int n, List<int> ids) => api.jsonReply({
  'page': n,
  'total_pages': 2,
  'results': [
    for (final id in ids) {'id': id, 'title': '영화 $id'},
  ],
}, 200);
Map<String, Object?> favorite(int id) => {
  'favoriteId': id + 10,
  'movieId': id,
  'createdAt': '2026-11-01T00:00:00Z',
};

void main() {
  testWidgets('마이페이지에서 즐겨찾기 해제 후 복귀하면 서버에서 빈 목록을 다시 읽는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool saved = true;
    int lists = 0;
    final h = auth.Harness(
      protectedReply: (o) {
        if (o.path.endsWith('/me')) return auth.good(auth.me());
        if (o.path == '/v8/favorites') {
          lists++;
          return auth.good(saved ? [favorite(550)] : []);
        }
        if (o.method == 'DELETE') {
          saved = false;
          return auth.good(null);
        }
        return auth.good({'isFavorite': saved});
      },
    );
    addTearDown(h.dispose);
    await tester.runAsync(() => h.login());
    final router = createAppRouter(h.auth)..go('/my');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: h.auth),
          ChangeNotifierProvider<SessionRatingsViewModel>.value(
            value: h.ratings,
          ),
          Provider.value(value: FavoriteApiService(h.protectedDio)),
          Provider.value(value: api.movieService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 즐겨찾기'));
    await auth.pumpUntil(
      tester,
      () => find.text('테스트 영화').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.ensureVisible(find.text('테스트 영화'));
    await tester.tap(find.text('테스트 영화'));
    await auth.pumpUntil(
      tester,
      () => find.byIcon(Icons.bookmark).evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.bookmark));
    await tester.tap(find.byIcon(Icons.bookmark));
    await auth.pumpUntil(
      tester,
      () => find.byIcon(Icons.bookmark_border).evaluate().isNotEmpty,
    );
    router.pop();
    await auth.pumpUntil(
      tester,
      () => find.text('아직 즐겨찾기한 영화가 없습니다.').evaluate().isNotEmpty,
    );
    expect(lists, 2);
  });

  test('다음 페이지 실패 시 결과 유지, 같은 페이지 재시도와 중복 제거', () async {
    var attempts = 0;
    final adapter = api.StubAdapter((o) {
      expect(o.path, '/discover/movie');
      expect(o.queryParameters['with_genres'], 28);
      if (o.queryParameters['page'] == 1) return page(1, [1]);
      if (++attempts == 1) return api.jsonReply({}, 503);
      return page(2, [1, 2]);
    });
    final vm = PagedMoviesViewModel(
      tmdbApi: TmdbMovieService(api.client(adapter)),
    );
    addTearDown(vm.dispose);
    await vm.loadInitial(genreId: 28);
    await vm.loadNextPage();
    expect(vm.loadMoreError, isNotNull);
    expect(vm.movies.map((m) => m.id), [1]);
    await vm.loadNextPage();
    expect(vm.movies.map((m) => m.id), [1, 2]);
    expect(vm.hasMore, isFalse);
    expect(adapter.requests.map((r) => r.queryParameters['page']), [1, 2, 2]);
  });
  test('늦은 검색 결과는 새 검색 결과를 덮지 않는다', () async {
    final started = Completer<void>(), old = Completer<ResponseBody>();
    final adapter = api.StubAdapter((o) {
      expect(o.path, '/search/movie');
      if (o.queryParameters['query'] == '이전') {
        started.complete();
        return old.future;
      }
      return page(1, [2]);
    });
    final vm = PagedMoviesViewModel(
      tmdbApi: TmdbMovieService(api.client(adapter)),
    );
    addTearDown(vm.dispose);
    final first = vm.loadInitial(query: '이전');
    await started.future;
    await vm.loadInitial(query: ' 새 검색 ');
    old.complete(page(1, [1]));
    await first;
    expect(vm.movies.single.id, 2);
  });
  test('즐겨찾기 중복/없음은 GET으로 맞추고 403은 아이콘과 로그인 유지', () async {
    var saved = false, forbidden = false;
    final h = auth.Harness(
      protectedReply: (o) {
        expect(o.headers['Authorization'], 'Bearer fixture-access');
        switch (o.method) {
          case 'POST':
            expect(o.path, '/v8/favorites');
            expect(o.data, {'movieId': 550});
            if (forbidden) return auth.failure(403, 'FORBIDDEN');
            saved = true;
            return auth.failure(409, 'FAVORITE409_1');
          case 'DELETE':
            expect(o.path, '/v8/favorites/550');
            saved = false;
            return auth.failure(404, 'FAVORITE404_1');
          default:
            expect(o.path, '/v8/favorites/550');
            return auth.good({'isFavorite': saved});
        }
      },
    );
    addTearDown(h.dispose);
    await h.login(load: false);
    final vm = FavoriteDetailViewModel(
      movieId: 550,
      favoriteApi: FavoriteApiService(h.protectedDio),
      auth: h.auth,
      version: h.auth.sessionVersion,
    );
    addTearDown(vm.dispose);
    await vm.load();
    await vm.toggle();
    expect(vm.isFavorite, isTrue);
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    forbidden = true;
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    expect(vm.errorMessage, isNotNull);
    expect(h.auth.status, AuthStatus.signedIn);
    expect(h.protectedAdapter.requests.map((r) => r.method), [
      'GET',
      'POST',
      'GET',
      'DELETE',
      'GET',
      'POST',
    ]);
  });
  test('TMDB 일부 실패에도 순서 보존, 이전 계정의 늦은 응답 차단', () async {
    final started = Completer<void>(), lateList = Completer<ResponseBody>();
    var delay = false;
    final h = auth.Harness(
      protectedReply: (o) {
        if (delay) {
          started.complete();
          return lateList.future;
        }
        return auth.good([favorite(1), favorite(2)]);
      },
    );
    addTearDown(h.dispose);
    await h.login(load: false);
    final movies = TmdbMovieService(
      api.client(
        api.StubAdapter(
          (o) => o.path == '/movie/1'
              ? api.jsonReply({}, 404)
              : api.jsonReply({'id': 2, 'title': '두번째'}, 200),
        ),
      ),
    );
    final vm = FavoritesViewModel(
      favoriteApi: FavoriteApiService(h.protectedDio),
      tmdbApi: movies,
      auth: h.auth,
      version: h.auth.sessionVersion,
    );
    addTearDown(vm.dispose);
    await vm.refresh();
    expect(vm.phase, LoadPhase.ready);
    expect(vm.items.first.movie, isNull);
    expect(vm.items.last.movie?.id, 2);
    delay = true;
    final pending = vm.refresh();
    await started.future;
    await h.auth.logout();
    await h.login(load: false);
    lateList.complete(auth.good([favorite(3)]));
    await pending;
    expect(vm.active, isFalse);
    expect(vm.items.any((x) => x.favorite.movieId == 3), isFalse);
    final next = FavoritesViewModel(
      favoriteApi: vm.favoriteApi,
      tmdbApi: movies,
      auth: h.auth,
      version: h.auth.sessionVersion,
    );
    addTearDown(next.dispose);
    expect(next.items, isEmpty);
  });
}
