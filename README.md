# AppStudio — 4개 실용 Android 앱

## 최신 경량 Release APK 검증 — 2026-11-14

- Windows runner [빌드 #17](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43607982171) **SUCCESS** (커밋 `bfc9d3de`)
- [최신 APK 4종 다운로드 — `appstudio-release-arm64-17`](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43607982171/artifacts/14119042321)
- 난독화된 앱 크래시 추적용 [별도 심볼 Artifact](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43607982171/artifacts/14119322037)
- **빌드당 Debug APK는 생성하지 않음**. Release 모드, ARM64 전용, Android R8 코드/리소스 축소, Dart AOT 심볼 외부 분리, APK 서명 검사 통과

| 앱 | 과거 Debug | 경량 ARM64 Release | 감소율 |
|---|---:|---:|---:|
| 모자이크 가드 | 200.02 MiB | **71.96 MiB** | **64.0%** |
| 픽셀 슬림 | 143.64 MiB | **15.71 MiB** | **89.1%** |
| 도큐 스냅 | 175.23 MiB | **46.88 MiB** | **73.2%** |
| 근무페이 | 140.56 MiB | **15.71 MiB** | **88.8%** |

이 표는 **APK 파일 크기**입니다. 설치 후 기기 저장 공간 크기와 다를 수 있습니다. ZIP Artifact 자체는 76,362,943바이트(약 72.8 MiB)입니다. ML Kit 얼굴/한국어 문자 인식 기능을 유지하므로 모자이크 가드·도큐 스냅은 상대적으로 큽니다.

**서명:** APK는 Release 모드로 빌드했지만 Flutter 생성 Android 호스트의 **테스트용(debug) 서명키**를 사용합니다. APK 서명 검증은 통과했으며 직접 설치용 테스트에 쓸 수 있습니다. **Play Store 제출용 서명된 AAB는 아닙니다.** 32비트 전용 Android 기기나 x86 에뮬레이터는 지원하지 않습니다.


CoStock 및 유익창고 블로그와 독립적으로 운영하는 Flutter 모노레포입니다.

## 활성 앱 (자동 빌드 대상)

| 앱 | Flutter 경로 | 제공 기능 |
|---|---|---|
| 픽셀 슬림 | `apps/pixel_slim` | 사진·영상 압축, 일괄 처리, 공유 |
| 도큐 스냅 | `apps/docu_snap` | 카메라·갤러리 스캔, PDF 생성·공유, OCR |
| **모자이크 가드** | `apps/privacy_mosaic` | 손가락 영역 선택, 얼굴/문자 후보 자동 감지, 모자이크·흐림·검정 가림, 새 JPEG 공유·위치 메타데이터 제거 |
| **근무페이** | `apps/shift_pay` | 월별 근무 달력, 출퇴근·익일퇴근·휴게, 시급 및 옵션 가산 추정, 기록 저장·수정·삭제, CSV 내보내기 |

## 기존 게임 앱 보존

- `apps/pulse_puzzle` (펄스 퍼즐)
- `apps/daily_quiz` (데일리 퀴즈)

두 폴더와 코드·문제은행·아이콘·테스트는 **삭제하지 않았습니다**. 단, 자동 APK 일괄 빌드 및 자동 push/PR CI에서는 제외했고, GitHub Actions 수동 실행은 유지합니다.

## 로컬 빌드

`main` 변경 시 **전용 Windows 러너 `AppStudio-Win11`**가 `scripts/windows/build-apps.ps1`로 활성 4개 앱을 빌드하고 GitHub Actions Artifacts에 ZIP으로 올립니다. 구형 게임 APK는 포함되지 않습니다.

```powershell
git clone https://github.com/OHOHOHTAEJIN/AppStudio.git D:\AppStudio
cd D:\AppStudio
.\scripts\bootstrap.ps1 -App all
```

기본 산출물은 **ARM64 전용 최적화 Release APK**입니다. Flutter AOT, Android R8·리소스 축소, 아이콘 트리셰이킹, 난독화·심볼 분리를 적용하고 Debug APK 자동 빌드는 중단했습니다.

Flutter 생성 Android 템플릿은 Release 모드에 **테스트용(debug) 서명키**를 사용합니다. APK는 실기기 설치·테스트용이며 Play Store 출시에는 앱별 업로드 키와 서명된 AAB가 별도로 필요합니다. ARM64 전용이므로 32비트 단독 기기나 x86 에뮬레이터에는 설치할 수 없습니다.

GitHub Actions에 `appstudio-release-arm64-N`(APK 4개 + 크기 비교 CSV), `appstudio-android-symbols-N`(스택 추적용 심볼)을 분리해 업로드합니다. AdMob/UMP 및 실기기 검증은 별도 작업입니다.

## 개인정보·급여 안내

모자이크 가드는 **기기에서 이미지 처리**하며 자동 얼굴/문자 감지 누락 가능성이 있으므로 저장 전 결과를 확인해야 합니다. 이미지 출력은 원본 EXIF·GPS를 복사하지 않는 새 JPEG이며 원본 사진은 변경하지 않습니다.

근무페이는 **2026년 시간급 10,320원**을 초기값으로 사용하나 사용자가 수정할 수 있습니다. 법적 수당·주휴수당·4대보험·세금은 근로계약/요건에 따라 달라지므로 **급여명세서 대체용이 아닙니다**. 휴게시간은 야간 근무에 비례 배분하는 근사 방식입니다. <https://www.moel.go.kr/news/enews/report/enewsView.do?news_seq=18144>

관련 문서: [기능 현황](docs/FEATURE_STATUS.md), [출시 준비](docs/RELEASE_CHECKLIST.md).

## 과거 Debug 빌드 검증 (보관용) — 2026-11-14

- 최종 소스: `124b9b52519306dbb07bc86e5a893e1f0caba289` (PR #11 병합)
- 각 앱 Flutter analyze 및 widget/unit tests: **4/4 통과**
- 집 Windows 러너 실제 디버그 APK 빌드: **4/4 통과**
- 검증된 AppStudio Actions: [빌드 #13](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43604570467) — **success**
- Android APK ZIP: [appstudio-debug-apks-13](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43604570467/artifacts/14118297030)
- ZIP 내용: `pixel_slim-debug.apk`, `docu_snap-debug.apk`, `privacy_mosaic-debug.apk`, `shift_pay-debug.apk`
- ZIP 약 341 MB, 21일 보관; debug APK이므로 Play Store 제출용 서명 AAB는 아님

**제약:** Flutter 테스트/Android 빌드 성공과 실기기의 ML Kit 얼굴·문자 인식, 파일 공유, 화면 터치 동작은 별도 검증입니다. 실사용 전 [신규 앱 QA](docs/QA_NEW_APPS.md)를 확인하세요.

## 경량화 빌드 (2026-11-14)
- `flutter build apk --release --target-platform=android-arm64 --obfuscate --split-debug-info=<symbols> --tree-shake-icons`
- R8 Java/Kotlin 코드 및 미사용 Android 리소스 축소
- 4개 앱별 용량과 기존 디버그 대비 감소율은 `size-report.csv`에 자동 기록
- 최신 Windows 빌드 성공 후 확정한 APK 크기를 사용해야 합니다. #13은 이전 Debug 비교 기준입니다.
