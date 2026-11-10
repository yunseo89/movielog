# 검증 결과 — 2026-11-10

## 완료한 검증

| 항목 | 결과 | 범위 |
|---|---|---|
| 기반 브랜치 | `feature/week-6`, `d6b2b8d` | 실제 6주차 커밋에서 작업 시작 |
| Flutter / Dart | 3.47.9 / 3.13.7 | stable SDK |
| `flutter analyze --no-pub` | **No issues found!** | 앱 및 테스트 코드 |
| `flutter test --no-pub --reporter expanded` | **23 tests passed** | 모델·서비스·ViewModel·실제 Flutter 위젯 |
| Android debug APK | **빌드 성공** | Android ARM64 + x86_64, Android SDK 36, JDK 21 |
| `git diff --check` | 통과 | 공백 오류 검사 |
| v6 Swagger 확인 | 확인 | 실제 `https://workbook.devnoco.com/docs/v6-json`을 읽고 계약 비교 |
| 실제 v6 중복 확인 GET | 200, available 직접 객체 | 읽기 요청만 확인, 계정/평점 생성 안 함 |
| Flutter Web 빌드 | 성공 | 보조 컴파일 검사. Android 기기 실행을 대신하지 않음 |

테스트 소스: `test/week7_test.dart`. Dio 전송 계층에 메모리 가상 응답을 넣어 재현하며 실제 서비스에 쓰기 요청을 보내지 않는다. 테스트 이메일·memberId·ratingId·영화 DTO는 테스트 픽스처이며 실제 계정 생성 결과가 아니다.

## 23개 테스트 내용

1. 비밀번호 원문 유지, 요청 JSON, 정수 score 범위와 NaN/Infinity 거부.
2. v6 경로, GET 직접 객체·배열, 가입 wrapper, 등록 result=null, PATCH 기존 comment·명시적 null, DELETE 204.
3. 가입 400 비밀번호 오류 → 필드 오류.
4. 가입 다른 400 → Snackbar 메시지.
5. 가입 최종 409 → Snackbar 메시지와 입력 변경 시 서버 오류 무효화.
6. 중복 확인 available=false는 duplicated로 분리.
7. 중복 확인 통신 실패는 error로 분리.
8. 가입 연속 탭 방지와 성공 result.memberId 확인.
9. 가입 result.memberId가 없으면 성공 처리 안 함.
10. 입력 변경 뒤 늦게 도착한 중복 확인 응답 무시.
11. 상세 등록에 세션 ID와 선택한 TMDB DTO.id 전달, ID 없으면 쓰기 금지.
12. PATCH 성공 → GET 실패 → GET 재시도, PATCH는 한 번만 전송.
13. DELETE 204 → GET 빈 배열 → empty UI 상태.
14~17. 평점 400/403/404/409 메시지를 구분하고 403/404만 재조회.
18. dispose 뒤 도착한 목록 응답 무시.
19. 비공통 오류에서 내부 원문 대신 안전한 안내.
20. 별점 없으면 확인 비활성, 저장 중 이탈 방지, 실패 뒤 입력 보존.
21. 수정 Dialog 초기 점수·코멘트와 저장 성공 뒤 닫힘.
22. 삭제 취소 시 API 없음, 삭제 중 Dialog 유지·이탈 방지, 성공 뒤 닫힘.
23. 실제 가입 화면 입력·중복 확인·약관 동의·제출 콜백 → 세션 저장 → 영화 탭 이동.

## 아직 직접 확인하지 않은 범위

- Android 에뮬레이터/실기기에 설치한 뒤의 실행과 녹화. 이 환경에는 실행할 Android 기기가 연결되어 있지 않다.
- 사용자의 로컬 TMDB 토큰으로 영화 목록을 불러오는 과정. `.env`는 Git에서 제외되어 이 환경에 전달되지 않았다. 빌드는 비어 있는 로컬 `.env`로 컴파일 검증했다. **기존 PC의 `.env`를 유지한 채 새 코드를 실행해야 한다.**
- 실제 본인 학습용 계정 가입 → 평점 등록·수정·삭제의 서버 저장 결과.
- 실제 서버 최종 가입 409 경합, GET만 실패하는 시점의 Android 영상. 가상 응답 테스트와 실서버 증거를 구분한다.
- Challenge의 다중 선택 삭제: 이번 필수미션 구현에 포함하지 않음.

수동 절차는 `WEEK7_MANUAL_CHECK.md`, 워크북 설명/제출 양식은 `WEEK7_WORKBOOK.md`를 참고한다. 회원 ID는 인증 수단이 아니며 JWT 로그인은 구현 범위에 없다.

## GitHub 반영

사용자가 반영 전 확인 요청에 답하면서 PR 대상을 `main`으로 지정했다. 이에 따라 `feature/week-7`을 게시하고 `main` 대상으로 PR을 생성한다. 기반 6주차 커밋과 현재 main의 파일 트리는 같으며, 새 커밋은 main 위에 쌓는다. PR은 별도 검토 후 병합한다.
