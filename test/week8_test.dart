import 'package:movielog/screens/tmdb_movie_detail_screen.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/theme/app_theme.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/session_ratings_view_model.dart';

import 'week7_test.dart' as fixture;

// 가상 API와 가상 저장소로만 검증합니다. 토큰은 테스트용 불투명 문자열입니다.
class MemoryStorage implements TokenStorage {
  String? value;
  int saves = 0;
  int deletes = 0;
  bool failRead = false;
  bool failDelete = false;
  bool failSave = false;
  Completer<void>? saving;
  @override
  Future<void> saveAccessToken(String token) async {
    saves++;
    if (failSave) throw StateError('storage failure');
    if (saving != null) await saving!.future;
    value = token;
  }

  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('storage failure');
    return value;
  }

  @override
  Future<void> deleteAccessToken() async {
    deletes++;
    if (failDelete) throw StateError('delete failed');
    value = null;
  }
}

Map<String, Object?> me([String nickname = '테스트회원']) => {
  'email': 'test@example.invalid',
  'nickname': nickname,
  'createdAt': '2026-11-20T00:00:00Z',
};
ResponseBody good(Object? data, [int status = 200]) =>
    fixture.jsonReply(fixture.common(status, result: data), status);
ResponseBody failure(int status, String code) => fixture.jsonReply({
  'isSuccess': false,
  'code': code,
  'message': '테스트 오류 $code',
  'result': null,
}, status);
Map<String, Object?> rated({int score = 4, String? comment = '기존 후기'}) => {
  ...fixture.rating(),
  'score': score,
  'comment': comment,
};
typedef Reply = FutureOr<ResponseBody> Function(RequestOptions);

class Harness {
  Harness({MemoryStorage? storage, Reply? publicReply, Reply? protectedReply})
    : storage = storage ?? MemoryStorage() {
    publicAdapter = fixture.StubAdapter(
      publicReply ??
          (_) => good({'nickname': '테스트회원', 'accessToken': 'fixture-access'}),
    );
    protectedAdapter = fixture.StubAdapter(protectedReply ?? (_) => good(me()));
    publicDio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = publicAdapter;
    protectedDio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..httpClientAdapter = protectedAdapter;
    protectedDio.interceptors.add(
      AuthInterceptor(
        this.storage,
        origin: Uri.parse('https://workbook.devnoco.com'),
        sessionVersion: () => auth.sessionVersion,
        onSessionExpired: (version) =>
            auth.expireSession(expectedVersion: version),
      ),
    );
    memberApi = MemberApiService(protectedDio);
    ratingApi = RatingApiService(publicDio, protectedDio);
    auth = AuthViewModel(AuthApiService(publicDio), memberApi, this.storage);
    ratings = SessionRatingsViewModel(ratingApi, auth);
  }
  final MemoryStorage storage;
  late final fixture.StubAdapter publicAdapter;
  late final fixture.StubAdapter protectedAdapter;
  late final Dio publicDio;
  late final Dio protectedDio;
  late final MemberApiService memberApi;
  late final RatingApiService ratingApi;
  late final AuthViewModel auth;
  late final SessionRatingsViewModel ratings;
  Future<void> login({bool load = true}) async {
    await auth.login('test@example.invalid', 'Fixture1!');
    if (load) await auth.loadMember();
  }

  void dispose() {
    ratings.dispose();
    auth.dispose();
    publicDio.close(force: true);
    protectedDio.close(force: true);
  }
}

Future<void> waitForState(Listenable source, bool Function() ready) async {
  if (ready()) return;
  final done = Completer<void>();
  void listener() {
    if (ready() && !done.isCompleted) done.complete();
  }

  source.addListener(listener);
  try {
    await done.future.timeout(const Duration(seconds: 5));
  } finally {
    source.removeListener(listener);
  }
}

Future<void> pumpUntil(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 100 && !ready(); attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  expect(ready(), isTrue, reason: '화면이 시작한 비동기 요청이 완료되어야 합니다.');
}

