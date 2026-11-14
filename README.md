# AppStudio — 4개 독립 안드로이드 앱 (Flutter)

CoStock 및 유익창고 블로그와 **완전히 분리**해 운영하는 4개 앱의 공통 저장소입니다.
각 앱은 독립된 패키지·테스트·런처 아이콘·버전을 갖고, 공통 UI 컴포넌트만 `packages/app_core`에서 공유합니다.

## 앱별 기능 — v0.2.0+2

| 앱 | 현재 구현 기능 | 남은 핵심 과제 |
|---|---|---|
| [펄스 퍼즐](apps/pulse_puzzle) | 30초·60초·20단계, 난이도 3단계, 콤보·점수·일시정지·최고 기록 | 게임 업적·보상, 광고 및 실제 플레이 품질 검증 |
| [픽셀 슬림](apps/pixel_slim) | 최대 20장 사진 압축·용량 비교·공유, 동영상 480p/720p/1080p 압축·진행률·취소 | 실제 여러 제조사 휴대폰의 영상 코덱·압축 품질 검증 |
| [도큐 스냅](apps/docu_snap) | 사진 촬영·순서 변경, 흑백 스캔 보정, PDF 생성·공유, 한국어·영어 OCR 및 복사 | 문서 모서리 감지·원근 보정, 기존 PDF 병합, 문서 보관함 |
| [데일리 퀴즈](apps/daily_quiz) | 날짜별 퀴즈·분야별 연습, 90문제, 정답 해설, 최고 기록·연속 참여 | 문제은행 확대·문항 검수·다국어·랭킹 |

공통 UI는 컴팩트한 그라데이션 헤더·카드·반응형 레이아웃과 4개 앱별 컬러 테마를 사용합니다.

## GitHub와 Windows PC 빌드

- `main` 변경 시 각 앱에 맞는 Flutter Analyze·Widget Tests를 GitHub Actions로 검사합니다.
- Android APK는 **Windows 11의 AppStudio 전용 self-hosted runner** (`AppStudio-Win11`, `appstudio-android`)에서만 빌드합니다.
- 러너는 정확한 Git 커밋을 체크아웃하고 Android API36 설정·앱 아이콘 생성 후 4개 APK를 순서대로 빌드합니다.
- 완료된 APK는 GitHub Actions **Artifacts**에 ZIP으로 업로드합니다. 소스 브랜치에 대형 APK를 커밋하지 않습니다.
- 기존 유익창고 러너 `D:\gh-runner`와 AppStudio 러너 `D:\gh-runner-appstudio`는 서로 다른 Windows 서비스입니다.

### 최신 확인된 정상 빌드

- 소스: `bc7a969` (v0.2.0 기능·UX 개선, PR #10)
- Windows 빌드: [GitHub Actions #12](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43599442490) — **성공**
- APK: [`appstudio-debug-apks-12`](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43599442490/artifacts/14115732079) (4개 앱 디버그 APK)
- GitHub Actions artifact는 21일 동안 보관한 후 만료됩니다. Release 또는 Play Store 앱 배포와는 다릅니다.

## 개발 시 주의할 사항

```powershell
git clone https://github.com/OHOHOHTAEJIN/AppStudio.git D:\AppStudio
cd D:\AppStudio
.\scripts\bootstrap.ps1 -App all
```

- Android 호스트 폴더는 `flutter create`로 생성되므로, 앱별 `pubspec.yaml` 런처 설정과 `scripts/windows/patch-android.ps1`의 모델 의존성을 적용한 다음 빌드해야 합니다.
- Pixel Slim은 `video_compress_next`, Docu Snap은 `google_mlkit_text_recognition`을 사용합니다.
- **Flutter 분석·위젯 테스트·APK 빌드 성공은 실제 기기에서 모든 버튼·OCR 정확도·동영상 압축을 검증했다는 뜻이 아닙니다.**
- AdMob·UMP 동의·개인정보 처리·서명된 AAB·Play Store 등록 및 실제 폴더블/태블릿 검증은 별도로 필요합니다.

관련 문서: [기능 상태](docs/FEATURE_STATUS.md) · [로드맵](docs/ROADMAP.md) · [출시 체크리스트](docs/RELEASE_CHECKLIST.md)
