# Google Calendar OAuth 설정 가이드 (GUICULUM_FLUTTER)

## 0) 현재 앱 식별자
- Android applicationId: `com.example.guiculum_flutter`
- iOS bundle id: Xcode의 `Runner` target 값 사용 (`PRODUCT_BUNDLE_IDENTIFIER`)
- Web origin(개발): 보통 `http://localhost:<flutter-port>`

## 1) Google Cloud 프로젝트
1. Google Cloud Console에서 프로젝트 생성/선택
2. APIs & Services > Library > **Google Calendar API** 활성화

## 2) OAuth Consent Screen
1. APIs & Services > OAuth consent screen
2. 앱 이름/이메일 입력
3. Scope 추가
   - `.../auth/calendar.readonly`
4. 테스트 모드면 Test users에 본인 구글 계정 추가

## 3) OAuth Client 생성

### A. Web Client
- Credentials > Create Credentials > OAuth client ID > Web application
- Authorized JavaScript origins 예시:
  - `http://localhost:53001`
  - `http://localhost:3000`
- 생성 후 Client ID를 `.env`의 `GOOGLE_CLIENT_ID`에 넣기
- (선택) Server client id는 `GOOGLE_SERVER_CLIENT_ID`

### B. Android Client
- OAuth client ID > Android
- Package name: `com.example.guiculum_flutter`
- SHA-1 추가

SHA-1 확인 명령(디버그):
```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```

### C. iOS Client
- OAuth client ID > iOS
- Bundle ID를 Runner 번들아이디와 동일하게 입력
- 생성된 `REVERSED_CLIENT_ID`를 iOS URL Scheme에 추가

`ios/Runner/Info.plist`에 아래 블록 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

## 4) Flutter 반영
- `.env` 파일:
```env
GOOGLE_CLIENT_ID=your-web-or-ios-client-id.apps.googleusercontent.com
GOOGLE_SERVER_CLIENT_ID=your-web-server-client-id.apps.googleusercontent.com
```

- 앱 실행 전 `.env` 로드 확인

## 5) 동작 확인
1. 앱 `/ops` 진입
2. `캘린더 연동 (Google)`의 `연결` 클릭
3. 로그인 성공 후 `다가오는 일정` 목록이 보이면 완료

## 6) 트러블슈팅
- `redirect_uri_mismatch`: OAuth client의 redirect/origin 불일치
- `access_blocked`: consent screen 테스트유저 미등록
- Android 실패: SHA-1 누락/오타
- iOS 실패: URL Scheme 미등록
