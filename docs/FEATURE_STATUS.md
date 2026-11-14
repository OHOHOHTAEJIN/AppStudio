# AppStudio 기능 현황 — 실용 앱 4종

## 현재 활성화
- 픽셀 슬림: 사진 20장 일괄 압축, 동영상 리인코딩, 진행률·공유 (기능별 실기기 QA 필요)
- 도큐 스냅: 다중 사진 PDF, OCR, 문서 흑백 보정, 페이지 정렬·공유 (기능별 실기기 QA 필요)
- 모자이크 가드: 직접 박스 선택, 얼굴·한국어 문자 자동 영역 감지, 모자이크·흐림·검정 가림, 새 JPG 공유. 자동 감지는 누락이 있을 수 있음
- 근무페이: 근무 달력·이력, 시급, 익일 퇴근, 휴게시간, 선택적 일일 초과·야간 수당 추정, CSV, 로컬 저장

## 보존하는 비활성 앱
- 펄스 퍼즐 `apps/pulse_puzzle`
- 데일리 퀴즈 `apps/daily_quiz`

기존 코드는 보존하고, 자동 4종 빌드에서 제외함.

## 검증 원칙
- Flutter analyze, flutter test, Android APK 생성과 GitHub Artifact 업로드를 구분해 기록
- 실제 얼굴 인식·OCR·파일공유·갤러리·영상 압축은 Android 실기기 검증 필요
- 자동 얼굴/문자 감지는 완전한 익명화 보장을 의미하지 않음
- 급여 계산은 추정치. 주 40시간 초과 수당, 주휴/휴일수당 자동 판정, 공제·세금, 실제 휴게시간 배분 및 국가별 법령 자동 적용은 미구현
- AdMob·UMP, 서명 AAB·Play Console, 폴더블·태블릿 실기기 검증은 미완료

## 이번 턴 검증 결과
- GitHub PR #11 main 병합 SHA `124b9b52`
- 신규 유틸리티 및 기존 유지 4개 앱 Flutter analyze/test 통과
- Windows runner APK 생성·수량 검증·Artifact 업로드 성공: [빌드 #13](https://github.com/OHOHOHTAEJIN/AppStudio/actions/runs/43604570467)
- 4개 APK: `privacy_mosaic`, `shift_pay`, `pixel_slim`, `docu_snap` (게임 2개 미포함)
- Android 실기기 기능 검증은 아직 수행되지 않음
