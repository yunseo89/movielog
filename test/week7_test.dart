import 'package:provider/provider.dart';
import 'package:movielog/sign_up_screen.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/api_error.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/delete_rating_dialog.dart';
import 'package:movielog/widgets/movielog_button.dart';

// 메모리 안에서만 동작하는 전송 계층입니다. 실제 서버나 타인 데이터를 사용하지 않습니다.
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.reply);
  final FutureOr<ResponseBody> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return await reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonReply(Object? body, int status) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
Map<String, Object?> common(int status, {Object? result, String? message}) => {
  'isSuccess': status < 400,
  'code': 'COMMON$status',
  'message': message ?? '테스트 응답',
  'result': result,
};
Dio client(StubAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = adapter;
const request = CreateMemberRequest(
  email: 'test@example.invalid',
  password: 'Example1!',
  nickname: '테스트',
);
Future<void> checked(SignUpViewModel vm) async {
  vm.onNicknameChanged(request.nickname);
  vm.onEmailChanged(request.email);
  await vm.checkNickname(request.nickname);
  await vm.checkEmail(request.email);
}

const movie = TmdbMovieDto(
  id: 550,
  title: '테스트 영화',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: null,
  genreIds: [],
  voteAverage: 0,
  popularity: 0,
);
Map<String, Object?> rating() => {
  'ratingId': 91,
  'movieId': 550,
  'score': 4,
  'comment': '기존 후기',
  'createdAt': '2026-11-10T00:00:00Z',
};
TmdbMovieService movieService() => TmdbMovieService(
  client(StubAdapter((_) => jsonReply({'id': 550, 'title': '테스트 영화'}, 200))),
);

void main() {
  test('요청 JSON은 비밀번호를 변경하지 않고 정수 score와 실제 TMDB id를 보낸다', () {
    expect(
      const CreateMemberRequest(
        email: ' a@b.co ',
        password: ' Example1! ',
        nickname: ' 이름 ',
      ).toJson(),
      {'email': 'a@b.co', 'password': ' Example1! ', 'nickname': '이름'},
    );
    expect(validatePasswordFormat('weakpass'), isNotNull);
    expect(validatePasswordFormat('Example1!'), isNull);
    for (final value in [0.0, 0.5, 3.5, 6.0, double.nan, double.infinity]) {
      expect(() => validateServerScore(value), throwsArgumentError);
    }
    expect(
      const CreateRatingRequest(movieId: 550, score: 5, comment: '  ').toJson(),
      {'movieId': 550, 'score': 5},
    );
  });

  test(
    'v6 직접 객체·배열 / 201 wrapper / PATCH comment null / DELETE 204 계약',
    () async {
      final adapter = StubAdapter((o) {
        if (o.method == 'DELETE') return jsonReply(null, 204);
        if (o.method == 'PATCH') return jsonReply(common(200), 200);
        if (o.method == 'POST' && o.path == '/v6/members') {
          return jsonReply(
            common(
              201,
              result: {
                'memberId': 42,
                'email': request.email,
                'nickname': request.nickname,
              },
            ),
            201,
          );
        }
        if (o.method == 'POST') return jsonReply(common(201), 201);
        if (o.path.endsWith('/ratings')) return jsonReply([rating()], 200);
        return jsonReply({'available': true}, 200);
      });
      final dio = client(adapter);
      final signUp = SignUpService(dio);
      expect(await signUp.checkNickname('한 글'), isTrue);
      expect(await signUp.checkEmail(request.email), isTrue);
      expect((await signUp.signUp(request)).result!.memberId, 42);
      final service = RatingApiService(dio);
      expect((await service.fetchMyRatings(42)).single.movieId, 550);
      await service.createRating(
        memberId: 42,
        request: const CreateRatingRequest(movieId: 550, score: 4),
      );
      await service.updateRating(
        memberId: 42,
        ratingId: 91,
        score: 5,
        comment: '기존 후기',
      );
      expect(adapter.requests.last.data, {'score': 5, 'comment': '기존 후기'});
      await service.updateRating(memberId: 42, ratingId: 91, score: 5);
      expect(adapter.requests.last.data, {'score': 5, 'comment': null});
      await service.deleteRating(memberId: 42, ratingId: 91);
      expect(adapter.requests.every((o) => o.path.startsWith('/v6/')), isTrue);
      expect(
        adapter.requests.every((o) => !o.headers.containsKey('Authorization')),
        isTrue,
      );
    },
  );

  for (final entry in [
    (400, '비밀번호 형식 오류', true),
    (400, '이메일 형식 오류', false),
    (409, '이미 사용 중인 이메일입니다.', false),
  ]) {
    test('가입 ${entry.$1} ${entry.$2}: 필드 오류와 Snackbar 분리', () async {
      final adapter = StubAdapter(
        (o) => o.method == 'POST'
            ? jsonReply(common(entry.$1, message: entry.$2), entry.$1)
            : jsonReply({'available': true}, 200),
      );
      final vm = SignUpViewModel(SignUpService(client(adapter)));
      await checked(vm);
      await vm.submit(request);
      expect(vm.submitStatus, SubmitStatus.error);
      expect(vm.passwordErrorText, entry.$3 ? entry.$2 : isNull);
      expect(vm.snackbarMessage, entry.$3 ? isNull : entry.$2);
      vm.onNicknameChanged('새닉네임');
      expect(vm.canSubmit, isFalse);
      expect(vm.passwordErrorText, isNull);
      expect(vm.snackbarMessage, isNull);
      vm.dispose();
    });
  }

  test('최종 POST 409와 GET available=false는 별도 상태', () async {
    final vm = SignUpViewModel(
      SignUpService(
        client(StubAdapter((_) => jsonReply({'available': false}, 200))),
      ),
    );
    await checked(vm);
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(vm.canSubmit, isFalse);
    vm.dispose();
  });
  test('가입 통신 실패와 중복 상태 구별', () async {
    final vm = SignUpViewModel(
      SignUpService(client(StubAdapter((_) => jsonReply(common(503), 503)))),
    );
    vm.onEmailChanged(request.email);
    await vm.checkEmail(request.email);
    expect(vm.emailCheckStatus, CheckStatus.error);
    vm.dispose();
  });
  test('가입 중 연속 탭 방지, 성공 memberId 저장', () async {
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    final adapter = StubAdapter((o) {
      if (o.method == 'POST') {
        started.complete();
        return pending.future;
      }
      return jsonReply({'available': true}, 200);
    });
    final vm = SignUpViewModel(SignUpService(client(adapter)));
    await checked(vm);
    final first = vm.submit(request);
    await started.future;
    await vm.submit(request);
    expect(adapter.requests.where((o) => o.method == 'POST').length, 1);
    pending.complete(
      jsonReply(
        common(
          201,
          result: {
            'memberId': 42,
            'email': request.email,
            'nickname': request.nickname,
          },
        ),
        201,
      ),
    );
    await first;
    expect(vm.createdMemberId, 42);
    expect(vm.submitStatus, SubmitStatus.success);
    vm.dispose();
  });
  test('가입 결과 memberId null은 성공 처리하지 않는다', () async {
    final vm = SignUpViewModel(
      SignUpService(
        client(
          StubAdapter(
            (o) => o.method == 'POST'
                ? jsonReply(common(201), 201)
                : jsonReply({'available': true}, 200),
          ),
        ),
      ),
    );
    await checked(vm);
    await vm.submit(request);
    expect(vm.submitStatus, SubmitStatus.error);
    expect(vm.createdMemberId, isNull);
    vm.dispose();
  });
  test('입력 변경 뒤 늦게 도착한 중복 확인 응답 무시', () async {
    final pending = Completer<ResponseBody>();
    final vm = SignUpViewModel(
      SignUpService(client(StubAdapter((_) => pending.future))),
    );
    vm.onNicknameChanged('기존이름');
    final first = vm.checkNickname('기존이름');
    vm.onNicknameChanged('새이름');
    pending.complete(jsonReply({'available': true}, 200));
    await first;
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    vm.dispose();
  });
  test('영화 상세는 세션 memberId와 선택한 TMDB id로 등록', () async {
    final adapter = StubAdapter((_) => jsonReply(common(201, result: 91), 201));
    final service = RatingApiService(client(adapter));
    final vm = MovieDetailViewModel(service, 42, movie);
    await vm.createRating(score: 5, comment: '후기');
    expect(adapter.requests.single.path, '/v6/members/42/ratings');
    expect(adapter.requests.single.data, {
      'movieId': 550,
      'score': 5,
      'comment': '후기',
    });
    expect(vm.submitStatus, SubmitStatus.success);
    vm.dispose();
    final noMember = MovieDetailViewModel(service, null, movie);
    await noMember.createRating(score: 5);
    expect(noMember.submitStatus, SubmitStatus.error);
    expect(adapter.requests.length, 1);
    noMember.dispose();
  });
  test('수정 성공 뒤 GET 실패 시 GET만 재시도, PATCH 중복 없음', () async {
    var failGet = true;
    final adapter = StubAdapter(
      (o) => o.method == 'PATCH'
          ? jsonReply(common(200), 200)
          : failGet
          ? jsonReply(common(503), 503)
          : jsonReply([rating()], 200),
    );
    final vm = MyRatingsViewModel(
      RatingApiService(client(adapter)),
      movieService(),
      42,
    );
    await vm.updateRating(ratingId: 91, score: 4, comment: '기존 후기');
    expect(vm.refreshPending, isTrue);
    expect(vm.status, MyRatingsLoadStatus.error);
    expect(vm.isWriting, isFalse);
    failGet = false;
    await vm.load();
    expect(vm.refreshPending, isFalse);
    expect(vm.ratings.single.movie!.id, 550);
    expect(adapter.requests.map((o) => o.method), ['PATCH', 'GET', 'GET']);
    vm.dispose();
  });
  test('삭제 204 뒤 마지막 목록은 empty', () async {
    final adapter = StubAdapter(
      (o) => o.method == 'DELETE' ? jsonReply(null, 204) : jsonReply([], 200),
    );
    final vm = MyRatingsViewModel(
      RatingApiService(client(adapter)),
      movieService(),
      42,
    );
    await vm.deleteRating(91);
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(adapter.requests.map((o) => o.method), ['DELETE', 'GET']);
    vm.dispose();
  });
  for (final status in [400, 403, 404, 409]) {
    test('평점 $status 구분 및 403/404만 GET 재조회', () async {
      final adapter = StubAdapter(
        (o) => o.method == 'PATCH'
            ? jsonReply(common(status, message: '오류 $status'), status)
            : jsonReply([], 200),
      );
      final vm = MyRatingsViewModel(
        RatingApiService(client(adapter)),
        movieService(),
        42,
      );
      await expectLater(
        vm.updateRating(ratingId: 91, score: 4),
        throwsStateError,
      );
      expect(vm.writeMessage, '오류 $status');
      expect(vm.isWriting, isFalse);
      expect(
        adapter.requests.where((o) => o.method == 'GET').length,
        [403, 404].contains(status) ? 1 : 0,
      );
      vm.dispose();
    });
  }
  test('dispose 뒤 늦은 조회 결과를 반영하지 않는다', () async {
    final pending = Completer<ResponseBody>();
    final vm = MyRatingsViewModel(
      RatingApiService(client(StubAdapter((_) => pending.future))),
      movieService(),
      42,
    );
    final load = vm.load();
    vm.dispose();
    pending.complete(jsonReply([rating()], 200));
    await load;
    expect(vm.ratings, isEmpty);
  });
  test('비공통 오류도 안전한 안내 문구', () {
    expect(
      apiErrorMessage(StateError('private payload')),
      isNot(contains('private payload')),
    );
  });

  Future<void> openDialog(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => dialog,
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('별점 미선택 시 확인 비활성, 실패 시 입력 유지, 요청 중 이탈 방지', (tester) async {
    final pending = Completer<void>();
    var count = 0;
    await openDialog(
      tester,
      RatingDialog(
        onSubmit: (score, comment) {
          count++;
          expect(score, 4);
          expect(comment, '입력 보존');
          return pending.future;
        },
      ),
    );
    expect(
      tester
          .widget<MovieLogButton>(find.widgetWithText(MovieLogButton, '확인'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '입력 보존');
    await tester.tap(find.byTooltip('4점'));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RatingDialog), findsOneWidget);
    expect(count, 1);
    pending.completeError(StateError('저장 실패 409'));
    await tester.pumpAndSettle();
    expect(find.text('입력 보존'), findsOneWidget);
    expect(find.text('저장 실패 409'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
  testWidgets('수정 Dialog 기존 별점·코멘트 초기값과 성공 후 닫기', (tester) async {
    await openDialog(
      tester,
      RatingDialog(
        initialScore: 4,
        initialComment: '기존 후기',
        onSubmit: (score, comment) async {
          expect(score, 4);
          expect(comment, '기존 후기');
        },
      ),
    );
    expect(find.text('기존 후기'), findsOneWidget);
    expect(find.text('4 / 5점'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsNothing);
  });
  testWidgets('삭제 취소는 API를 호출하지 않고, 삭제 중에는 Dialog 유지', (tester) async {
    var count = 0;
    final pending = Completer<void>();
    await openDialog(
      tester,
      DeleteRatingDialog(
        onDelete: () {
          count++;
          return pending.future;
        },
      ),
    );
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(count, 0);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pump();
    expect(count, 1);
    expect(find.byType(DeleteRatingDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(DeleteRatingDialog), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DeleteRatingDialog), findsNothing);
  });
  testWidgets('가입 화면에서 실제 콜백 연결 → 세션 저장 → 영화 탭 이동', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = LearningMemberSession();
    final adapter = StubAdapter(
      (o) => o.method == 'POST'
          ? jsonReply(
              common(
                201,
                result: {
                  'memberId': 42,
                  'email': request.email,
                  'nickname': request.nickname,
                },
              ),
              201,
            )
          : jsonReply({'available': true}, 200),
    );
    final tmdb = TmdbMovieService(
      client(
        StubAdapter(
          (o) => jsonReply(
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
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SignUpService>(
            create: (_) => SignUpService(client(adapter)),
          ),
          Provider<TmdbMovieService>.value(value: tmdb),
          ChangeNotifierProvider<LearningMemberSession>.value(value: session),
          ChangeNotifierProvider(create: (_) => MovieHomeViewModel(tmdb)..loadPopular()),
        ],
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), request.nickname);
    await tester.enterText(find.byType(TextFormField).at(1), request.email);
    await tester.enterText(find.byType(TextFormField).at(2), request.password);
    await tester.tap(find.text('중복 확인').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('중복 확인').at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();
    expect(session.memberId, 42);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('회원가입 완료 · 학습용 memberId: 42'), findsOneWidget);
  });
}
