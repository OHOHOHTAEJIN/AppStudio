# AppStudio Android app launcher icons

4 original designed icons are sourced from this repository:

- `apps/pulse_puzzle/assets/icon/launcher.jpg` (purple neon numeric puzzle)
- `apps/pixel_slim/assets/icon/launcher.jpg` (turquoise media compression)
- `apps/docu_snap/assets/icon/launcher.jpg` (orange scanner/PDF)
- `apps/daily_quiz/assets/icon/launcher.jpg` (pink quiz brain)

Each Flutter app declares `flutter_launcher_icons: ^0.14.4` in dev_dependencies
and has its own adaptive launcher configuration in pubspec.yaml.

Important: Android host directories are generated using `flutter create` on
every CI run. Run `flutter pub get` and `dart run flutter_launcher_icons` **after**
that generation and **before** `flutter build apk`. The dedicated Windows
build and the four per-app Linux workflows both do this automatically.

The icon source is an Android-launcher-sized derivative of the original
concept art, stored in Git. No global Windows runner settings or blog runner
are modified.

Verification: the Windows runner checks `mipmap-xxxhdpi/ic_launcher.png` after
generation and the GitHub Actions job must successfully build four APKs.
Manual device launcher and adaptive icon appearance should still be inspected
on Android 12+ and 13+ devices.


## 신규 실용 앱 아이콘
- `apps/privacy_mosaic/tool/generate_icon.dart`: 녹색 방패·모자이크 픽셀 아이콘
- `apps/shift_pay/tool/generate_icon.dart`: 파란 달력·급여 아이콘
- 신규 앱 아이콘은 각각 `dart run tool/generate_icon.dart <app_name>` 실행 후 `dart run flutter_launcher_icons`로 Android mipmap 리소스로 생성
- 빌드/CI는 순서를 자동 실행