void main() {
  test('로그인 모델은 memberId나 JWT claim을 가정하지 않고 비밀번호를 trim하지 않는다', () {
    expect(const LoginRequest(email: ' x@y.co ', password: ' pass ').toJson(), {
      'email': 'x@y.co',
      'password': ' pass ',
    });
    expect(
      LoginResult.fromJson({'nickname': '회원', 'accessToken': 'opaque'})
          .nickname,
      '회원',
    );
    expect(
      () => LoginResult.fromJson({'nickname': '회원', 'accessToken': ''}),
      throwsStateError,
    );
  });
  test('토큰 없는 복원은 signedOut이며 GET me를 보내지 않는다', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.auth.restoreSession();
    expect(h.auth.status, AuthStatus.signedOut);
    expect(h.protectedAdapter.requests, isEmpty);
  });
  test('저장 토큰 복원은 GET me 완료 전까지 initializing', () async {
    final pending = Completer<ResponseBody>();
    final h = Harness(
      storage: MemoryStorage()..value = 'stored',
      protectedReply: (_) => pending.future,
    );
    addTearDown(h.dispose);
    final restoring = h.auth.restoreSession();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(h.auth.status, AuthStatus.initializing);
    expect(h.auth.member, isNull);
    pending.complete(good(me()));
    await restoring;
    expect(h.auth.status, AuthStatus.signedIn);
    expect(h.auth.member!.nickname, '테스트회원');
  });
  test('복원 네트워크 실패는 token 유지 + retryRequired, 재시도 성공', () async {
    var fail = true;
    final h = Harness(
      storage: MemoryStorage()..value = 'stored',
      protectedReply: (_) => fail ? failure(503, 'COMMON503') : good(me()),
    );
    addTearDown(h.dispose);
    await h.auth.restoreSession();
    expect(h.auth.status, AuthStatus.retryRequired);
    expect(h.storage.deletes, 0);
    fail = false;
    await h.auth.restoreSession();
    expect(h.auth.status, AuthStatus.signedIn);
  });
  test('저장소 읽기 실패도 자동 로그아웃하지 않고 재시도', () async {
    final h = Harness(storage: MemoryStorage()..failRead = true);
    addTearDown(h.dispose);
    await h.auth.restoreSession();
    expect(h.auth.status, AuthStatus.retryRequired);
    expect(h.storage.deletes, 0);
  });
  test('신규 로그인 → 저장 → signedIn → Main의 GET me, 내 정보 중복 로딩 방지', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.login(load: false);
    expect(h.auth.status, AuthStatus.signedIn);
    expect(h.auth.member, isNull);
    expect(h.storage.saves, 1);
    expect(h.protectedAdapter.requests, isEmpty);
    await h.auth.loadMember();
    await h.auth.loadMember();
    expect(h.auth.member, isNotNull);
    expect(h.protectedAdapter.requests.length, 1);
    expect(h.publicAdapter.requests.single.path, '/v7/auth/login');
    expect(
      h.publicAdapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });
  test('로그인 AUTH401_1은 폼 오류이며 만료 알림이나 logout 없음', () async {
    final h = Harness(publicReply: (_) => failure(401, 'AUTH401_1'));
    addTearDown(h.dispose);
    await h.login(load: false);
    expect(h.auth.status, AuthStatus.signedOut);
    expect(h.auth.message, contains('이메일'));
    expect(h.auth.sessionExpired, isFalse);
    expect(h.storage.deletes, 0);
  });
  test('실제 연결 오류 타입에서도 프로필·GET me·복원은 토큰을 삭제하지 않는다', () async {
    var offline = false;
    final h = Harness(
      protectedReply: (o) {
        if (offline) {
          throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          );
        }
        return good(me());
      },
    );
    addTearDown(h.dispose);
    await h.login();
    offline = true;
    final profile = EditProfileViewModel(h.memberApi, h.auth);
    addTearDown(profile.dispose);
    expect(await profile.save('바꿀닉네임'), isFalse);
    expect(profile.message, isNotNull);
    expect(h.auth.status, AuthStatus.signedIn);
    await h.auth.loadMember(force: true);
    expect(h.auth.memberStatus, MemberLoadStatus.error);
    expect(h.auth.status, AuthStatus.signedIn);
    await h.auth.restoreSession();
    expect(h.auth.status, AuthStatus.retryRequired);
    expect(h.storage.value, isNotNull);
    expect(h.storage.deletes, 0);
  });
  test('토큰 저장 실패는 signedIn으로 가지 않는다', () async {
    final h = Harness(storage: MemoryStorage()..failSave = true);
    addTearDown(h.dispose);
    await h.login(load: false);
    expect(h.auth.status, AuthStatus.signedOut);
    expect(h.auth.sessionExpired, isFalse);
  });
  test('로그인 중 중복 탭은 POST 한 번', () async {
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    final h = Harness(
      publicReply: (_) {
        started.complete();
        return pending.future;
      },
    );
    addTearDown(h.dispose);
    final login = h.login(load: false);
    await started.future;
    await h.login(load: false);
    expect(h.publicAdapter.requests.length, 1);
    pending.complete(good({'nickname': '회원', 'accessToken': 'fixture'}));
    await login;
  });
  for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
    test('보호 $code는 토큰·member 삭제 및 만료 알림 1회 소비', () async {
      final h = Harness(
        storage: MemoryStorage()..value = 'stored',
        protectedReply: (_) => failure(401, code),
      );
      addTearDown(h.dispose);
      await h.auth.restoreSession();
      expect(h.auth.status, AuthStatus.signedOut);
      expect(h.auth.member, isNull);
      expect(h.storage.value, isNull);
      expect(h.storage.deletes, 1);
      expect(h.auth.consumeSessionExpired(), isTrue);
      expect(h.auth.consumeSessionExpired(), isFalse);
    });
  }
  test('직접 로그아웃은 저장소·메모리 삭제하며 만료 안내 없음', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.login();
    await h.auth.logout();
    expect(h.auth.status, AuthStatus.signedOut);
    expect(h.auth.member, isNull);
    expect(h.storage.value, isNull);
    expect(h.auth.sessionExpired, isFalse);
  });
  test('동시 401은 한 번만 삭제하고, 오래된 401은 새 세션을 지우지 않는다', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.login();
    final old = h.auth.sessionVersion;
    await Future.wait([
      h.auth.expireSession(expectedVersion: old),
      h.auth.expireSession(expectedVersion: old),
    ]);
    expect(h.storage.deletes, 1);
    await h.login();
    await h.auth.expireSession(expectedVersion: old);
    expect(h.auth.status, AuthStatus.signedIn);
    expect(h.storage.deletes, 1);
  });
  test('진행 중 저장을 기다리고 로그아웃 삭제, 정리 중 로그인 차단', () async {
    final storage = MemoryStorage()..saving = Completer<void>();
    final h = Harness(storage: storage);
    addTearDown(h.dispose);
    final login = h.login(load: false);
    while (storage.saves == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final logout = h.auth.logout();
    await h.login(load: false);
    expect(h.publicAdapter.requests.length, 1);
    storage.saving!.complete();
    await Future.wait([login, logout]);
    expect(storage.value, isNull);
    expect(h.auth.status, AuthStatus.signedOut);
  });
  test('삭제 실패를 성공으로 숨기지 않고 저장소 정리 재시도', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.login();
    h.storage.failDelete = true;
    await h.auth.logout();
    expect(h.auth.status, AuthStatus.retryRequired);
    h.storage.failDelete = false;
    await h.auth.restoreSession();
    expect(h.auth.status, AuthStatus.signedOut);
    expect(h.storage.value, isNull);
  });
  test('SerializedTokenStorage는 write 다음 delete 순서를 보장', () async {
    final raw = MemoryStorage()..saving = Completer<void>();
    final storage = SerializedTokenStorage(raw);
    final write = storage.saveAccessToken('fixture');
    final delete = storage.deleteAccessToken();
    raw.saving!.complete();
    await Future.wait([write, delete]);
    expect(await storage.readAccessToken(), isNull);
  });
  test('지연 GET me 응답은 로그아웃 뒤 member에 반영하지 않는다', () async {
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    final h = Harness(
      protectedReply: (_) {
        started.complete();
        return pending.future;
      },
    );
    addTearDown(h.dispose);
    await h.login(load: false);
    final load = h.auth.loadMember();
    await started.future;
    await h.auth.logout();
    pending.complete(good(me()));
    await load;
    expect(h.auth.member, isNull);
    expect(h.auth.status, AuthStatus.signedOut);
  });
  test('새 계정 로그인 뒤 이전 요청의 실제 401이 도착해도 새 세션 유지', () async {
    var wait = false;
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    final h = Harness(
      protectedReply: (_) {
        if (wait) {
          started.complete();
          return pending.future;
        }
        return good(me());
      },
    );
    addTearDown(h.dispose);
    await h.login();
    wait = true;
    final old = h.protectedDio.get('/v7/members/me');
    await started.future;
    await h.auth.logout();
    wait = false;
    await h.login();
    pending.complete(failure(401, 'AUTH401_4'));
    await expectLater(old, throwsA(isA<DioException>()));
    expect(h.auth.status, AuthStatus.signedIn);
    expect(h.auth.member, isNotNull);
  });
  test('Bearer는 승인된 origin·메서드·path에만 부착, 공개/외부/redirect 차단', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.login();
    for (final path in [
      '/v7/auth/login',
      '/v7/members/42/ratings',
      '/v7/ratings-extra',
      'https://external.invalid/v7/members/me',
      'http://workbook.devnoco.com/v7/members/me',
      'https://workbook.devnoco.com:444/v7/members/me',
    ]) {
      await h.protectedDio.get(
        path,
        options: Options(headers: {'authorization': 'stale'}),
      );
      expect(
        h.protectedAdapter.requests.last.headers.keys.any(
          (k) => k.toLowerCase() == 'authorization',
        ),
        isFalse,
      );
    }
    await h.protectedDio.get('/v7/members/me');
    expect(
      h.protectedAdapter.requests.last.headers['Authorization'],
      isNotNull,
    );
    expect(h.protectedAdapter.requests.last.followRedirects, isFalse);
  });
  test('보호 요청의 secure storage 읽기 실패는 서버 401이 아니며 세션 유지', () async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.login();
    h.storage.failRead = true;
    await expectLater(
      h.protectedDio.get('/v7/members/me'),
      throwsA(isA<DioException>()),
    );
    expect(h.auth.status, AuthStatus.signedIn);
    expect(h.storage.deletes, 0);
  });
  test(
    'v7 등록/수정 Rating 파싱, 명시적 comment null, 삭제 200 wrapper, 공개 조회 무토큰',
    () async {
      final h = Harness(
        publicReply: (_) => fixture.jsonReply([rated()], 200),
        protectedReply: (o) => o.method == 'DELETE'
            ? good(null)
            : good(rated(), o.method == 'POST' ? 201 : 200),
      );
      addTearDown(h.dispose);
      final created = await h.ratingApi.createRating(
        const CreateRatingRequest(movieId: 550, score: 4),
      );
      expect(created.ratingId, 91);
      expect(h.protectedAdapter.requests.last.path, '/v7/ratings');
      expect(h.protectedAdapter.requests.last.data, {
        'movieId': 550,
        'score': 4,
      });
      await h.ratingApi.updateRating(ratingId: 91, score: 5, comment: '유지');
      expect(h.protectedAdapter.requests.last.data, {
        'score': 5,
        'comment': '유지',
      });
      await h.ratingApi.updateRating(ratingId: 91, score: 5);
      expect(h.protectedAdapter.requests.last.data, {
        'score': 5,
        'comment': null,
      });
      await h.ratingApi.deleteRating(91);
      expect((await h.ratingApi.fetchMyRatings(42)).single.movieId, 550);
      expect(
        h.publicAdapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    },
  );
  test('삭제는 과거 204 응답을 성공으로 처리하지 않는다', () async {
    final h = Harness(protectedReply: (_) => fixture.jsonReply(null, 204));
    addTearDown(h.dispose);
    await expectLater(h.ratingApi.deleteRating(91), throwsStateError);
  });
  test('세션 평점은 등록/PATCH 응답으로 갱신, DELETE로 제거, 전체 GET 추정 없음', () async {
    final h = Harness(
      protectedReply: (o) => o.path.endsWith('/me')
          ? good(me())
          : o.method == 'DELETE'
          ? good(null)
          : good(
              rated(score: o.method == 'PATCH' ? 5 : 4),
              o.method == 'POST' ? 201 : 200,
            ),
    );
    addTearDown(h.dispose);
    await h.login();
    await h.ratings.create(fixture.movie, score: 4);
    expect(h.ratings.ratings.single.movieId, 550);
    expect(h.ratings.movieFor(550)!.title, fixture.movie.title);
    await h.ratings.update(91, score: 5, comment: '수정');
    expect(h.ratings.ratings.single.score, 5);
    await h.ratings.delete(91);
    expect(h.ratings.ratings, isEmpty);
    expect(
      h.protectedAdapter.requests.where(
        (o) => o.path.contains('/members/') && o.path.endsWith('/ratings'),
      ),
      isEmpty,
    );
  });
  for (final code in ['RATING403_1', 'RATING409_1']) {
    test('$code는 입력 오류 안내만, 자동 로그아웃 없음', () async {
      final h = Harness(
        protectedReply: (o) => o.path.endsWith('/me')
            ? good(me())
            : failure(code.contains('403') ? 403 : 409, code),
      );
      addTearDown(h.dispose);
      await h.login();
      await expectLater(
        h.ratings.create(fixture.movie, score: 4),
        throwsStateError,
      );
      expect(h.auth.status, AuthStatus.signedIn);
      expect(h.storage.deletes, 0);
    });
  }
  test('없는 평점 RATING404_1은 세션의 해당 카드만 제거', () async {
    final h = Harness(
      protectedReply: (o) => o.path.endsWith('/me')
          ? good(me())
          : o.method == 'POST'
          ? good(rated(), 201)
          : failure(404, 'RATING404_1'),
    );
    addTearDown(h.dispose);
    await h.login();
    await h.ratings.create(fixture.movie, score: 4);
    await expectLater(h.ratings.update(91, score: 3), throwsStateError);
    expect(h.ratings.ratings, isEmpty);
    expect(h.auth.status, AuthStatus.signedIn);
  });
  test('계정 전환은 세션 평점을 비우고 이전 등록 결과를 버린다', () async {
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    final h = Harness(
      protectedReply: (o) {
        if (o.method == 'POST') {
          started.complete();
          return pending.future;
        }
        return good(me());
      },
    );
    addTearDown(h.dispose);
    await h.login();
    final create = h.ratings.create(fixture.movie, score: 4);
    await started.future;
    await h.auth.logout();
    await h.login();
    pending.complete(good(rated(), 201));
    await expectLater(create, throwsStateError);
    expect(h.ratings.ratings, isEmpty);
    expect(h.auth.status, AuthStatus.signedIn);
  });
  test('프로필 길이·변경 없음은 PATCH 생략, 성공 member 즉시 교체', () async {
    final h = Harness(
      protectedReply: (o) => good(me(o.method == 'PATCH' ? '변경닉네임' : '테스트회원')),
    );
    addTearDown(h.dispose);
    await h.login();
    final vm = EditProfileViewModel(h.memberApi, h.auth);
    addTearDown(vm.dispose);
    expect(await vm.save('한'), isFalse);
    expect(vm.nicknameError, isNotNull);
    expect(await vm.save('테스트회원'), isTrue);
    expect(
      h.protectedAdapter.requests.where((o) => o.method == 'PATCH'),
      isEmpty,
    );
    expect(await vm.save('변경닉네임'), isTrue);
    expect(h.auth.member!.nickname, '변경닉네임');
  });
  for (final code in ['MEMBER409_1', 'COMMON400', 'COMMON503']) {
    test('프로필 $code: 입력/중복은 필드 오류, 통신 실패는 재시도, 로그인 유지', () async {
      final h = Harness(
        protectedReply: (o) => o.method == 'PATCH'
            ? failure(
                code.contains('409')
                    ? 409
                    : code.contains('400')
                    ? 400
                    : 503,
                code,
              )
            : good(me()),
      );
      addTearDown(h.dispose);
      await h.login();
      final vm = EditProfileViewModel(h.memberApi, h.auth);
      addTearDown(vm.dispose);
      expect(await vm.save('바꿀닉네임'), isFalse);
      expect(code == 'COMMON503' ? vm.message : vm.nicknameError, isNotNull);
      expect(h.auth.status, AuthStatus.signedIn);
    });
  }
  test('늦은 프로필 PATCH 응답은 새 회원 정보를 덮지 않는다', () async {
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    final h = Harness(
      protectedReply: (o) {
        if (o.method == 'PATCH') {
          started.complete();
          return pending.future;
        }
        return good(me());
      },
    );
    addTearDown(h.dispose);
    await h.login();
    final vm = EditProfileViewModel(h.memberApi, h.auth);
    addTearDown(vm.dispose);
    final save = vm.save('바꿀닉네임');
    await started.future;
    await h.auth.logout();
    await h.login();
    pending.complete(good(me('이전응답')));
    expect(await save, isFalse);
    expect(h.auth.member!.nickname, '테스트회원');
  });
  test('프로필 수정 전에 시작한 GET me는 늦게 도착해도 새 닉네임을 덮지 않는다', () async {
    var delayGet = false;
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    final h = Harness(
      protectedReply: (o) {
        if (o.method == 'PATCH') return good(me('새닉네임'));
        if (delayGet) {
          started.complete();
          return pending.future;
        }
        return good(me());
      },
    );
    addTearDown(h.dispose);
    await h.login();
    delayGet = true;
    final loading = h.auth.loadMember(force: true);
    await started.future;
    final vm = EditProfileViewModel(h.memberApi, h.auth);
    addTearDown(vm.dispose);
    expect(await vm.save('새닉네임'), isTrue);
    pending.complete(good(me('이전닉네임')));
    await loading;
    expect(h.auth.member!.nickname, '새닉네임');
    expect(h.auth.memberStatus, MemberLoadStatus.success);
  });
  test('모든 보호 경로 redirect와 공개 가입 경로, 초기화/실패 스플래시', () {
    for (final path in [
      '/home',
      '/movies',
      '/my',
      '/my/profile/edit',
      '/my/ratings',
      '/movie/550',
    ]) {
      expect(authRedirect(AuthStatus.signedOut, path), '/login');
      expect(authRedirect(AuthStatus.retryRequired, path), '/start');
      expect(authRedirect(AuthStatus.initializing, path), '/start');
    }
    expect(authRedirect(AuthStatus.signedOut, '/register'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
  });
  test(
    'SecureTokenStorage write/read/delete 플러그인 호출 계약 (OS 보안 검증과 별개)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final store = <String, String>{};
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            final a = call.arguments as Map;
            final key = a['key'] as String;
            if (call.method == 'write') {
              store[key] = a['value'] as String;
              return null;
            }
            if (call.method == 'read') return store[key];
            if (call.method == 'delete') {
              store.remove(key);
              return null;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final storage = SecureTokenStorage(const FlutterSecureStorage());
      await storage.saveAccessToken('fixture');
      expect(await storage.readAccessToken(), isNotNull);
      await storage.deleteAccessToken();
      expect(await storage.readAccessToken(), isNull);
      expect(calls, ['write', 'read', 'delete', 'read']);
    },
  );
  for (final width in [320.0, 360.0]) {
    testWidgets('작은 화면 $width 평점 Dialog 별 5개와 키보드 입력', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(onSubmit: (_, _) async {}),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var score = 1; score <= 5; score++) {
        await tester.tap(find.byTooltip('$score점'));
        await tester.pump();
        expect(find.text('$score / 5점'), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), '입력 유지');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('입력 유지'), findsOneWidget);
    });
  }
  testWidgets('평점 403은 Dialog 입력 유지와 Snackbar 안내, 로그아웃 없음', (tester) async {
    final h = Harness(
      protectedReply: (o) =>
          o.path.endsWith('/me') ? good(me()) : failure(403, 'RATING403_1'),
    );
    addTearDown(h.dispose);
    await tester.runAsync(() => h.login());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: h.auth),
          ChangeNotifierProvider<SessionRatingsViewModel>.value(
            value: h.ratings,
          ),
        ],
        child: const MaterialApp(
          home: TmdbMovieDetailScreen(movie: fixture.movie),
        ),
      ),
    );
    await tester.ensureVisible(find.text('평점 남기기'));
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5점'));
    await tester.enterText(find.byType(TextField), '보존할 후기');
    await tester.runAsync(() async {
      await tester.tap(find.text('확인'));
      await waitForState(h.ratings, () => !h.ratings.isWriting);
    });
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('보존할 후기'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('테스트 오류 RATING403_1'), findsNWidgets(2));
    expect(h.auth.status, AuthStatus.signedIn);
  });
  testWidgets('프로필 중복 입력 유지·이메일 읽기 전용·저장 성공 즉시 반영', (tester) async {
    var reject = true;
    final h = Harness(
      protectedReply: (o) => o.method == 'PATCH'
          ? (reject ? failure(409, 'MEMBER409_1') : good(me('변경닉네임')))
          : good(me()),
    );
    addTearDown(h.dispose);
    await tester.runAsync(() => h.login());
    final vm = EditProfileViewModel(h.memberApi, h.auth);
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: h.auth),
          ChangeNotifierProvider<EditProfileViewModel>.value(value: vm),
        ],
        child: const MaterialApp(home: EditProfileScreen()),
      ),
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      isFalse,
    );
    // 별도 라우터 없이 실패 UI만 먼저 검증하고 성공 상태는 ViewModel에서 검증합니다.
    final field = find.byType(TextField).last;
    await tester.enterText(field, '바꿀닉네임');
    await tester.runAsync(() async {
      await tester.tap(find.text('저장'));
      await waitForState(vm, () => vm.status != EditProfileStatus.saving);
    });
    await tester.pumpAndSettle();
    expect(find.text('바꿀닉네임'), findsOneWidget);
    expect(find.text('테스트 오류 MEMBER409_1'), findsOneWidget);
    reject = false;
    expect(await tester.runAsync(() => vm.save('변경닉네임')), isTrue);
    expect(h.auth.member!.nickname, '변경닉네임');
  });
  testWidgets('Router 로그인 화면·만료 Snackbar 1회·로그아웃 보호 화면 차단', (tester) async {
    final h = Harness();
    addTearDown(h.dispose);
    await h.auth.restoreSession();
    final router = createAppRouter(h.auth);
    addTearDown(router.dispose);
    final movies = TmdbMovieService(
      fixture.client(
        fixture.StubAdapter(
          (o) => fixture.jsonReply(
            o.path.contains('/genre/')
                ? {'genres': []}
                : {
                    'page': 1,
                    'total_pages': 1,
                    'total_results': 0,
                    'results': [],
                  },
            200,
          ),
        ),
      ),
    );
    final home = MovieHomeViewModel(movies)..loadPopular();
    addTearDown(home.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: h.auth),
          ChangeNotifierProvider<SessionRatingsViewModel>.value(
            value: h.ratings,
          ),
          ChangeNotifierProvider<MovieHomeViewModel>.value(value: home),
          Provider<TmdbMovieService>.value(value: movies),
          Provider<MemberApiService>.value(value: h.memberApi),
          Provider<RatingApiService>.value(value: h.ratingApi),
          Provider<SignUpService>(create: (_) => SignUpService(h.publicDio)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.invalid',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Fixture1!');
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await waitForState(
        h.auth,
        () => h.auth.status != AuthStatus.authenticating,
      );
    });
    await tester.pump();
    await pumpUntil(
      tester,
      () => h.auth.memberStatus == MemberLoadStatus.success,
    );

    await tester.pumpAndSettle();
    router.go('/my');
    await tester.pumpAndSettle();
    expect(find.text('테스트회원'), findsOneWidget);
    router.push('/my/profile/edit');
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.runAsync(
      () => h.auth.expireSession(expectedVersion: h.auth.sessionVersion),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    router.go('/my/ratings');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(h.auth.sessionExpired, isFalse);
  });
}
