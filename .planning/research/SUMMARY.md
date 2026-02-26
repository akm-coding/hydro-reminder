# Project Research Summary

**Project:** Hydro Reminder
**Domain:** Mobile hydration reminder / water tracking app (Expo + Supabase)
**Researched:** 2026-02-26
**Confidence:** HIGH overall

## Executive Summary

Hydro Reminder is a mobile habit-tracking app in a mature, well-understood market. The hydration app category is 8+ years old, which means best practices are well-established, user expectations are clear, and common failure modes are documented. The recommended approach is a client-first architecture: the Expo app owns all user-facing logic, Supabase provides auth and database as a service, and local scheduled notifications (not server push) handle reminders. This stack eliminates the need for a custom backend server entirely for v1. The existing project scaffold (Expo 54, React Native 0.81, expo-router) is already correct — no changes needed to the base project.

The core product value lives in three sequential loops: log a drink, see today's progress, and receive reminders to do it again. These must all work reliably before any social, trend, or gamification layer is added. The target user is developers and knowledge workers — a technically sophisticated audience who notice dark patterns and friction immediately. This means the app must be fast, honest, and data-dense, with manual control over scheduling rather than "smart" AI-driven reminders. Every extra tap between a notification and a logged drink reduces compliance; the logging action must complete in 1-2 taps.

The highest-risk areas are all in Phase 1 and Phase 4. Phase 1 carries multiple critical security and auth setup pitfalls (wrong Supabase key, missing RLS, session persistence failures) that, if skipped, corrupt the entire application. Phase 4 (notifications) has the most platform-specific landmines: iOS's 64-notification limit, Android's channel and permission requirements, and the silent failure mode of background fetch. Both phases are well-documented, but require careful setup checklists rather than exploratory development.

---

## Key Findings

### Recommended Stack

The existing scaffold is correct and complete — no core package changes are needed. Add Supabase integration, notification support, state management, and utilities as targeted installs. The critical install-order constraint is that `react-native-url-polyfill/auto` must be the very first import in `app/_layout.tsx` before any Supabase code runs; violating this causes silent crashes on auth operations. Use `@react-native-async-storage/async-storage` as the Supabase session storage adapter or users will be logged out on every app restart.

For state management, split responsibilities clearly: Zustand for local UI state (preferences, unit toggle, goal display) and TanStack Query v5 for server state (drink logs, history from Supabase). Merging both into one solution causes hand-rolled cache logic. Use `expo-notifications` with `DailyTriggerInput` for repeating local notifications — this is the only reliable reminder mechanism on iOS; background fetch is not a substitute.

**Core technologies:**
- `Expo 54 / React Native 0.81 / expo-router`: Existing scaffold — file-based routing, correct for this app size
- `@supabase/supabase-js` + AsyncStorage: Auth + database backend, session persistence — stable documented pattern
- `expo-notifications` (local only): Reminder scheduling via OS — no server needed for fixed daily times
- `zustand ^5`: Local/UI state (preferences, unit toggle) — simpler than Redux for this scale
- `@tanstack/react-query ^5`: Server state for Supabase queries — prevents hand-rolled cache logic
- `date-fns ^3`: Streak calculation, history grouping, timezone-safe date formatting — no native deps
- `react-hook-form ^7`: Goal setup, drink amount forms — standard form validation
- `nativewind ^4` (conditional): Tailwind-style classes — verify Expo 54 + New Architecture compatibility before installing; fallback to StyleSheet if issues arise

**Defer decision:** Chart library (react-native-gifted-charts vs. victory-native) until the trends phase.

### Expected Features

The market is mature enough that table stakes are non-negotiable. The core action — logging a drink — must complete in 1-2 taps with quick-add presets. Without reliable push notifications, the app has no differentiated value over a mental note. Streaks are a low-complexity motivation layer that users expect in this category.

**Must have (table stakes):**
- Daily water intake goal (user-set, ml/oz toggle) — every competitor has this; users look for it on first launch
- Log a drink by amount with quick-add presets (250ml, 500ml, 1L) — core action; presets cut friction dramatically
- Today's progress display (progress ring toward daily goal) — immediate feedback that logging worked
- Push notifications at scheduled times — this IS the "reminder" value; no reminders = no product
- Notification time customization — fixed times feel broken; users have irregular schedules
- Streak counter (consecutive days hitting goal) — standard motivation layer in this category
- Drink history (at minimum 7 days) — confirms logging works; detects patterns
- Account + cloud sync — required; cross-device access is the implied payoff of requiring sign-up

