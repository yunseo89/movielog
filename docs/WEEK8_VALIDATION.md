# 8주차 검증 기록

## 기준과 범위

- 기준: `feature/week-7`, commit `bfacc84` (`bfacc84 Update README for Week 7 enhancements`). 기존 사용자가 수정한 작은 화면 별점 Expanded 처리도 포함한 최신 7주차 코드에서 시작했다.
- 작업 브랜치: `feature/week-8`.
- SDK: Flutter 3.47.9 / Dart 3.13.7. 기존 프로젝트에 맞는 SDK에서 검증했다.
- 외부 계약: 실제 `https://workbook.devnoco.com/docs/v7-json`을 읽어 로그인·내 정보·평점 DTO와 성공 status를 비교했다. 실제 계정 가입·로그인·평점 쓰기 요청은 하지 않았다.

## 자동 검증

| 검증 | 결과 |
|---|---|
| flutter analyze --no-pub | No issues found |
| flutter test --no-pub --reporter expanded | 54개 통과 |
| Android ARM64 release APK | 빌드 성공, 21.0MB (기존 개발 서명 설정) |
| git diff --check | 통과 |

원문은 `docs/verification/week8-flutter-analyze.txt`, `week8-flutter-test.txt`에 보관한다. `week7_test.dart`에서는 기존 JSON·가입·Dialog 검증을 유지하고, v6 memberId 평점/학습용 세션 검증은 새 v7 계약 테스트로 교체했다. `week8_test.dart`가 인증·보안 저장소 추상화·인터셉터·프로필·세션 평점·Router 검증을 담당한다.

주요 검증:

- 신규 로그인은 토큰 저장 뒤 signedIn, 탭 호스트가 GET me 호출. 복원은 GET me 완료 전 initializing.
- 네트워크·저장소 읽기 실패는 retryRequired, 토큰 자동 삭제 없음.
- 로그인 AUTH401_1과 보호 AUTH401_2/3/4 구분. 만료는 한 번 정리하고 한 번 안내.
- 승인된 origin·method·path만 Bearer 부착. 외부 host/다른 port/다른 scheme/공개 경로에는 미부착. 보호 요청 redirect 자동 추적 비활성.
- 로그아웃 중 진행 중인 write 완료 뒤 delete. 삭제 실패는 재시도 상태로 표시. 오래된 실제 401이 새 계정을 지우지 않음.
- 프로필 입력 길이, 현재 닉네임 유지 시 PATCH 생략, 중복·네트워크 실패 시 입력 유지, 성공 member 교체.
- 이전 GET me가 늦게 도착해 수정한 닉네임을 되돌리지 않음.
- 평점 등록/수정 result 객체 파싱, DELETE 200 wrapper, 공개 조회는 직접 배열과 무토큰.
- 현재 세션 Rating만 갱신·삭제. 로그아웃·회원 전환·늦은 쓰기 응답에서 다른 회원으로 데이터가 섞이지 않음.
- 실제 로그인 Form → Router → GET me → 마이페이지와 프로필 수정 경로. 보호 화면 redirect와 만료 Snackbar.
- 320/360 작은 화면에서 별 5개 선택과 키보드 입력. 403 시 Dialog 입력 유지·Snackbar, 로그인 유지.
- SecureTokenStorage의 write/read/delete 메서드 채널 호출 계약.

테스트는 메모리 API adapter, MemoryStorage 및 Flutter 플러그인 mock으로 실행한다. 실제 계정이나 실제 JWT를 사용하지 않았다. 테스트의 불투명 토큰 문자열은 JWT claim을 파싱하지 않음을 확인하기 위한 fixture이다.

## 미검증 및 API 제한

- Android 에뮬레이터/실기기가 연결되지 않아 **Android Keystore에서 실제 write/read/delete 및 프로세스 재시작을 통한 복원은 미검증**이다. 메서드 채널 mock 통과를 OS 검증으로 표현하지 않는다.
- iOS Keychain entitlement를 추가했지만 Xcode 서명·실행 및 iOS 보안 저장 동작은 미검증이다. iOS 재설치 감지 심화 기능도 구현하지 않았다.
- 이 clone의 `.env`는 로컬 검증용 빈 TMDB 설정이다. 사용자의 기존 PC `.env`는 그대로 유지해야 한다. 실제 토큰으로 영화 API 조회·서버 JWT 로그인·닉네임/평점 저장 화면을 촬영하지 않았다.
- 토큰 만료·403·409의 실제 서버 증거 및 Android 영상은 `WEEK8_MANUAL_CHECK.md` 순서로 확인해야 한다. 자동 테스트의 가상 응답 증거와 구분한다.
- v7 로그인/GET me에는 memberId가 없고 토큰 기반 내 평점 전체 조회가 없다. JWT claim 추정이나 임의 회원 조회 없이 현재 세션 생성 Rating만 관리한다. 앱 재시작 뒤 이전 내 평점 목록이 비어 있는 동작을 문서화했다.
- 선택 Challenge인 이메일 저장·가입일 표시·편집 내용 뒤로가기 확인은 범위에 포함하지 않았다. 내 정보 재시도 UI는 Guided/Required 복구를 위해 제공한다.

사용자가 새 브랜치 게시를 승인하여 feature/week-8로 커밋·게시한다. PR 생성이나 main 병합은 이번 요청 범위에 포함하지 않는다.
