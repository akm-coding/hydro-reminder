# Feature Landscape

**Domain:** Mobile hydration reminder / water tracking app
**Target user:** Developers and knowledge workers who sit at a desk for long periods
**Researched:** 2026-02-26
**Confidence:** MEDIUM — hydration app market is mature; patterns reflect established market consensus.

---

## Table Stakes

Features users expect. Missing = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Daily water intake goal (user-set) | Every competitor has this; users look for it on first launch | Low | ml/oz toggle also expected |
| Unit toggle (ml / oz) | Users have strong regional unit preferences | Low | Store preference per user; default based on device locale |
| Log a drink by amount | The core action — must complete in 1–2 taps | Low | Quick-add presets (250ml, 500ml, 1L) dramatically reduce friction |
| Today's progress display | Users need immediate feedback that logging worked | Low | Progress ring or bar toward daily goal is the standard visual pattern |
| Push notifications at scheduled times | This IS the "reminder" part — without it there is no value | Medium | Must work when app is closed; reliable delivery is non-negotiable |
| Notification time customization | Users have different schedules; fixed times feel broken | Low-Med | Add/remove specific times at minimum |
| Streak counter (consecutive days hitting goal) | Motivation layer; streaks are standard in this category | Low | Midnight edge cases are painful — handle carefully |
| Drink history (at minimum last 7 days) | Users want to confirm logs and spot patterns | Low-Med | Calendar view is standard; list view is acceptable fallback |
| Account / cloud sync | If accounts are required, cross-device sync is the implied payoff | Medium | Users will test this immediately on a second device |

---

## Differentiators

Features that give the product a competitive edge. Not expected, but valued when discovered.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Quick-add presets on home screen | Removes the "decide how much" step; biggest friction reducer | Low | Configurable amounts (250ml glass, 500ml bottle, 1L bottle) |
| Trends view (weekly / monthly aggregate) | Converts logger into insight tool; developers respond to data-driven feedback | Medium | Bar chart per week, rolling 30-day average, "best day" highlight |
| Smart goal suggestion based on weight | Reduces setup friction for users who don't know their goal | Low-Med | Simple formula (body weight × 0.033L) or WHO 2.5L guideline |
| Pre-set drink types (glass, bottle, coffee) | Makes logging feel contextual; reduces cognitive load | Low | Map drink type to default volume; user can override per log |
| Notification inline action ("Log 250ml" from notification) | Log without opening the app — dramatically improves compliance | High | expo-notifications supports actionable notifications; Android needs extra setup |
| Motivational copy / contextual messages | Productivity-framed copy resonates with developer target audience | Low | Static message bank with rotation; no AI required for v1 |
| Dark mode | Expected by developers; many work in low-light environments | Low | Worth building from day one |
| Onboarding that sets goal + first reminder in under 60 seconds | First-run experience determines activation rate | Medium | 3 screens max: goal → units → first reminder time |

---

## Anti-Features

Features to explicitly NOT build, with reasoning.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Social features (leaderboards, challenges) | Adds auth complexity, moderation surface; near-zero retention benefit for the target user | Anonymous aggregate stats if social proof needed |
| AI-adaptive / smart reminder scheduling | No training corpus at v1; false intelligence is worse than honest fixed scheduling | Launch with fixed user-set times; build smart scheduling in v2 |
| Beverage nutritional tracking (calories, caffeine) | Scope creep into diet-app territory | Stick to hydration volume only |
| Wearable companion (Apple Watch, Wear OS) | Outside Expo managed workflow; doubles testing surface | Defer to v2 |
| Apple Health / Google Fit integration | Complex OAuth + platform-specific native modules | Design data model to be export-compatible; build in v2 |
| Gamification beyond streaks (badges, points, levels) | Adds asset requirements; the target user is less motivated by badges than clean data | Streaks + trend graphs satisfy the motivation need |
| Aggressive upsell / paywall mechanics | Destroys trust with developers who are highly sensitive to dark patterns | Honest one-time purchase or subscription with clear value |
| Complex offline-first sync with conflict resolution | Adds weeks for a low-frequency problem | Optimistic local logging that syncs on next connection |

---

## Feature Dependencies

```
Account / sign-up
  → Cloud sync (requires auth)
  → Drink history persistence (requires user ID to scope records)
  → Cross-device access (requires cloud sync)

Daily goal (user-set)
  → Today's progress display (requires goal to show progress against)
  → Streak logic (requires goal threshold to determine "hit" vs "missed")
  → Trends view (% of goal is more meaningful than raw ml)

Log a drink
  → Today's progress display (requires log entries for the current day)
  → Drink history (requires persisted log entries)
  → Streak counter (requires daily aggregate to compare against goal)
  → Trends view (requires historical log entries to aggregate)

Push notifications (scheduled)
  → Notification time customization (nothing to customize without notifications)
  → Notification inline action (depends on notifications existing)

Drink history
  → Streak counter (streak computes from historical daily totals)
  → Trends view (requires history to aggregate over time)
```

---

## MVP Recommendation

Priority order for v1:

1. **Log a drink** — core action; everything else is meaningless without it
2. **Today's progress toward daily goal** — immediate feedback loop
3. **Quick-add presets (250ml, 500ml, 1L)** — cutting tap count is essential
4. **Push notifications at scheduled times** — the "reminder" in "reminder app"
5. **Notification time customization** — without this, notifications feel broken
6. **Account + cloud sync** — required by PROJECT.md
7. **Drink history — 7-day view** — validates that logging is working
8. **Streak counter** — motivation layer; very low complexity
9. **Trends — weekly/monthly view** — converts logger into insight tool
10. **Dark mode** — low effort, high signal to developer target audience

**Defer post-v1:**
- Notification inline action — high value, medium-high complexity; build after core notification flow is stable
- Smart goal suggestion — useful for onboarding; not blocking v1
- Home screen widget — likely requires leaving Expo managed workflow

---

## Notes on the Target User (Developers / Desk Workers)

- **They notice dark patterns immediately** — never use misleading UI
- **They appreciate data density** — compact trends chart with numbers beats cartoon water animations
- **They prefer control** — manual scheduling over "trust us to pick the right time"
- **They have irregular schedules** — 9-to-5 reminder defaults are wrong; give full time-of-day control
- **They will test edge cases** — midnight streak resets, logging 0ml, changing goal mid-day; build defensively
- **Friction is the enemy** — every tap between notification and "drink logged" reduces compliance

---

## Confidence Summary

| Area | Level | Reason |
|------|-------|--------|
| Table stakes | HIGH | Market is 8+ years old; these features appear in every major hydration app |
| Differentiators | MEDIUM | Patterns verified across multiple apps in training data |
| Anti-features | HIGH | Developer audience traits and dark-pattern sensitivity are well-documented |
| Developer audience traits | HIGH | Well-documented in UX research and developer-tool market literature |

---

## Roadmap Implications

- Phase 1: Core logging loop (log drink → see progress → repeat) — before notifications
- Phase 2: Notifications + scheduling — the "reminder" value
- Phase 3: History, streaks, trends — the "tracking" value
- Auth/sync should thread through early (Phase 1 or 2) — don't build logging without a user ID
- Dark mode should be designed in from Phase 1, not retrofitted later
