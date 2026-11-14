# AppStudio Windows 러너의 Android SDK 인식

## 확인된 빌드 실패 (2026-11-14)

- Windows 러너 `AppStudio-Win11`에서 Git 소스 체크아웃 성공
- Flutter 3.35.2가 정상 실행됨
- 펄스 퍼즐 Flutter 분석 및 위젯 테스트 성공
- `flutter build apk --debug` 중 `[!] No Android SDK found` 발생
- SDK를 찾지 못해 빌드 단계가 첫 앱에서 종료되었고 나머지 앱은 시도하지 않음

## 자동 탐색

`scripts/windows/detect-android-sdk.ps1`가 빌드 단계 전에 실행되어 다음 경로를 확인함.

- 러너 환경변수 `ANDROID_HOME`, `ANDROID_SDK_ROOT`
- `flutter config --list`에서 설정한 `android-sdk`
- `adb`가 PATH에 등록된 경우 그 설치 경로
- `C:\Users\*\AppData\Local\Android\Sdk` (Android Studio 기본 경로)
- `D:\Android\Sdk` 및 공통 SDK 경로

찾은 경로가 `platforms/android-36/android.jar`, `platform-tools/adb.exe`를 포함하면
**현재 빌드 작업 내에서만** `ANDROID_HOME`, `ANDROID_SDK_ROOT`를 지정함.
기존 유익창고 러너, Windows 시스템 환경변수, SDK 설치 내용은 변경하지 않음.

## 자동 탐색 실패 시 Windows PC에서 확인

관리자 권한 불필요. 사용자가 보통 사용하는 PowerShell에서:

```powershell
flutter doctor -v
Get-ChildItem Env:ANDROID_HOME,Env:ANDROID_SDK_ROOT -ErrorAction SilentlyContinue
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platforms\android-36\android.jar"
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```

- SDK 자체가 없으면 Android Studio의 SDK Manager에서 플랫폼 36, platform-tools 설치.
- SDK가 다른 드라이브에 있으면 **AppStudio 전용 서비스 계정**에 SDK 경로를
  인식시키는 구성이 필요하며, 기존 블로그 서비스를 변경해서는 안 됨.
- 로그가 API 36 누락 또는 platform-tools 누락으로 바뀌면 해당 구성요소만 설치.
