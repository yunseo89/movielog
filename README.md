# MovieLog · Flutter 7주차

`feature/week-6`의 `d6b2b8d`를 기반으로 v6 회원가입과 평점 등록·조회·수정·삭제를 구현했습니다. 기존 Flutter 화면과 Navigator 구조를 유지합니다.

## VS Code / Android Studio에서 실행

1. Flutter stable을 설치합니다. 검증 환경: Flutter **3.47.9**, Dart **3.13.7**. 프로젝트 요구사항은 Dart `^3.13.3`입니다.
2. Android Studio의 SDK Manager에서 Android SDK Platform 36, Build-Tools 36, Platform-Tools를 설치하고 Device Manager에서 에뮬레이터를 시작합니다. Flutter·Dart 플러그인도 설치합니다. Android 빌드는 JDK 21 사용을 권장합니다.
3. 이 폴더를 IDE에서 엽니다. `android/`만 열지 말고 `pubspec.yaml`이 있는 프로젝트 루트를 엽니다.
4. **기존 `.env`가 있으면 그대로 유지합니다.** 없는 경우에만 `.env.example`을 `.env`로 복사하고 다음 값을 로컬에서 채웁니다.

   ```dotenv
   TMDB_ACCESS_TOKEN=본인의_TMDB_API_Read_Access_Token
   ```

   TMDB 설정 → API → **API Read Access Token**을 사용합니다. API Key와 구분합니다. 토큰·`.env`는 커밋하지 않습니다.

5. 루트 터미널에서 실행합니다.

   ```sh
   flutter pub get
   flutter doctor -v
   flutter devices
   flutter run -d <Android_기기_ID>
   ```

   VS Code에서는 오른쪽 아래 기기를 선택하고 F5 (`MovieLog · Week 7`), Android Studio에서는 `lib/main.dart`와 Android 기기를 선택하고 ▶ Run을 누릅니다. `.env` 변경 후에는 앱을 종료하고 다시 실행합니다.

6. 시작하기 → 회원가입 → 닉네임·이메일 중복 확인 → 약관 동의 → 가입하기 → 영화 탭 → 영화 상세 → 평점 남기기 → 마이 탭 → 내가 등록한 평점 순서로 확인합니다.

회원가입 성공 Snackbar와 마이페이지 진입 행에 **실제 result.memberId**가 표시됩니다. 학습용 세션은 메모리에만 있으므로 hot restart/앱 재실행 시 사라집니다. JWT 로그인이나 기존 회원 로그인은 이번 주차 범위가 아닙니다. 본인이 새로 만든 학습용 계정만 사용합니다.

## GitHub의 7주차 코드를 기존 PC로 가져오기

기존 프로젝트 루트에서 작업 중인 변경을 먼저 커밋하거나 백업한 후 실행합니다. `.env`는 Git에서 제외되어 있으므로 기존 값을 유지합니다.

```sh
git fetch origin
git switch --track origin/feature/week-7
flutter pub get
flutter devices
flutter run -d <Android_기기_ID>
```

이미 로컬에 같은 브랜치가 있으면 `git switch feature/week-7` 후 `git pull --ff-only origin feature/week-7`을 실행합니다. VS Code와 Android Studio에서 같은 프로젝트 폴더를 열면 전환된 소스가 보입니다. PR 병합 전에도 브랜치를 가져와 실행할 수 있습니다.

## 검증

```sh
flutter analyze
flutter test
flutter build apk --debug
```

- [워크북 작성 가이드 및 필수미션 대응](docs/WEEK7_WORKBOOK.md)
- [Android 수동 검증·촬영 순서](docs/WEEK7_MANUAL_CHECK.md)
- [검증 결과와 미검증 범위](docs/WEEK7_VALIDATION.md)

API: `https://workbook.devnoco.com/docs`의 **v6** 명세. 워크북의 주차 번호와 Swagger 화면의 주차 표기가 다르더라도 이번 구현은 `/v6` 계약을 따릅니다. TMDB 요청에는 TMDB 전용 Client만 토큰을 붙입니다. MovieLog Client에는 인증 헤더와 비밀번호 로깅 인터셉터를 추가하지 않았습니다.

Challenge의 다중 선택 삭제는 포함하지 않았습니다. 필수미션의 카드별 수정·삭제를 구현했습니다.
