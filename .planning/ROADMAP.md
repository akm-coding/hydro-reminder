# Roadmap: Hydro Reminder

## Overview

Four phases in strict dependency order. Auth and goal setup must exist before any data can be written. The core logging loop must produce data before history and trends are meaningful. Notifications and settings come last because they reference both the goal/unit preferences established earlier and require isolated platform testing. Sync (SYNC-01) is verified at the end when all syncable data types — logs, goal, unit, reminders — are present and testable across two devices.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Auth, Supabase setup, onboarding, and goal/unit configuration
- [ ] **Phase 2: Core Logging Loop** - Drink logging, quick-add, and today's progress dashboard
- [ ] **Phase 3: History and Trends** - Calendar history, streaks, weekly and monthly trends
- [ ] **Phase 4: Notifications, Settings, and Sync** - Reminder scheduling, settings screen, cross-device sync

## Phase Details

### Phase 1: Foundation
**Goal**: Users can create an account, log in, set their daily water goal and preferred unit, and complete onboarding — with all data securely stored in Supabase with row-level security.
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, PROF-01, PROF-02, PROF-03, PROF-04
**Success Criteria** (what must be TRUE):
  1. User can sign up with email and password and immediately access the app
  2. User can close and reopen the app and remain logged in without re-entering credentials
  3. User can log out from any screen and be returned to the auth flow
  4. User can reset their password via an email link and log back in with a new password
  5. User completes onboarding in under 60 seconds: the app suggests a goal based on body weight, the user sets their goal and preferred unit (ml or oz), and reaches the home screen
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md — Project setup: dependencies, Supabase client, URL polyfill, AsyncStorage session adapter, NativeWind/StyleSheet decision
- [ ] 01-02-PLAN.md — Supabase schema, RLS, handle_new_user trigger, auth flow (sign up, sign in, sign out, password reset)
- [ ] 01-03-PLAN.md — Hydration math library, onboarding screens (goal suggestion, unit selection), first-launch routing

### Phase 2: Core Logging Loop
**Goal**: Users can log every drink they take, see their progress toward today's goal in real time, and delete mistakes — making the core action of the app fast and satisfying.
**Depends on**: Phase 1
**Requirements**: LOG-01, LOG-02, LOG-03, LOG-04
**Success Criteria** (what must be TRUE):
  1. User can log a drink by entering a custom amount in their preferred unit (ml or oz)
  2. User can quick-add a drink in one tap using preset amounts (250ml, 500ml, 1L)
  3. User can delete a logged drink entry from today and see the total update immediately
  4. User sees today's total intake and goal progress (amount logged vs. daily goal) update instantly on the home screen after every log action
**Plans**: TBD

Plans:
- [ ] 02-01: Drink log data layer — Supabase table, TanStack Query hooks, optimistic updates, local_date column
- [ ] 02-02: Home screen — progress display, quick-add presets, custom amount entry, delete entry

### Phase 3: History and Trends
**Goal**: Users can look back at their hydration history, see how many consecutive days they have hit their goal, and spot weekly and monthly patterns — turning raw logs into insight.
**Depends on**: Phase 2
**Requirements**: HIST-01, HIST-02, HIST-03, HIST-04
**Success Criteria** (what must be TRUE):
  1. User can view a calendar showing daily intake totals for past days, grouped by local date (not UTC)
  2. User can see their current streak — the number of consecutive days where they met their daily goal
  3. User can view a weekly bar chart showing daily intake totals for the past 7 days
  4. User can view monthly trends and a rolling 30-day average intake
**Plans**: TBD

Plans:
- [ ] 03-01: History data layer — streak calculation using local_date grouping, history query hooks (last 90 days cap)
- [ ] 03-02: History and trends screens — calendar view, streak display, weekly chart, monthly chart (chart library selected at phase start)

### Phase 4: Notifications, Settings, and Sync
**Goal**: Users receive push notifications at their scheduled reminder times even when the app is closed, can manage all settings in one place, and have their data — logs, goal, unit preference, and reminder schedules — available on any device they log into.
**Depends on**: Phase 3
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, SYNC-01
**Success Criteria** (what must be TRUE):
  1. User receives a push notification at each reminder time they have set, even when the app is closed, on both iOS and Android
  2. User can add and remove specific reminder times from the settings screen and changes take effect immediately
  3. User can disable all reminders with a master toggle and re-enable them without losing their configured times
  4. An in-app banner appears when a reminder time is reached while the app is open
  5. After logging into the same account on a second device, the user sees their drink logs, daily goal, unit preference, and reminder schedule without any manual re-configuration
**Plans**: TBD

Plans:
- [ ] 04-01: Notification infrastructure — permission flow, Android channel setup, DailyTriggerInput scheduling, syncRemindersFromDB() on authenticated start
- [ ] 04-02: Settings screen — goal editing, unit toggle, reminder time management, master notification toggle
- [ ] 04-03: Cross-device sync verification — login on second device, confirm all data types present

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/3 | Planned | - |
| 2. Core Logging Loop | 0/2 | Not started | - |
| 3. History and Trends | 0/2 | Not started | - |
| 4. Notifications, Settings, and Sync | 0/3 | Not started | - |
