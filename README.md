# Study Pilot Flutter App

Study Pilot은 **Flutter 단일 코드베이스**로 만든 학습 관리 앱이야.  
Web + iOS + Android를 함께 가져가면서, 학습 계획부터 실행, 검색, 개인화, 통계까지 한 흐름으로 묶는 걸 목표로 하고 있어.

---

## 현재 제품 방향
- **한국어 우선 UI**
- **blue glassmorphism + premium productivity** 톤
- **cloud / flight / route motif**
- 학습 흐름을 아래 순서로 연결
  - 가이드라인
  - 커리큘럼
  - 할일(Todo)
  - 캘린더
  - 검색 자료 연결
  - 통계 / 리마인드

---

## 핵심 기능

### 1. 학습 플로우 관리
- 가이드라인 생성
- 커리큘럼 생성
- Todo 생성 / 상태 변경
- 학습 캘린더 / Todo 캘린더 분리 운영
- 가이드라인 → 커리큘럼 → Todo 흐름 연결

### 2. 학습 탭 통합
- 하단 내비게이션의 **학습** 탭에서 가이드라인 / 커리큘럼 통합 관리
- 상단 **커리큘럼 선택 드롭다운**
- 그 아래 **가이드라인 / 커리큘럼 탭 2개**
- 선택한 커리큘럼 기준으로 관련 정보와 생성 폼을 함께 관리

### 3. 캘린더 기능
- 학습 캘린더
- Todo 캘린더
- 월 / 주 보기
- 선택 날짜 기준 요약
- 실행 상태 시각화
- 커리큘럼 기준 진행률 / 로드맵 요약

### 4. 검색 기능
- 검색
- 검색 상세 보기
- 관심 자료 저장
- 최근 검색어 저장
- 검색 자료를 커리큘럼 / Todo와 연결

### 5. 마이페이지 / 개인화
- 닉네임 저장
- 목표 직무
- 학습 스타일 메모
- 관심 분야
- 학습 방향 요약 카드

### 6. 홈 대시보드
- 실행 통계 카드
- 최근 7일 실행량
- 커리큘럼별 진척률
- 오늘 리마인드
- 온보딩 카드

### 7. 로그인 / 실행 환경
- 실제 Supabase 환경이 있으면 Supabase 기반 인증 사용
- 환경 변수가 placeholder인 경우 **데모 모드 로그인** 지원
- 관리자 빠른 시작 버튼 제공
- Flutter 플랫폼 러너(iOS / Android / web / macOS 등) 복구 완료

---

## 기술 스택
- Flutter / Dart
- `go_router`
- `supabase_flutter`
- `shared_preferences`
- `rxdart`
- `flutter_dotenv`

---

## 프로젝트 구조
```text
lib/
  core/
    app_router.dart
    app_shell.dart
    app_theme.dart
  features/
    home/
    login/
    planner/
    search/
  services/
```

### 주요 파일
- `lib/core/app_router.dart`
  - 전체 라우팅
- `lib/core/app_shell.dart`
  - 공통 레이아웃 / 하단 내비게이션
- `lib/features/home/home_page.dart`
  - 홈 대시보드 / 검색 진입 / 리마인드 / 통계
- `lib/features/planner/learning_page.dart`
  - 학습 탭 통합 화면
- `lib/features/planner/calendar_page.dart`
  - 학습 캘린더
- `lib/features/planner/todo_page.dart`
  - Todo 캘린더
- `lib/features/search/search_page.dart`
  - 검색 / 최근 검색어
- `lib/features/search/search_detail_page.dart`
  - 검색 상세 / 자료-학습 연결
- `lib/features/home/profile_page.dart`
  - 마이페이지 / 개인화 설정
- `lib/services/auth_service.dart`
  - 인증 / 데모 모드 로그인 처리
- `lib/services/planner_service.dart`
  - 가이드라인 / 커리큘럼 / Todo / 통계 집계
- `lib/services/search_service.dart`
  - 검색 / 북마크 / 최근 검색 / 자료 연결
- `lib/services/profile_service.dart`
  - 프로필 / 학습 설정 저장

---

## 현재 하단 내비게이션
현재 모바일 하단 내비게이션은 5개 구조야.

1. 홈
2. 학습
3. 캘린더
4. 할일
5. 마이

### 규칙
- 검색은 하단바에 두지 않고 **홈 상단 검색 진입**으로 처리
- 학습 탭은 **가이드라인 + 커리큘럼 통합 화면**

---

## 실행 방법
### 1. 의존성 설치
```bash
cd /Users/brian/.openclaw/workspace/studypilot-flutter-app
flutter pub get
```

### 2. 환경 변수 준비
```bash
cp -n .env.example .env
```

`.env`에 실제 Supabase 값을 넣으면 실데이터 모드로 동작하고,  
placeholder 상태면 데모 모드 로그인으로 진입 가능해.

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### 3. 실행
```bash
flutter run -d chrome
flutter run -d ios
flutter run -d android
```

### 4. 점검
```bash
flutter doctor -v
flutter devices
flutter analyze
flutter test
```

---

## 데모 모드 안내
실제 Supabase 프로젝트가 아직 연결되지 않은 환경에서도 화면/흐름 점검이 가능하도록 데모 모드를 넣어뒀어.

### 동작 방식
- `.env`가 placeholder 값이면 데모 모드 활성화
- 로그인 / 회원가입 / 관리자 빠른 시작이 로컬 세션 기반으로 동작
- UI 흐름 점검용으로 사용 가능

### 주의
- 데모 모드는 **실서비스 인증 대체가 아님**
- 실제 배포/운영 전에는 반드시 Supabase 실환경으로 검증해야 함

---

## 최근 반영된 주요 변경
- 학습 탭에서 가이드라인 / 커리큘럼 통합
- 홈 상단 검색 진입 추가
- 하단 내비게이션 5개 구조 정리
- 홈 메인 카드 반응형 보강
- 디버그 배너 제거
- 대시보드 통계 / 리마인드 추가
- 검색 자료를 커리큘럼 / Todo와 연결 가능하게 확장
- 개인화 설정(목표 직무 / 학습 스타일 / 관심 분야) 추가
- 플랫폼 러너 복구로 iOS 시뮬레이터 실행 가능 상태 복원

---

## 참고
- 이 README는 **민감 정보 없이 현재 제품 구조와 개발 상태만 정리**한 문서야.
- 실제 배포 전에는
  - Supabase 인증/정합성
  - 실기기 검증
  - 캘린더 / 통계 / 자료 연결 흐름 최종 점검
이 추가로 필요해.
