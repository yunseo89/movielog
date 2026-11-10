# 7주차 워크북 작성 가이드

이 문서는 구현한 코드로 설명할 수 있는 내용입니다. 실제 계정·기기 촬영 증거는 수동 검증 후 제출 양식에 추가하세요. 자동 테스트의 가상 응답을 실제 서버 성공 기록으로 제출하지 않습니다.

## 학습 목표 정리 — 그대로 참고해 작성하기

### CRUD와 HTTP Method

| 작업 | 요청 | 성공 응답 | 구현 처리 |
|---|---|---|---|
| 회원가입 | POST `/v6/members` | 201 + CommonResponse<SignUpResult> | result.memberId 확인 후 메모리 세션 저장 |
| 중복 확인 | GET `/v6/members/nickname/{nickname}`, `/email/{email}` | 200 + `{available: bool}` | wrapper 없이 직접 객체 파싱 |
| 내 평점 조회 | GET `/v6/members/{memberId}/ratings` | 200 + 배열 | 직접 배열을 RatingDto 목록으로 변환 |
| 평점 등록 | POST `/v6/members/{memberId}/ratings` | 201 + wrapper | result는 숫자/null 모두 허용 |
| 평점 수정 | PATCH `/v6/members/{memberId}/ratings/{ratingId}` | 200 + wrapper, result null | score와 comment를 명시적으로 전송 |
| 평점 삭제 | DELETE `/v6/members/{memberId}/ratings/{ratingId}` | 204, body 없음 | 상태 코드만 확인, JSON 파싱 안 함 |

`toJson()`은 Dart 객체를 요청 body인 Map으로 바꾼다. `fromJson()`은 응답 JSON을 Dart 모델로 바꾼다. `CommonResponse<T>`는 공통 상태와 payload를 분리하며 result를 두 번 감싸지 않는다.

### 회원가입과 학습용 회원 상태

닉네임은 2~12자, 이메일은 이메일 형식, 비밀번호는 8자 이상이며 대문자·소문자·숫자·`!@#$%^&*` 중 특수문자가 각각 하나 이상 필요하다. 이메일과 닉네임은 trim하지만 비밀번호는 바꾸지 않는다.

두 중복 확인이 현재 입력값에 대해 모두 available인 경우에만 가입하기가 활성화된다. 입력을 변경하면 이전 확인 결과와 서버 제출 오류를 무효화한다. 비동기 중복 확인은 요청 버전과 현재 입력을 비교해서 오래된 응답을 무시한다.

POST가 성공하면 result.memberId가 있는지 확인하고 `LearningMemberSession`에 저장한다. 이후 상세 등록과 마이페이지 조회·수정·삭제가 같은 ID를 사용한다. ID가 없으면 임의로 1을 사용하지 않는다. memberId를 아는 것은 인증이 아니며 이 상태는 재실행 시 사라진다.

### movieId와 ratingId

`TmdbMovieDto.id`는 영화 자체를 가리키는 TMDB ID이다. 상세 화면에서 전달받은 DTO의 id를 POST body의 movieId로 그대로 보낸다. 배열 index가 아니다.

`RatingDto.ratingId`는 서버가 만든 평점의 ID이다. 수정·삭제 path에는 movieId 대신 ratingId를 사용한다. 내 평점 목록의 제목·포스터는 rating.movieId로 TMDB 영화 DTO를 조회해 연결한다. TMDB만 실패해도 평점 자체는 표시하고 제목·포스터에 대체 UI를 사용한다.

### 평점 Dialog와 쓰기 실패

초기 별점은 0이라 확인 버튼이 비활성이다. 별을 누르면 1~5 정수로 선택된다. 코멘트는 선택 입력이며 500자까지 허용한다. 등록 때 빈 코멘트는 생략하고 수정 때 빈 코멘트는 null로 보내 기존 후기를 삭제한다. 수정 Dialog는 기존 별점·코멘트로 시작하므로 그대로 확인하면 기존 후기가 유지된다.

입력 컨트롤러는 State에서 한 번 만들고 dispose한다. 저장 중에는 입력·취소·확인 버튼을 막고 로딩을 보여준다. `barrierDismissible: false`와 `PopScope`를 함께 사용한다. 실패하면 Dialog가 열린 채 입력을 보존하고 서버 메시지를 보여준다.

### 저장 성공과 재조회 실패

수정·삭제 요청과 후속 GET을 서로 다른 단계로 처리한다. 쓰기가 성공하면 refreshPending을 true로 두고 GET한다. 이 GET만 실패하면 쓰기 실패 예외를 던지지 않으므로 Dialog는 정상 종료되고 “저장 완료 · 목록 새로고침”을 안내한다. 화면의 재시도는 load()만 호출하므로 PATCH/DELETE를 재전송하지 않는다. 상세 등록은 성공 Snackbar를 표시하고, 마이페이지 진입 시 새 GET으로 확인한다.

### 오류 구분