**Should have (competitive differentiators):**
- Quick-add presets on home screen — biggest single friction reducer in logging flow
- Trends view (weekly/monthly bar chart, 30-day rolling average) — converts logger into insight tool; resonates with developer target audience
- Dark mode — low effort; developers expect it; build from day one, not retrofitted later
- Onboarding that sets goal + first reminder in under 60 seconds — activation rate driver; 3 screens max
- Contextual motivational copy — static message bank; no AI required; productivity-framing resonates with target users

**Defer (v2+):**
- Notification inline action ("Log 250ml" from notification banner) — high value but medium-high complexity; build after core notification flow is stable
- Smart goal suggestion based on weight — reduces onboarding friction; not blocking v1
- Apple Health / Google Fit integration — complex native modules; design data model to be export-compatible now
- Home screen widget — likely requires ejecting from Expo managed workflow
- Wearable companion — doubles testing surface; defer

**Explicit anti-features (do not build):**
- Social features, leaderboards, challenges — near-zero retention benefit for developer target audience
- AI-adaptive scheduling — no training corpus at v1; false intelligence is worse than honest fixed scheduling
- Complex offline-first sync with conflict resolution — optimistic local logging that syncs on reconnect is sufficient

### Architecture Approach

The architecture is client-first with a thin backend. The Expo client owns all user-facing logic. Supabase provides auth (via Supabase Auth), a PostgreSQL database (three tables: `profiles`, `drink_logs`, `reminder_schedules`), and Row Level Security to ensure users can only access their own data. Local notifications are scheduled entirely on-device — no custom server, no Expo Push Service for v1. The pattern is: user saves a reminder time in settings, the app writes it to Supabase and immediately calls `scheduleNotificationAsync` with a `DailyTriggerInput`. On every authenticated app start, all OS notifications are cancelled and rescheduled from the database — this handles reinstalls and cross-device login atomically.

**Major components:**
1. `lib/supabase.ts` — Supabase client singleton with AsyncStorage adapter; must be initialized with `detectSessionInUrl: false` and `persistSession: true`
2. `lib/notifications.ts` — Permission registration, local notification scheduling/cancellation, and the critical `syncRemindersFromDB()` function called on every authenticated start
3. `lib/hydration.ts` — Pure unit conversion (ml/oz), goal progress math, and the canonical `isGoalMet()` function used everywhere
4. `contexts/auth-context.tsx` — Session state, sign-in/out, auth-gated routing; placed at root `_layout.tsx`
5. `contexts/hydration-context.tsx` — Today's drink logs in memory with optimistic updates; placed at `(tabs)/_layout.tsx` (authenticated only)
6. `hooks/` layer — Custom hooks (`use-hydration`, `use-history`, `use-reminders`, `use-streaks`) wrapping Supabase queries via TanStack Query
7. Supabase DB — Three tables with RLS enabled; amounts stored in ml universally, converted to oz client-side; reminder times stored as `hour`/`minute` integers (not UTC timestamps)

**Key data model decisions:**
- Store all drink amounts in ml; convert to oz for display only — avoids mixed-unit aggregation bugs
- Store reminder times as `(hour, minute)` integers, not UTC timestamps — device OS handles timezone automatically with `DailyTriggerInput`
- Add a `local_date TEXT` column to `drink_logs` at insertion time — eliminates timezone math in history grouping and streak calculation

### Critical Pitfalls

