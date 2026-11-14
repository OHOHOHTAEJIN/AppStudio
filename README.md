# AppStudio — Android 4 App Monorepo

CoStock와 유익창고 프로젝트와 완전히 독립된 신규 Flutter 안드로이드 앱 개발 저장소입니다.

| 앱 | 코드 | 첫 버전 목표 | 후속 작업 |
|---|---|---|---|
| 펄스 퍼즐 | [pulse_puzzle](apps/pulse_puzzle) | 60초 숫자 찾기, 최고 점수 | 게임 모드·AdMob |
| 픽셀 슬림 | [pixel_slim](apps/pixel_slim) | 사진 선택·압축·공유 | 실제 동영상 재인코딩 |
| 도큐 스냅 | [docu_snap](apps/docu_snap) | 사진 촬영/선택 → PDF 공유 | OCR·문서 보정 |
| 데일리 퀴즈 | [daily_quiz](apps/daily_quiz) | 날짜별 상식 10문제, 기록 | 문제은행·다국어 |

## 구조

- `apps/`: 별도 Flutter 진입점, 의존성, 테스트 및 Android 앱 패키지
- `packages/app_core/`: 공통 테마·반응형 화면·카드·통계 그리드
- `.github/workflows/`: 앱별 독립 CI. 변경된 앱과 공통 패키지에 해당하는 CI만 실행
- `scripts/`: Android 호스트 생성, Android API 설정 및 일괄 검사
- `docs/`: 개발 현황·작업 정책·출시 검증 체크리스트

## 로컬 준비

Windows 11 + Flutter 3.35.2 + Android SDK Platform 36 + Java 17 + Python 3.

```powershell
git clone https://github.com/OHOHOHTAEJIN/AppStudio.git D:\AppStudio
cd D:\AppStudio
.\scripts\bootstrap.ps1 -App all
cd .\apps\pulse_puzzle
flutter run
```

CI는 Flutter Analyze/Test를 실행하고, Actions에서 수동 실행할 때만 디버그 APK를 생성합니다. **Play Store 배포용 AAB 서명/업로드는 구성되지 않았습니다.**

## 운영 원칙

- `main` 브랜치는 PR+CI 통과 후 변경
- `feature/puzzle-<issue>`, `feature/optimizer-<issue>` 등 앱별 브랜치
- `app:puzzle`, `app:optimizer`, `app:documents`, `app:quiz`, `shared`로 이슈 관리
- 각 앱은 Play Console 패키지명, 스토어 등록, AdMob ID 및 버전 별도 관리
- 실기기, Z Fold/Flip, 태블릿, 접근성 글꼴 확대 테스트 추가 필요

**현재 상태**: 개발 초기 MVP 소스 작성. 실제 Android 빌드·에뮬레이터 테스트·실광고·AAB 배포 검증 전입니다.
