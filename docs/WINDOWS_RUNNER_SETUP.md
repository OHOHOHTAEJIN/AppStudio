# AppStudio 전용 Windows 11 GitHub Runner 추가

이 문서는 **기존 유익창고 러너 D:\gh-runner 는 유지**하고,
AppStudio 전용 러너를 **D:\gh-runner-appstudio**에 추가하는 절차입니다.

## 1. GitHub UI에서 신규 러너 발급

1. https://github.com/OHOHOHTAEJIN/AppStudio/settings/actions/runners
2. New self-hosted runner → Windows → x64
3. **관리자 권한** Windows PowerShell 실행
4. `New-Item -ItemType Directory -Force D:\gh-runner-appstudio`
5. `cd D:\gh-runner-appstudio`
6. UI가 안내하는 최신 zip 다운로드 및 압축 해제 명령을 **이 폴더에서만** 실행
7. GitHub가 제공한 **시간 제한 등록 토큰**으로 등록:

```powershell
.\config.cmd --url https://github.com/OHOHOHTAEJIN/AppStudio `
  --token "<등록화면에서 발급받은 토큰>" `
  --name "AppStudio-Win11" `
  --labels "appstudio-android" `
  --work "_work" `
  --runasservice
```

등록 토큰은 GitHub/문서/대화에 남기지 마세요. 서비스 계정은 Flutter 및
Android SDK와 해당 작업 폴더에 접근 가능해야 합니다.

## 2. 기존 러너 보호

- 유익창고 기존 폴더 `D:\gh-runner`를 **절대 재설정하지 마세요**.
- AppStudio 신규 폴더 `D:\gh-runner-appstudio` 사용
- 러너 이름 `AppStudio-Win11`, 레이블 `appstudio-android`
- 신규 저장소에만 연결된 **repository-scoped** runner
- Windows 서비스도 독립 등록. 사용 중인 기존 러너는 유지.
- `Get-Service 'actions.runner.*' | Format-Table Name,Status,StartType -AutoSize`
- GitHub AppStudio Settings → Actions → Runners에서 Idle 확인
- **공통 CPU/RAM/SSD는 공유됨**. 동시 실행 시 성능 저하는 생길 수 있음

## 3. SDK 확인

AppStudio Windows 서비스가 실행되는 계정에서 아래 도구가 접근되어야 합니다.

```powershell
flutter --version
flutter doctor -v
java -version
Get-Command flutter, java
```

Flutter 3.35.2 / Android SDK Platform 36 / Android SDK build tools / Java 17 권장.
SDK가 사용자별 프로필에만 설치되었다면 Windows 서비스 계정이 경로를 못 볼 수
있습니다. 서비스 계정 또는 시스템 환경 변수 PATH, ANDROID_HOME,
ANDROID_SDK_ROOT 등을 확인하고 **AppStudio 서비스만 재시작**하세요.

## 4. 자동 실행 동작

소스 `main` push → AppStudio 전용 runner가 정확한 commit checkout(=Git fetch/pull) →
`scripts/windows/build-apps.ps1`에서 4개 Flutter 앱 순차 테스트 및 APK 빌드 →
GitHub Actions Artifacts에 zip 형식으로 자동 업로드.

- 소스 저장소 브랜치에 APK 파일을 commit/push하지 않습니다.
- GitHub Actions의 **Actions > Run > Artifacts**에서 APK 다운로드 가능
- Actions 수동 실행(`workflow_dispatch`)의 `app`에서 1개 또는 전체 선택 가능
- `publish_release=true`를 수동 선택하면 **테스트 APK만** GitHub Releases의
  **prerelease**로 추가 업로드. Play Store용 서명된 AAB와는 별개입니다.
- 저장소가 Public이므로, Self-hosted runner가 임의 PR 코드를 실행하지 않도록
  Android Windows workflow는 `push(main)` 및 `workflow_dispatch`만 사용.
- Runner 서비스에 개인 키·증권 계정·브라우저 프로필 등 불필요한 권한을 주지 않습니다.
- 실제 Play Store 출시에는 앱별 고유 applicationId, Play signing, release AAB,
  AdMob/동의 관리 및 정책 검증이 필요합니다.

## 5. 문제 해결

- workflow가 queued: 레이블 `appstudio-android`, Windows/X64 일치 여부,
  서비스 상태 및 Online/Idle 여부 확인
- flutter not found: **서비스 계정 PATH** 확인, 새 서비스만 재시작
- Python은 로컬 Windows 빌드에 필요하지 않음(플랫폼 패치는 PowerShell 스크립트)
- SDK/Gradle 실패: `flutter doctor -v` 및 Android SDK Platform 36 확인
- 문서/이미지 접근 실패: 신규 서비스 계정과 폴더 ACL 확인
- 두 러너 중 하나를 정지할 때 `Stop-Service 'actions.runner.*'`처럼
  와일드카드 전체를 중지하지 마세요. 정확한 서비스 이름으로 조작하세요.
