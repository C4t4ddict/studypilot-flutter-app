# Supabase Quick Setup (GUICULUM_FLUTTER)

## 1) SQL 실행
Supabase Dashboard → SQL Editor 에서 아래 순서로 실행:

1. `supabase/sql/001_profiles.sql`
2. `supabase/sql/002_seed_search_items.sql`
3. `supabase/sql/003_planner_core.sql`
4. `supabase/sql/004_auth_profile_trigger.sql`  (Google/일반 회원가입 시 profiles 자동 생성)
5. `supabase/sql/005_weekly_reviews.sql`
6. `supabase/sql/006_growth_features.sql`

> 이미 `todos` 테이블이 있고 status check가 `todo/done`만 허용 중이면 SQL Editor에서 아래를 추가 실행:
```sql
alter table public.todos drop constraint if exists todos_status_check;
alter table public.todos add constraint todos_status_check check (status in ('todo','in_progress','done'));
alter table public.todos add column if not exists priority text not null default 'medium';
alter table public.todos drop constraint if exists todos_priority_check;
alter table public.todos add constraint todos_priority_check check (priority in ('low','medium','high'));
```

## 2) Auth Provider 설정
Authentication → Providers → Google 활성화

### Redirect URL 추가
- Web(local): `http://localhost:53001/auth/callback`
- Mobile(deeplink): `guiculum://auth/callback`

> 포트가 다르면 실제 실행 포트 기준으로 web callback을 맞춰야 함.

## 3) 앱 env 설정
`.env`
```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 4) 실행
```bash
flutter pub get
flutter run -d chrome --web-port 53001
```

## 5) 검증 시나리오
1. `/login`에서 Google 로그인
2. 홈에서 Auth 상태 확인
3. `/profile` 진입 시 내 프로필 표시
4. `/search`에서 키워드 입력 시 seed 데이터 검색
