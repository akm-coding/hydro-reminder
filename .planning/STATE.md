# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-26)

**Core value:** Remind the user to drink water at the right times and make it effortless to log each drink — so they actually hit their daily goal.
**Current focus:** Phase 1 — Foundation

## Current Position

Phase: 1 of 4 (Foundation)
Plan: 3 of 3 in current phase (01-01 complete, 01-02 tasks complete — awaiting human-verify checkpoint)
Status: In progress — awaiting human verification of auth flow before 01-02 checkpoint approval
Last activity: 2026-02-26 — Plan 01-02 tasks 1 and 2 complete; paused at Task 3 human-verify checkpoint

Progress: [███░░░░░░░] 25%

## Performance Metrics

**Velocity:**
- Total plans completed: 1 (01-02 in checkpoint, not yet counted)
- Average duration: ~9 min
- Total execution time: ~18 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 1 complete + 1 in checkpoint | ~18 min | ~9 min |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Phase 1]: `react-native-url-polyfill/auto` must be the absolute first import in `app/_layout.tsx` — before any Supabase code
- [Phase 1]: Use `SUPABASE_ANON_KEY` only (never service_role) in the Expo client; store in `.env`, never commit
- [Phase 1]: Configure Supabase client with `storage: AsyncStorage`, `persistSession: true`, `detectSessionInUrl: false`
- [Phase 1]: Enable RLS on all tables and test with two separate accounts before any feature work proceeds
- [Phase 4]: Use `DailyTriggerInput` for all reminder scheduling (not one-off per-day notifications) — keeps iOS under 64-notification limit
- [01-01]: NativeWind v4 installed (not skipped) — peer deps compatible with Expo 54/RN 0.81
- [01-01]: Supabase client uses throw Error at module load if env vars missing (fail-fast pattern)
- [01-02]: AuthGate renders Stack (not Slot) — owns all Screen declarations so routing useEffect actually executes inside AuthProvider
- [01-02]: Email trimmed and lowercased before signIn/signUp to prevent case-sensitivity account duplication
- [01-02]: Migration applied manually via Supabase Dashboard SQL Editor — no Supabase CLI required

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 3]: Chart library (react-native-gifted-charts vs. victory-native) not yet selected — evaluate at Phase 3 start based on RN 0.81 compatibility and bundle size at that time
- [Phase 4]: Physical device required for notification testing — iOS Simulator does not support local notifications; confirm both iOS and Android 13+ devices are available before Phase 4 begins
- [Phase 1, Plan 01]: NativeWind v4.2.2 installed successfully with Expo 54 / RN 0.81.5 — peer deps only required tailwindcss >3.3.0 (RESOLVED)

## Session Continuity

Last session: 2026-02-26
Stopped at: 01-02-PLAN.md Task 3 — human-verify checkpoint. Tasks 1 (migration SQL) and 2 (auth screens + layout) complete and committed. Awaiting user to apply SQL migration and verify auth flow end-to-end.
Resume file: None
