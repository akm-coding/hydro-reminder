# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-26)

**Core value:** Remind the user to drink water at the right times and make it effortless to log each drink — so they actually hit their daily goal.
**Current focus:** Phase 1 — Foundation

## Current Position

Phase: 1 of 4 (Foundation)
Plan: 0 of 3 in current phase
Status: Ready to plan
Last activity: 2026-02-26 — Roadmap created; phases derived from 21 v1 requirements

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

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

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 3]: Chart library (react-native-gifted-charts vs. victory-native) not yet selected — evaluate at Phase 3 start based on RN 0.81 compatibility and bundle size at that time
- [Phase 4]: Physical device required for notification testing — iOS Simulator does not support local notifications; confirm both iOS and Android 13+ devices are available before Phase 4 begins
- [Phase 1]: NativeWind v4 + Expo 54 compatibility is MEDIUM confidence — verify before installing; fallback to React Native StyleSheet if not confirmed

## Session Continuity

Last session: 2026-02-26
Stopped at: Roadmap written; ready to plan Phase 1
Resume file: None