1. **`service_role` key in Expo app** (CRITICAL, Phase 1) — Always use `SUPABASE_ANON_KEY` in the client; service_role bypasses all RLS and exposes all users' data. Store keys in `.env`, never commit.
2. **RLS not enabled before first INSERT** (CRITICAL, Phase 1) — Enable Row Level Security on all tables and create owner-only policies in the Phase 1 migration; test immediately with two separate accounts using the Supabase RLS Simulator.
3. **Session not persisting / `detectSessionInUrl: true`** (HIGH, Phase 1) — Configure the Supabase client with `storage: AsyncStorage`, `persistSession: true`, and `detectSessionInUrl: false`; without this, users are logged out on every restart.
4. **`react-native-url-polyfill/auto` not first import** (HIGH, Phase 1) — Must be the absolute first line in `app/_layout.tsx`; placing it after any other import causes `URL is not a constructor` crashes on Supabase auth operations.
5. **iOS 64-notification scheduling limit** (HIGH, Phase 4) — Use `DailyTriggerInput` (one repeating schedule per reminder time) instead of individual one-off notifications per day; 5 reminder times = 5 scheduled notifications, well under the limit.
6. **Android notification channel missing** (HIGH, Phase 4) — Android 8+ silently drops notifications without a channel; create the channel in `lib/notifications.ts` before any `scheduleNotificationAsync` call.
7. **Post-reinstall notification loss** (HIGH, Phase 4) — On every authenticated start, call `syncRemindersFromDB()` which cancels all OS-scheduled notifications and reschedules from the database; this is idempotent and handles reinstalls automatically.
8. **UTC day boundary bugs in history and streaks** (MEDIUM, Phases 2-3) — Group by `local_date` (stored at log time as device local date string) rather than computing `DATE(logged_at)` in SQL; avoids drinks appearing on the wrong calendar day for users in non-UTC timezones.

---

## Implications for Roadmap

Based on the combined research, four phases emerge in a strict dependency order. Auth and database must work before any data can be written. The core logging loop must produce data before history and trends are meaningful. Settings and notifications come last because they depend on goal/unit settings being established and because notification platform requirements are isolated to this phase.

### Phase 1: Foundation — Auth, Supabase, and Project Setup

**Rationale:** Every feature depends on authenticated users and a functioning Supabase connection. Security pitfalls (service_role key, RLS, session persistence, URL polyfill) are all concentrated here and are cheapest to fix before any feature code is written. NativeWind compatibility must be resolved here before it affects all component work.

**Delivers:** Working sign-up/sign-in flow, session persistence, user profile auto-creation, Row Level Security on all tables, and verified project dependency setup.

**Addresses features from FEATURES.md:** Account + cloud sync (auth prerequisite), unit preference setup, daily goal storage.

**Avoids pitfalls:** `service_role` key exposure, missing RLS, session loss on restart, `detectSessionInUrl` crash, URL polyfill crash, NativeWind compatibility failure, missing `handle_new_user` trigger.

**Research flag:** Standard patterns — Supabase + Expo auth is well-documented. No additional research needed.

---

### Phase 2: Core Loop — Drink Logging and Today's Dashboard

**Rationale:** The core action (log a drink, see progress) is the smallest useful product and the foundation for all subsequent features. History, streaks, and trends are all meaningless without drink log data. The `isGoalMet()` function and `local_date` column must be defined here to prevent streak bugs later.

**Delivers:** Today's dashboard with progress ring, quick-add presets, optimistic drink logging, goal progress display, and the canonical hydration math library.

**Addresses features from FEATURES.md:** Log a drink, quick-add presets (250ml, 500ml, 1L), today's progress display, daily goal (user-set).

**Avoids pitfalls:** Goal threshold ambiguity (single `isGoalMet()` function), UTC day boundary bugs (add `local_date` column at this phase, not Phase 3).

**Research flag:** Standard patterns — optimistic updates with TanStack Query and Supabase are well-documented. No additional research needed.

---

### Phase 3: History, Streaks, and Trends

**Rationale:** These features depend on accumulated drink log data (must come after Phase 2) and are read-only derivations of that data. Streak logic must use `local_date` grouping rather than UTC dates. The trends view requires a chart library decision.

**Delivers:** 7-day drink history with calendar view, streak counter, and weekly/monthly trends chart.

**Addresses features from FEATURES.md:** Drink history (7-day view), streak counter, trends view (weekly/monthly aggregate).

**Avoids pitfalls:** UTC day boundary bugs in history and streaks (group by `local_date`), unbounded history query for streaks (limit to last 90 days).

**Research flag:** Chart library selection needs a brief evaluation — defer the decision to this phase and evaluate `react-native-gifted-charts` vs. `victory-native` then.

---

### Phase 4: Notifications and Settings

**Rationale:** Notifications reference the user's goal and timezone preferences, so settings must exist first. This phase has the highest density of platform-specific pitfalls and requires physical device testing; isolating it to its own phase prevents notification issues from blocking other development.

**Delivers:** Notification permission flow (with correct timing — after user sets first reminder), daily reminder scheduling, settings screen (goal, reminders, unit preference), and the `syncRemindersFromDB()` idempotent resync pattern.

**Addresses features from FEATURES.md:** Push notifications at scheduled times, notification time customization, dark mode.

