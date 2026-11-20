# 8주차 Required 미션 구현·학습 정리

## 무엇이 바뀌었나

7주차에는 가입 결과의 memberId를 메모리에만 저장하고 v6 평점 path에 사용했다. 8주차에는 로그인 응답의 accessToken을 보안 저장소에 저장하고, v7 보호 API의 Authorization 헤더로 전달한다. 사용자를 식별하는 책임을 서버의 토큰 검증으로 옮겼다.

| 항목 | 7주차 | 8주차 |
|---|---|---|
| 인증 | 학습용 memberId 메모리 상태 | v7 로그인 JWT, secure storage |
| 시작 | 가입/시작 화면 | 초기화 전용 스플래시, 서버 검증 후 복원 |
| 등록 | POST /v6/members/{memberId}/ratings | POST /v7/ratings, 201 + Rating 객체 |
| 수정 | PATCH /v6/members/{memberId}/ratings/{ratingId}, result=null | PATCH /v7/ratings/{ratingId}, 200 + Rating 객체 |
| 삭제 | DELETE, 204 body 없음 | DELETE /v7/ratings/{ratingId}, 200 wrapper/result=null |
| 마이페이지 | 고정 닉네임/학습용 ID | GET me의 이메일·닉네임 |
| 닉네임 수정 | 미연결 | PATCH /v7/members/me → member 교체 |
| 평점 목록 | memberId 공개 GET | 현재 세션의 등록 응답만 보관, 전체 복원하지 않음 |
| 라우팅 | Navigator 중심 | GoRouter refreshListenable·redirect, 루트 상세 화면 |

## Required → 코드 위치

| 요구사항 | 구현 |
|---|---|
| 현재 세션 Rating PATCH/DELETE | `session_ratings_view_model.dart`, `my_ratings_screen.dart` |
| v7 상태·result·도메인 오류 파싱 | `rating_api_service.dart`, `response_parser.dart`, `core/network/api_error.dart` |
| 마이페이지 GET me·닉네임 반영 | `auth_view_model.dart`, `profile_screen.dart` |
| /my/profile/edit | `router/app_router.dart`, `edit_profile_screen.dart` |
| 닉네임 2~12자·중복 입력 유지·통신 재시도 | `edit_profile_view_model.dart` |
| 재시작·만료·로그아웃·redirect | `auth_view_model.dart`, `auth_interceptor.dart`, `app_router.dart` |
| 로그아웃 버튼 | `profile_screen.dart` 앱바 |
| 만료 때만 로그인 Snackbar 1회 | `login_screen.dart`의 post-frame 리스너와 consumeSessionExpired |
| 토큰 보안 저장 | `core/storage/token_storage.dart` |

각 파일은 `lib/` 아래에 있습니다.

## 인증 상태 흐름

- 신규 로그인: public Client의 POST 로그인 성공 → secure storage 저장 → signedIn → MainShell의 post-frame `loadMember()` → GET me 결과 보관.
- 재시작: initializing → 토큰 읽기 → 없으면 signedOut, 있으면 GET me → 성공한 뒤에만 signedIn.
- 복원 중 통신/저장소 읽기 실패: 토큰을 지우지 않고 retryRequired, 스플래시에서 다시 시도.
- 보호 API의 AUTH401_2/3/4: 세션 버전 증가 → member와 세션 평점 비우기 → 진행 중 토큰 write 대기 → 토큰 삭제 → signedOut → /login.
- 직접 로그아웃: 같은 정리를 수행하지만 만료 안내 플래그는 켜지 않는다.
- 삭제 자체가 실패하면 복원이 아니라 삭제 재시도를 요구한다. 삭제에 성공한 것처럼 처리하지 않는다.

