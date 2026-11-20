# MovieLog · Flutter 8주차

`feature/week-7`의 `bfacc84`를 바탕으로 8주차 Required 미션을 구현했습니다. v7 로그인, 보안 토큰 저장·복원, 내 정보 조회·닉네임 수정, 토큰 기반 평점 등록·수정·삭제, 로그아웃과 보호 경로 redirect를 연결합니다.

## 로컬에서 실행

검증 SDK는 Flutter 3.47.9 / Dart 3.13.7입니다. Android Studio 또는 VS Code에서 `pubspec.yaml`이 있는 루트 폴더를 엽니다.

```sh
git fetch origin
git switch --track origin/feature/week-8
flutter pub get
flutter devices
flutter run -d <Android_기기_ID>
```

이미 같은 로컬 브랜치가 있으면 `git switch feature/week-8` 후 `git pull --ff-only origin feature/week-8`을 사용합니다. 브랜치 전환 전에 작업 중인 변경은 먼저 커밋하거나 백업합니다.

**기존 PC의 `.env`를 그대로 유지하세요.** 새로 clone했다면 `.env.example`을 `.env`로 복사하고 `TMDB_ACCESS_TOKEN`을 로컬에서 설정합니다. 토큰 값은 Git에 올리지 않습니다.

이번 변경은 `flutter_secure_storage` 네이티브 플러그인을 추가하므로 기존 실행을 종료하고 다시 `flutter run`해야 합니다. Hot Reload만으로 플러그인 설치가 완료되지 않습니다. Android SDK Manager에서 Platform 35/36, Build-Tools 36, NDK 28.2.13676358, CMake 3.22.1을 준비하면 네이티브 의존성 빌드에 도움이 됩니다. 라이선스 오류가 나면 `flutter doctor --android-licenses`를 실행합니다.

## 앱에서 확인할 순서

1. 스플래시에서 저장 토큰 확인 → 토큰이 없으면 로그인 화면.
2. 회원가입 또는 기존 학습용 계정으로 로그인 → 홈 진입 → GET me로 내 정보 로드.
3. 마이 탭에서 서버의 닉네임·이메일 확인 → 프로필 수정 → 2~12자 닉네임 저장.
4. 영화 탭 → TMDB 영화 선택 → 정수 별점·코멘트 등록.
5. 마이 → **이번 로그인에서 등록한 평점** → 카드별 수정·삭제.
6. 앱 재시작 → secure storage의 토큰 읽기 → GET me 검증 성공 뒤 홈.
7. 마이 앱바의 로그아웃 → 토큰·member·현재 세션 평점 제거 → 로그인 화면.

로그인/회원가입은 `https://workbook.devnoco.com`의 **v7** 서버를 사용합니다. 별도로 만든 로컬 Spring 서버의 계정과 혼동하지 마세요. API 서버를 개발용으로 변경하려면 `MOVIELOG_BASE_URL` dart-define을 사용하며, 보호용 Client는 그 origin과 승인된 v7 path·method에만 JWT를 붙입니다. TMDB는 항상 별도 Client를 사용합니다.

## API 계약상 제한

v7 로그인과 GET me에는 memberId가 없으며, 토큰 기반 ‘내 평점 전체 조회’ API도 없습니다. **JWT payload를 해석해 회원 ID를 추측하지 않습니다.** 등록 응답으로 받은 Rating만 현재 세션의 목록에 보관하고 PATCH/DELETE 결과로 갱신합니다. 앱 재시작·로그아웃·계정 전환 시 이 목록은 비워지지만 서버에 저장한 평점이 삭제되는 것은 아닙니다.

공개 `GET /v7/members/{memberId}/ratings`는 Service에 유지했습니다. 본인 ID를 모르는 상태에서 임의 번호로 호출하거나 내 전체 평점을 복원한 것처럼 표시하지 않습니다. `RATING404_1`이면 없어진 해당 세션 카드만 제거해 현재 표시를 갱신합니다.

## 검증 및 워크북

```sh
flutter analyze
flutter test --reporter expanded
```

- [Required 항목별 구현·워크북 작성 가이드](docs/WEEK8_WORKBOOK.md)
- [Android 실행·보안 저장소·촬영 체크리스트](docs/WEEK8_MANUAL_CHECK.md)
- [검증 결과와 미검증 범위](docs/WEEK8_VALIDATION.md)

이메일 저장, 변경 전 뒤로가기 확인, iOS 재설치 감지 같은 Challenge/심화 기능은 포함하지 않았습니다. 과거 `docs/WEEK7_*` 문서는 이전 주차 기록이며 현재 v7 앱 계약은 위 8주차 문서를 따릅니다.
