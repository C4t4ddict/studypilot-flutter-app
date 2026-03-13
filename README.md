# GUICULUM_FLUTTER

Flutter 단일 코드베이스로 Web + Mobile 프로토타입.

## 목적
- 취업용 포트폴리오에서 아키텍처/의사결정 역량 강조
- 앱/웹 동시 대응
- Supabase(Auth/RLS) + 반응형 검색(RxDart) 스켈레톤

## 스택
- Flutter 3.x / Dart
- supabase_flutter
- rxdart
- flutter_dotenv

## 컬러 시스템
- Primary: `#771EF4`
- Secondary: `#8249EE`
- Accent: `#A285F9`
- Light: Background `#F8F9FD`, Card `#FFFFFF`
- Dark: Background `#0F0F13`, Card `#1A1A22`

## 구조
- `lib/core/app_router.dart` : go_router 라우팅
- `lib/features/home` : 홈 + 인증상태 표시 + 내비게이션
- `lib/features/login` : 로그인 스켈레톤
- `lib/features/search` : RxDart 검색 이벤트 스트림
- `lib/features/home/profile_page.dart` : 프로필 조회 샘플
- `lib/services/auth_service.dart` : Supabase Auth 래퍼
- `lib/services/profile_service.dart` : 프로필 데이터 접근
- `supabase/sql` : RLS 전제 SQL
- `docs/adr` : 아키텍처 의사결정 문서

## 실행
```bash
cd GUICULUM_FLUTTER
cp .env.example .env
# .env에 Supabase URL/KEY 입력
flutter pub get
flutter run -d chrome --web-port 53001  # 웹
flutter run -d ios                       # iOS
flutter run -d android                   # Android
```

Supabase 초기화/시드는 `docs/setup-supabase.md` 참고.
캘린더는 현재 외부 API 없이 Todo 기반 일정 표시 모드로 동작.

## 환경변수
`.env`
```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 추가 반영 (v0.2)
- `go_router` 라우팅 적용 (`/`, `/login`, `/search`, `/profile`, `/auth/callback`)
- Auth 세션 스트림 구독 + signedIn 시 `profiles` 자동 upsert
- 홈에서 로그인 상태 배지 + 로그인/로그아웃 스낵바 피드백
- 홈에 대시보드 카드(핵심 플로우/타임라인/오늘 할 일)
- 핵심 화면
  - `/guidelines` (가이드라인 생성)
  - `/curriculums` (기간 기반 커리큘럼 생성)
  - `/todos` (실행 단위 todo 수동 추가/체크/날짜 지정)
  - `/review` (주간 회고)
  - `/templates` (직무 템플릿)
  - `/insights` (리스크 인사이트)
  - `/productivity` (Pomodoro/습관/자동 재계획)
  - `/gamification` (streak/레벨/배지/히트맵)
  - `/ai-assist` (AI 추천 MVP)
  - `/ops` (CSV 백업/공유/운영 스캐폴드)
  - `/calendar` (날짜별 커리큘럼/투두 시각화)
- 프로필 화면에서 닉네임 수정/저장 + pull-to-refresh
  - optimistic UI + 실행 취소(Undo)
- 검색은 Supabase `search_items` 실데이터 조회 + 미구성시 fallback
- 검색 화면에 로딩/에러/카드형 결과 UI 반영
- 검색 결과 탭 시 `/search/:id` 상세 라우팅 + Supabase row 상세 조회
- 캘린더 고도화
  - 월/주 보기 토글
  - Todo 상태 필터 칩(전체/미완료/진행중/완료)
  - 웹 URL 쿼리 동기화(`view`, `filter`, `date`)
  - QR/공유시트 링크 공유
  - Todo 선택 다중 이동(선택 항목 날짜 이동)
  - Todo 우선순위(low/medium/high) 및 캘린더 셀 완료율 미니바
- OAuth redirect 분기
  - Web: `${Uri.base.origin}/auth/callback`
  - Mobile: `guiculum://auth/callback`

## 메모
- Web/Android/iOS 실서비스 전환 시 redirect URI/딥링크 도메인 설정 필요
- Supabase SQL(`supabase/sql/001_profiles.sql`, `002_seed_search_items.sql`, `003_planner_core.sql`, `004_auth_profile_trigger.sql`)을 먼저 적용해야 핵심 플로우(가이드라인→커리큘럼→투두)가 동작
- Google/일반 회원가입 시 `auth.users` 생성과 함께 `profiles`가 자동 upsert 되도록 트리거 구성

## MySQL 로컬 세팅(옵션)
Supabase를 유지하면서 로컬 MySQL도 병행 가능:
- 설치: `brew install mysql`
- 실행: `brew services start mysql`
- Workbench: `/Applications/MySQLWorkbench.app`
- 기본 생성 정보
  - DB: `guiculum`
  - USER: `guiculum_user`
  - PASSWORD: `guiculum123!`
- 스키마 샘플: `supabase/sql/900_mysql_bootstrap.sql` (MySQL에서 실행)