`sessionVersion`을 요청 시작 시 기록하고 응답 시 비교한다. 따라서 로그아웃·계정 전환 전의 GET/PATCH/평점 응답과 오래된 401이 새 세션에 반영되지 않는다. 동시 401은 한 번만 정리한다. 보안 저장소 작업은 직렬화하며, 정리 중 새 로그인도 막는다. 같은 세션에서도 프로필 수정 전에 시작한 GET me가 최신 닉네임을 덮지 않게 member revision을 검사한다.

## Client와 민감 정보 경계

1. TMDB Client: TMDB Read Access Token만 사용한다.
2. MovieLog public Client: 로그인·회원가입·중복 확인·공개 평점 조회, JWT 없음.
3. MovieLog auth Client: 신뢰한 origin의 GET/PATCH `/v7/members/me`, POST `/v7/ratings`, PATCH/DELETE `/v7/ratings/{id}`에만 JWT 부착.

보호 Client는 예전 Authorization을 제거하고 매 요청마다 저장소에서 읽는다. 외부 URL과 공개 API에 JWT를 붙이지 않으며 보호 요청의 자동 HTTP redirect도 허용하지 않는다. 로그인 password는 요청 중에만 사용하고 로그나 SharedPreferences에 보관하지 않는다. Auth Client에는 요청/응답 원문 Logger를 등록하지 않는다.

## 오류 구분

| code | 처리 |
|---|---|
| AUTH401_1 | 로그인 Form 오류, 만료 처리 안 함 |
| AUTH401_2/3/4 | 해당 요청의 세션 버전이 현재일 때만 만료 정리 |
| RATING403_1 | Dialog 입력 유지·Snackbar 안내, 로그인 유지 |
| RATING409_1 | 중복 등록 안내, 로그인 유지 |
| RATING404_1 | 없어진 세션 카드 제거·안내, 전체 내 목록 GET을 추정하지 않음 |
| MEMBER409_1 | 닉네임 필드 오류, 컨트롤러 입력 유지 |
| COMMON400 / COMMON4001 | 서버 입력 오류를 필드/평점 Dialog 아래에 표시 |
| MEMBER404_1 | 내 정보 재조회 및 오류 안내 |
| 네트워크/기기 저장소 실패 | 일반 재시도 안내, 인증 401로 바꾸거나 자동 로그아웃하지 않음 |

## 영화 정보 결합

평점 등록은 선택한 `TmdbMovieDto.id`를 `CreateRatingRequest.movieId`로 전송한다. 등록 응답의 Rating은 ratingId로 관리하고, 제목·포스터는 movieId로 현재 세션의 `Map<int, TmdbMovieDto>`에서 찾는다. 없는 영화 정보는 `영화 #movieId`와 포스터 placeholder로 표시한다. MovieLog 로그아웃은 이 사용자별 작업 데이터를 비우지만 TMDB 설정과 공개 홈 영화 ViewModel을 지우지는 않는다.

## 제출 양식 — 실제 증거로 채우기

```text
PR 링크: [필요하면 별도로 생성한 PR]
로그인→GET me 증거: [Android 화면/민감 정보 제거한 요청 상태]
재시작 복원 / 로그아웃 / 만료 증거: [영상]
닉네임 수정 증거: [성공, MEMBER409_1, 입력 유지]
평점 v6→v7 변경 표와 동작 영상: [위 표 + Android 영상]
TMDB id → MovieLog movieId → 영화 정보 결합 증거: [중단점/민감 정보 제거한 요청]
401/403/409 처리: [실서버 확인한 항목 + 가상 API 테스트를 구분]
보안 저장 검증 플랫폼·결과: [실제로 사용한 Android 기기/API 레벨, 재시작·로그아웃 결과]
토큰/비밀번호 비노출 확인: [원문 없이 method/path/status/code만 기록]
트러블슈팅: [인증 상태, 재현, 원인, 수정, 재검증]
```

자동 테스트의 MemoryStorage/플러그인 mock 성공을 실제 Android Keystore 검증으로 적지 않는다. 전체 내 평점 복원은 미구현 버그가 아니라 현재 v7 계약의 제한이므로 완료했다고 체크하지 않는다.
