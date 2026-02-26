# Requirements: Hydro Reminder

**Defined:** 2026-02-26
**Core Value:** Remind the user to drink water at the right times and make it effortless to log each drink — so they actually hit their daily goal.

---

## v1 Requirements

### Authentication

- [ ] **AUTH-01**: User can sign up with email and password
- [ ] **AUTH-02**: User can log in with email and password and stay logged in across app restarts
- [ ] **AUTH-03**: User can log out from any screen
- [ ] **AUTH-04**: User can reset their password via an email link

### Profile & Goal Setup

- [ ] **PROF-01**: User can set a custom daily water intake goal in ml or oz
- [ ] **PROF-02**: User can toggle between ml and oz as their preferred display unit
- [ ] **PROF-03**: App suggests a daily goal based on the user's body weight during onboarding (body weight × 0.033L formula)
- [ ] **PROF-04**: App guides the user through onboarding (goal → unit → first reminder time) on first launch in under 60 seconds

### Drink Logging

- [ ] **LOG-01**: User can log a drink by entering an amount in their preferred unit (ml or oz)
- [ ] **LOG-02**: User can quick-add a drink using preset amounts (250ml, 500ml, 1L)
- [ ] **LOG-03**: User can delete a previously logged drink entry from today
- [ ] **LOG-04**: User can see today's total water intake progress toward their daily goal on the home screen

### Notifications & Reminders

- [ ] **NOTIF-01**: App delivers push notifications at user-set times, even when the app is closed
- [ ] **NOTIF-02**: User can add and remove specific reminder times (e.g., 9am, 12pm, 3pm)
- [ ] **NOTIF-03**: User can enable or disable all reminders with a master toggle
- [ ] **NOTIF-04**: App shows an in-app banner prompt when a reminder time is reached while the app is open

### History & Trends

- [ ] **HIST-01**: User can view drink history in a calendar view showing daily intake totals
- [ ] **HIST-02**: User can see their current streak — consecutive days where the daily goal was met
- [ ] **HIST-03**: User can view a weekly trend chart showing daily intake over the past 7 days
- [ ] **HIST-04**: User can view monthly trends and a rolling 30-day average

### Sync

- [ ] **SYNC-01**: User's drink logs, daily goal, unit preference, and reminder schedules sync across devices via Supabase

---

## v2 Requirements

### Notifications

- **NOTIF-V2-01**: User can log a drink directly from a notification action button (without opening the app)
- **NOTIF-V2-02**: Smart reminders — app learns usage patterns and adjusts reminder timing (requires v1 usage data)

### Integrations

- **INTG-01**: App writes daily water intake totals to Apple Health (iOS)
- **INTG-02**: App writes daily water intake totals to Google Fit (Android)

### Platform Extensions

- **PLAT-01**: Home screen widget showing today's progress
- **PLAT-02**: Apple Watch / Wear OS companion app

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Social features (leaderboards, challenges, friends) | Adds moderation surface and complexity; low value for developer target audience |
| AI-adaptive reminder scheduling | No training data at v1; false intelligence is worse than honest fixed times |
| Beverage nutritional tracking (calories, caffeine) | Scope creep into diet app territory; core value is hydration volume only |
| Offline-first conflict resolution | Optimistic local writes + sync-on-connect is sufficient for low-frequency logging |
| Gamification beyond streaks (badges, points, avatars) | Target user values clean data over game mechanics |
| Aggressive upsell / paywall mechanics | Destroys trust with developer target audience |

---

## Traceability

Filled during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | — | Pending |
| AUTH-02 | — | Pending |
| AUTH-03 | — | Pending |
| AUTH-04 | — | Pending |
| PROF-01 | — | Pending |
| PROF-02 | — | Pending |
| PROF-03 | — | Pending |
| PROF-04 | — | Pending |
| LOG-01 | — | Pending |
| LOG-02 | — | Pending |
| LOG-03 | — | Pending |
| LOG-04 | — | Pending |
| NOTIF-01 | — | Pending |
| NOTIF-02 | — | Pending |
| NOTIF-03 | — | Pending |
| NOTIF-04 | — | Pending |
| HIST-01 | — | Pending |
| HIST-02 | — | Pending |
| HIST-03 | — | Pending |
| HIST-04 | — | Pending |
| SYNC-01 | — | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 21 ⚠️

---
*Requirements defined: 2026-02-26*
*Last updated: 2026-02-26 after initial definition*