**Avoids pitfalls:** iOS 64-notification limit (use `DailyTriggerInput`), Android notification channel requirement, Android 13+ permission requirement, background fetch misuse, post-reinstall notification loss, permission dialog timing, stale push token handling.

**Research flag:** Notification platform requirements are well-documented in Expo official docs. Physical device testing is mandatory — do not rely on simulator. No additional research needed, but a testing checklist should be created at phase start.

---

### Phase Ordering Rationale

- Auth before data: Supabase RLS requires a `user_id` on every row; no data model works without auth.
- Logging before history: History is a view over drink log data; building history first produces empty screens.
- Logging before notifications: Notifications prompt users to log; the logging experience must be good before driving users to it.
- Settings deferred: Goal and unit settings are needed for display (Phase 2), but the settings screen itself is not blocking — defaults work. Notification settings require the notification infrastructure (Phase 4).
- Dark mode threaded through Phase 4: Low effort to add during the UI polish of the settings screen; this is the last significant UI work phase.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Notifications):** Platform-specific behavior varies by OS version and physical device. A testing checklist specific to this project should be drafted at phase start. The research is complete; the implementation checklist is the gap.
- **Phase 3 (Trends):** Chart library selection (react-native-gifted-charts vs. victory-native) should be evaluated when this phase begins — both were unverified at research time.

Phases with standard patterns (can skip research-phase):
- **Phase 1 (Foundation):** Supabase + Expo auth setup is the most-documented pattern in the ecosystem. Pitfalls are known; follow the checklist.
- **Phase 2 (Core Loop):** Optimistic updates with TanStack Query + Supabase is a canonical, well-documented pattern.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Existing scaffold verified from package.json; Supabase + expo-notifications patterns verified from official docs; NativeWind v4 is MEDIUM — verify before install |
| Features | HIGH | Hydration app market is mature (8+ years); table stakes and anti-features are consistent across major competitors; developer audience traits are well-documented |
| Architecture | HIGH | Based on official Expo/Supabase documentation patterns and established community conventions; data model is specific to this app's requirements |
| Pitfalls | HIGH | All critical pitfalls are documented in official Apple, Android, and Supabase documentation; community failure reports corroborate them |

**Overall confidence:** HIGH

### Gaps to Address

- **NativeWind v4 + Expo 54 compatibility:** MEDIUM confidence only. Verify the exact package versions and New Architecture compatibility before Phase 1 work begins. If compatibility is not confirmed, fall back to React Native `StyleSheet` — this is lower risk for v1.
- **Chart library selection:** No definitive recommendation between `react-native-gifted-charts` and `victory-native`. Evaluate both at Phase 3 start based on bundle size, maintenance status, and RN 0.81 compatibility at that time.
- **v2 server push (Expo Push Service + Supabase Edge Functions):** Not needed for v1 but should be designed for. The `user_settings.push_token` column and UPSERT pattern are already in the schema; the integration path is clear when needed.
- **Physical device availability for Phase 4:** Notification testing is explicitly unsupported on iOS Simulator. Both an iOS and Android 13+ physical device must be available before Phase 4 begins.

---

## Sources

### Primary (HIGH confidence)
- Supabase official React Native quickstart — AsyncStorage adapter, `detectSessionInUrl: false`, anon key requirements
- Supabase official security documentation — service_role key risks, RLS patterns
- Expo `expo-notifications` official documentation — `DailyTriggerInput`, permission flow, `scheduleNotificationAsync`
- Apple Human Interface Guidelines — iOS 64-notification local scheduling limit
- Android official documentation — notification channels (API 26+), `POST_NOTIFICATIONS` permission (API 33+)
- Existing `package.json` in project root — Expo 54, React Native 0.81, React 19, expo-router ~6 confirmed

### Secondary (MEDIUM confidence)
- Community consensus on Zustand v5 + TanStack Query v5 as dominant state management pattern for Expo + Supabase apps
- NativeWind v4 documentation — New Architecture requirement; Expo 54 compatibility not independently verified
- Hydration app market analysis — feature landscape based on established competitor patterns
- `date-fns` v3 — stable, well-adopted, no native dependencies

### Tertiary (LOW confidence — validate during implementation)
- `react-native-gifted-charts` vs. `victory-native` — chart library comparison not benchmarked; defer to Phase 3
- v2 smart reminder scheduling — no corpus; would require user data analysis

---
*Research completed: 2026-02-26*
*Ready for roadmap: yes*
