# 앱별 Play Store 출시 점검표

- [ ] 독립적이고 최종 확정한 applicationId
- [ ] 컴파일·단위·위젯 테스트 성공
- [ ] Android 16/API 36 기준 검토 및 기기 호환
- [ ] 320dp/일반 휴대폰/폴더블/태블릿/가로모드 반응형 검증
- [ ] 접근성 큰 글꼴·스크린리더 점검
- [ ] 권한 최소화, 개인정보처리방침 및 데이터 보안 신고
- [ ] AdMob 테스트 ID와 UMP/동의 흐름 검증 후 실계정 적용
- [ ] 광고 정책 위반 여부 확인, 게임 흐름 방해 광고 금지
- [ ] 앱별 업로드 키·서명된 release AAB (비밀키 커밋 금지)
- [ ] 아이콘·스크린샷·스토어 설명·연락처
- [ ] Play Console 요구사항에 따른 테스트와 정식 게시 심사
- [ ] 릴리스별 Crash/ANR 및 DAU/유지율/광고수익 추적

## Android 경량화
- [x] ARM64 Release APK 기본 생성, Debug APK 중단
- [x] AOT 난독화·심볼 외부 분리·아이콘 트리 셰이킹
- [x] R8 및 Android 리소스 축소
- [x] 과거 Debug 용량과 새 Release 크기 자동 비교
- [ ] Windows 최적화 Release 빌드 실제 성공 및 크기·서명 검증
- [ ] Play Store 서명된 AAB 및 기기별 전달 용량 확인