| 응답 | UI/복구 |
|---|---|
| 가입 400 + 비밀번호 명시 메시지 | passwordErrorText → 비밀번호 입력칸 |
| 가입 다른 400 / 최종 409 | 서버 메시지 → Snackbar |
| 평점 400 | 입력을 보존하고 서버 입력 오류 안내 |
| 평점 403 | 소유권 오류 메시지 + 내 목록 재조회 |
| 평점 404 | 해당 작업의 서버 메시지 + 내 목록 재조회 |
| 평점 409 | 중복 등록 안내, 값과 입력 보존 |
| 네트워크/비정상 응답 | 일반 오류 안내, 비밀번호나 원문 요청을 로그에 남기지 않음 |

본인 세션의 목록만 조회하며 그 목록 카드에만 수정·삭제 버튼을 표시한다. v6는 인증이 없는 학습 API이므로 이 UI는 서버 인증을 대체하지 않는다. 타인의 ID로 테스트하지 않는다.

## 필수미션 → 코드 위치

| 워크북 항목 | 파일 |
|---|---|
| 공통 응답/가입 요청·결과 | `lib/data/models/common_response.dart`, `create_member_request.dart`, `sign_up_models.dart` |
| v6 중복 확인과 가입 POST | `lib/data/services/sign_up_service.dart` |
| 입력 변경 무효화, 최종 400/409, 중복 탭 방지 | `lib/view_models/sign_up_view_model.dart`, `lib/sign_up_screen.dart` |
| 가입 ID 전달 | `lib/view_models/learning_member_session.dart`, `lib/app/movie_log_app.dart`, `lib/profile_screen.dart` |
| 정수 score·코멘트 JSON | `lib/data/models/rating_request.dart` |
| 별점·코멘트, 초기값, 실패 입력 보존·이탈 방지 | `lib/widgets/rating_dialog.dart` |
| 상세 등록과 Snackbar | `lib/view_models/movie_detail_view_model.dart`, `lib/screens/tmdb_movie_detail_screen.dart` |
| GET/POST/PATCH/DELETE 계약 | `lib/data/services/rating_api_service.dart` |
| 조회 네 상태·재조회 실패 분리·오래된 응답 무시 | `lib/view_models/my_ratings_view_model.dart` |
| 카드별 수정·삭제, 하단 탭 없는 상세 목록 | `lib/screens/my_ratings_screen.dart` |
| 삭제 취소·삭제 중 Dialog 유지 | `lib/widgets/delete_rating_dialog.dart` |
| 400/403/404/409 메시지/재조회 행동 | `lib/data/services/api_error.dart` |
| 재현 가능한 자동 검증 | `test/week7_test.dart` |

기존 6주차 코드는 Navigator를 사용하므로 GoRouter를 새로 도입하지 않았다. 선택한 DTO는 화면 생성자에 전달하고 내 평점 화면은 루트 Navigator에 push한다. 따라서 하단 NavigationBar가 새 화면에 표시되지 않는다. 정수 별점 입력은 기존 SDK의 IconButton 별 5개로 구현해 반 점 선택을 원천적으로 막는다.

## 제출 양식 — 실제 확인 뒤 대괄호를 채우기

```text
PR 링크: [GitHub 반영 승인 후 생성한 PR URL]
생성한 본인 테스트 계정(비밀번호 제외): [직접 만든 닉네임/이메일, result.memberId]
닉네임/이메일 확인과 입력 변경 무효화: [촬영 번호]
회원가입 결과와 최종 409: [촬영 번호 / 테스트 증거를 구분]
선택한 TMDB id → MovieLog movieId 증거: [실제로 선택한 DTO.id, 요청 movieId]
등록→조회→수정→조회→삭제→조회 증거: [Android 촬영 영상]
오류 code 처리 증거: [400/403/404/409 자동 테스트 + 직접 확인한 화면]
저장 성공/재조회 실패 분리 증거: PATCH → GET 실패 → GET 재시도, PATCH는 1회 (자동 테스트)
트러블슈팅: [아래 내용과 본인의 실행 이슈]
미검증 항목: [실제 서버에서 아직 실행하지 않은 항목 / 기기 영상 등]
```

## 트러블슈팅 작성 예시

```text
작업: 평점 수정
요청 Method·Path: PATCH /v6/members/{본인ID}/ratings/{평점ID}
요청 body: {"score": 4, "comment": "기존 후기"}
기대 status·body: 200, 공통 응답, result=null
원인과 수정: PATCH에서 comment를 생략하면 후기 삭제로 해석된다.
             유지할 때도 초기 코멘트를 명시적으로 보내고, 지울 때만 null을 보낸다.
재검증: test/week7_test.dart의 계약 테스트에서 기존 후기/명시적 null을 각각 확인.
실제 서버 검증: [본인 계정으로 확인한 결과 추가]
```

```text
작업: 수정 후 목록 재조회
기대 상태: PATCH 성공과 GET 성공을 별도로 처리
문제: GET 실패를 저장 실패로 처리하면 사용자가 PATCH/POST를 반복할 수 있다.
수정: refreshPending을 두고 GET 실패 화면에서 load()만 재시도한다.
재검증: 자동 테스트 요청 순서가 PATCH, GET, GET이고 PATCH는 1회임을 확인.
```
