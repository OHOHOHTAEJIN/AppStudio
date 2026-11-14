# AppStudio — 4개 실용 Android 앱

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

APK는 디버그 설치용입니다. Play Store용 AAB/서명/AdMob/UMP 및 실제 기기 검증은 별도 작업입니다.

## 개인정보·급여 안내

모자이크 가드는 **기기에서 이미지 처리**하며 자동 얼굴/문자 감지 누락 가능성이 있으므로 저장 전 결과를 확인해야 합니다. 이미지 출력은 원본 EXIF·GPS를 복사하지 않는 새 JPEG이며 원본 사진은 변경하지 않습니다.

근무페이는 **2026년 시간급 10,320원**을 초기값으로 사용하나 사용자가 수정할 수 있습니다. 법적 수당·주휴수당·4대보험·세금은 근로계약/요건에 따라 달라지므로 **급여명세서 대체용이 아닙니다**. 휴게시간은 야간 근무에 비례 배분하는 근사 방식입니다. <https://www.moel.go.kr/news/enews/report/enewsView.do?news_seq=18144>

관련 문서: [기능 현황](docs/FEATURE_STATUS.md), [출시 준비](docs/RELEASE_CHECKLIST.md).
