# Hydro Reminder

## What This Is

A mobile hydration reminder app for developers and desk workers who sit all day and forget to drink water. Users set their own daily water goal, log drinks by amount (ml/oz), receive push notifications at custom-scheduled times, and track their full drinking history with streaks and trends. Accounts are required for history sync across devices via Supabase.

## Core Value

Remind the user to drink water at the right times and make it effortless to log each drink — so they actually hit their daily goal.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can sign up and log in with email/password via Supabase Auth
- [ ] User can set a custom daily water intake goal (in ml or oz)
- [ ] User can log a drink by entering the amount (ml/oz)
- [ ] User can schedule specific reminder times (e.g., 9am, 12pm, 3pm)
- [ ] App sends push notifications at scheduled times (works when app is closed)
- [ ] App shows in-app reminder prompts when open
- [ ] User can see today's progress toward their daily goal
- [ ] User can see full drinking history (calendar view)
- [ ] User can see streaks (consecutive days hitting goal)
- [ ] User can see trends over time
- [ ] Data syncs across devices via Supabase

### Out of Scope

- Smart/adaptive reminders — deferred to v2; requires usage data and added complexity
- Social features (leaderboards, challenges) — not the core value for v1
- Apple Health / Google Fit integration — v2; adds setup complexity
- Wearable support — out of scope for v1

## Context

- **Stack**: Expo (React Native) targeting iOS + Android
- **Backend**: Supabase for auth, database, and real-time sync
- **Existing codebase**: Expo project scaffolded but not yet implemented — greenfield from a product perspective
- **Target user**: Developers and knowledge workers who sit at a desk for long periods

## Constraints

- **Tech stack**: Expo + Supabase — decided, not negotiable
- **Platform**: iOS + Android via Expo managed workflow
- **Auth**: Supabase Auth (accounts required — no anonymous usage)
- **Notifications**: Expo Push Notifications (expo-notifications) for cross-platform support

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Supabase for backend | User chose it — handles auth, DB, and sync in one service | — Pending |
| Accounts required (no anonymous mode) | Enables cross-device sync and history persistence | — Pending |
| User-set reminder times (not smart/adaptive) | Simpler to build and understand for v1 | — Pending |
| Log by amount (ml/oz), not just "I drank" | More meaningful data for tracking and trends | — Pending |

---
*Last updated: 2026-02-26 after initialization*
