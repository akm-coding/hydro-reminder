# Common Pitfalls

**Domain:** Expo + Supabase hydration reminder / habit tracking app
**Researched:** 2026-02-26
**Confidence:** HIGH — these are well-documented failure modes in production Expo + Supabase apps

---

## 1. Push Notification Pitfalls

### Pitfall 1.1 — iOS 64-Notification Scheduling Limit

**What:** iOS limits each app to 64 scheduled local notifications at any time. If a user schedules many reminder times over many days, this limit is silently hit and new notifications stop being scheduled.

**Warning signs:**
- User adds 3+ reminder times and stops receiving alerts after several weeks
- No errors in code; `scheduleNotificationAsync` returns success

**Prevention:**
- Use `DailyTriggerInput` (a single daily repeating schedule per reminder time) instead of scheduling individual one-off notifications for each future day
- With `DailyTriggerInput`, 5 reminder times = 5 scheduled notifications, well under the 64 limit
- Phase 4 (Notifications) must use repeating triggers, not date-specific triggers

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 1.2 — Testing on Simulator vs. Physical Device

**What:** Local notifications work differently in simulators. iOS Simulator may not reliably deliver scheduled notifications. Expo Go on a physical device is required for accurate notification testing.

**Warning signs:**
- Notifications appear to be scheduled but never arrive during development
- Inconsistent behavior between team members on different setups

**Prevention:**
- Test all notification flows on a physical iOS and Android device — not simulator
- Document this requirement in the project README
- Use `expo-notifications` `getPresentedNotificationsAsync()` to verify scheduled notifications exist

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 1.3 — Android Notification Channels (Android 8+)

**What:** Android 8+ requires a notification channel to be created before notifications can be displayed. Skipping this causes silent failure — no notification is shown, no error is thrown.

**Warning signs:**
- Notifications work on iOS but not on Android

**Prevention:**
```typescript
// Set this in app/_layout.tsx or lib/notifications.ts
if (Platform.OS === 'android') {
  await Notifications.setNotificationChannelAsync('reminders', {
    name: 'Water Reminders',
    importance: Notifications.AndroidImportance.HIGH,
    vibrationPattern: [0, 250, 250, 250],
    lightColor: '#FF231F7C',
  });
}
```

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 1.4 — Android 13+ Explicit Permission Required

**What:** Android 13 (API 33) introduced a mandatory `POST_NOTIFICATIONS` runtime permission. Apps that don't request it never display notifications — no error.

**Warning signs:**
- Android 13 device receives no notifications despite scheduling them

**Prevention:**
- `Notifications.requestPermissionsAsync()` handles this on Expo SDK 49+
- Always call this before scheduling; check the return status before proceeding
- Test on a physical Android 13+ device

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 1.5 — Stale Push Tokens

**What:** Expo push tokens can change when the user reinstalls the app or the OS rotates them. Stale tokens stored in the DB cause v2 remote push to silently fail.

**Warning signs:** (Not critical in v1 since we use local notifications, but affects v2)

**Prevention:**
- On every app start, call `getExpoPushTokenAsync` and UPSERT the result — not a one-time call
- Use `UPSERT` (not INSERT) in `user_settings.push_token` to always have the freshest token

**Phase mapping:** Phase 1/4 — store token on start

---

## 2. Supabase Auth Gotchas

### Pitfall 2.1 — Session Not Persisting After App Restart

**What:** Without an AsyncStorage adapter, the Supabase JS client stores the session in memory only. App restart = session lost = user must log in every time.

**Warning signs:**
- "Logged out" on every app restart during development
- Users complain about being logged out constantly

**Prevention:**
```typescript
// lib/supabase.ts — REQUIRED setup
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,  // CRITICAL for React Native — must be false
  },
});
```

**Phase mapping:** Phase 1 — Foundation

---

### Pitfall 2.2 — `detectSessionInUrl: true` in React Native

**What:** The default Supabase JS config has `detectSessionInUrl: true`, which works in web browsers but causes errors in React Native (no window.location).

**Warning signs:**
- Auth errors or crashes immediately on app start
- Error about `window.location` or URL parsing

**Prevention:**
- Always set `detectSessionInUrl: false` in React Native Supabase client initialization (see above)

**Phase mapping:** Phase 1 — Foundation

---

### Pitfall 2.3 — `service_role` Key Exposed in Client Bundle

**What:** Accidentally using the `service_role` key (instead of `anon` key) in the Expo app. The service_role key bypasses ALL RLS policies — any user can read any other user's data.

**Warning signs:**
- RLS policies appear to not be working
- Data is accessible without proper auth

**Prevention:**
- Use ONLY `SUPABASE_ANON_KEY` in the Expo client
- Store keys in `.env` file (never hardcode); add `.env` to `.gitignore`
- Use `expo-constants` or a secrets management approach, never commit secrets
- The `service_role` key should only ever appear in Supabase Edge Functions or server-side code

**Phase mapping:** Phase 1 — Foundation (set up immediately)

---

### Pitfall 2.4 — RLS Policies Missing or Overly Permissive

**What:** Forgetting to enable RLS or writing policies that accidentally allow cross-user data access.

**Warning signs:**
- User A can see User B's drink history
- All data visible when logged in as any user

**Prevention:**
- Enable RLS on every table before the first INSERT — not as a post-launch cleanup
- Test with two separate accounts from day one
- Verify policies in Supabase dashboard using the "RLS Simulator" tool
- Use `USING (user_id = auth.uid())` — never use `USING (true)` in production

**Phase mapping:** Phase 1 — Foundation

---

### Pitfall 2.5 — `handle_new_user` Trigger Missing for Profile Creation

**What:** Without the `on_auth_user_created` trigger, new users have no `profiles` or `user_settings` row. All profile queries return null, causing runtime errors or empty UI states.

**Warning signs:**
- New user signs up, app crashes or shows no data
- `profiles` table is empty despite having users in `auth.users`

**Prevention:**
- Create the `handle_new_user` trigger as part of the database migration in Phase 1
- Test by creating a fresh account and verifying the row appears in `profiles` and `user_settings`

**Phase mapping:** Phase 1 — Foundation

---

## 3. Timezone Handling for Reminders

### Pitfall 3.1 — Storing Reminder Times as UTC Timestamps

**What:** Storing `2026-02-26T09:00:00Z` (UTC) instead of `hour: 9, minute: 0`. When the user travels across time zones, their "9am" reminder arrives at the wrong local time.

**Warning signs:**
- Reminders fire at the wrong time for users in non-UTC timezones
- Reminder times change after daylight saving time transitions

**Prevention:**
- Store `hour` and `minute` as integers in `reminder_schedules`, not as timestamps
- Let the device OS handle timezone — `DailyTriggerInput` uses the device's local time automatically
- This is the pattern already in the schema design — do not change it to timestamps

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 3.2 — Day Boundaries for History Using UTC Instead of Local Time

**What:** `logged_at` is stored as UTC in `drink_logs`. Grouping by date using `DATE(logged_at)` in SQL uses UTC — so a drink logged at 11pm Eastern is counted on the next day's UTC date. History view shows drinks on the wrong day.

**Warning signs:**
- Drink logged late in the evening appears on tomorrow's history
- Day totals look wrong in timezones behind UTC

**Prevention:**
- Pass the user's local timezone to the query, or
- Group by date on the client using `date-fns` with the user's local timezone:
  ```typescript
  import { format } from 'date-fns';
  const localDate = format(new Date(logged_at), 'yyyy-MM-dd'); // uses device TZ
  ```
- Consider adding a `local_date TEXT` column (e.g., `'2026-02-26'`) stored at log time — eliminates timezone math at query time

**Phase mapping:** Phase 2 (drink logging) and Phase 3 (history)

---

## 4. Streak Calculation Edge Cases

### Pitfall 4.1 — Day Boundary Bugs (UTC vs Local)

**What:** Streak logic that uses UTC dates misattributes drinks to the wrong day, causing streaks to break unexpectedly or extend incorrectly.

**Warning signs:**
- User complains streak broke even though they drank yesterday
- Streak counts look off by 1 day in certain timezones

**Prevention:**
- Calculate streaks on the client using the device's local timezone
- Or add a `local_date` column to `drink_logs` at insertion time:
  ```typescript
  const local_date = format(new Date(), 'yyyy-MM-dd'); // device local time
  // INSERT: { amount_ml, local_date, logged_at: new Date().toISOString() }
  ```
- Then group by `local_date` for streak calculation — no timezone math at query time

**Phase mapping:** Phase 3 — History + Trends

---

### Pitfall 4.2 — Goal Threshold Ambiguity

**What:** "Did the user hit their goal today?" is ambiguous. Is it ≥ 100%? ≥ 80%? Exactly 100%? This affects every streak calculation.

**Warning signs:**
- Users feel the streak doesn't match their actual drinking behavior

**Prevention:**
- Define clearly: goal is hit when `daily_total_ml >= daily_goal_ml`
- Codify this in `lib/hydration.ts`:
  ```typescript
  export const isGoalMet = (totalMl: number, goalMl: number): boolean =>
    totalMl >= goalMl;
  ```
- Use this single function everywhere — no inline comparisons

**Phase mapping:** Phase 2 (define), Phase 3 (apply to streak)

---

### Pitfall 4.3 — Fetching All History for Streak Calculation

**What:** Loading the entire `drink_logs` table to compute streaks client-side. Grows unbounded.

**Warning signs:**
- App feels slow for users who've been using it for months
- Large response payloads from Supabase

**Prevention:**
- Only query the last 90 days for streak calculation
- Or use a Supabase RPC function for server-side streak computation
- Consider a `daily_summaries` materialized table (built via trigger or Edge Function) if scaling beyond 10K users

**Phase mapping:** Phase 3 — History + Trends

---

## 5. Expo Managed Workflow Limitations

### Pitfall 5.1 — Background Fetch is Unreliable for Reminders

**What:** `expo-background-fetch` is often used for reminder systems but is highly unreliable on iOS (limited to ~15min intervals, iOS may not wake the app at all when throttling background tasks).

**Warning signs:**
- Team considers using background fetch to "check if it's time to remind the user"
- Reminders don't fire consistently during development

**Prevention:**
- Do NOT use background fetch for reminders — use `expo-notifications` local scheduled notifications exclusively
- Local notifications are delivered by the OS even when the app is completely closed; no background execution needed
- Background fetch is appropriate for syncing data in the background, not for delivering timely reminders

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 5.2 — Notification State Gets Out of Sync After Reinstall

**What:** When the user reinstalls the app, all OS-scheduled notifications are cleared. If the app doesn't re-register them from the DB on first launch, the user never receives reminders again.

**Warning signs:**
- User reports reminders stopped working after reinstalling the app

**Prevention:**
- On every authenticated app start, call `syncRemindersFromDB(schedules)` which:
  1. Fetches all `enabled` rows from `reminder_schedules`
  2. Cancels ALL currently scheduled notifications
  3. Reschedules all of them from scratch
- This is idempotent — safe to call on every start

**Phase mapping:** Phase 4 — Notifications + Settings

---

### Pitfall 5.3 — Notification Permissions Must Be Requested at the Right Time

**What:** iOS permission dialogs can only be shown once. If shown at an inappropriate time (cold start before user understands value), many users deny. Denied = no notifications = core product doesn't work.

**Warning signs:**
- Permission dialog appears immediately on first app launch before any value is shown

**Prevention:**
- Show the permission request AFTER the user has set up their first reminder time
- Frame the request: "Enable notifications to get your water reminders at [time]?"
- If denied, gracefully degrade: show in-app reminders only, and offer a Settings deep-link to enable later

**Phase mapping:** Phase 4 — Notifications + Settings (during onboarding flow)

---

### Pitfall 5.4 — NativeWind v4 New Architecture Compatibility

**What:** NativeWind v4 requires the New Architecture (`newArchEnabled: true`). The existing project has this enabled, which is correct. But if package versions are mismatched, Tailwind classes silently fail — no error, just unstyled components.

**Warning signs:**
- Tailwind classes don't apply; components render with no styles

**Prevention:**
- Verify NativeWind v4 compatibility with the exact Expo SDK version before installing
- Check NativeWind changelog and GitHub issues for known Expo 54 compatibility
- Alternative: use React Native's built-in `StyleSheet` for v1 if NativeWind causes issues — it's simpler and guaranteed compatible

**Phase mapping:** Phase 1 — Foundation (install NativeWind and verify before building any components)

---

### Pitfall 5.5 — `react-native-url-polyfill` Must Be the First Import

**What:** The Supabase JS client uses URL parsing internally. Without the URL polyfill, certain Supabase operations (particularly auth) crash with a `URL is not a constructor` error.

**Warning signs:**
- App crashes on start or on any Supabase call with `URL is not a constructor` or similar error

**Prevention:**
```typescript
// app/_layout.tsx — MUST be the very first line
import 'react-native-url-polyfill/auto';

// All other imports AFTER
import { Stack } from 'expo-router';
// ...
```

**Phase mapping:** Phase 1 — Foundation (Day 1 setup)

---

## Summary Table

| Pitfall | Severity | Phase | Quick Fix |
|---------|----------|-------|-----------|
| iOS 64-notification limit | HIGH | 4 | Use `DailyTriggerInput` repeating triggers |
| Android 13+ permission | HIGH | 4 | `requestPermissionsAsync()` + test on physical device |
| Android notification channel | HIGH | 4 | Create channel before scheduling |
| Session not persisting | HIGH | 1 | AsyncStorage adapter + `detectSessionInUrl: false` |
| service_role key in client | CRITICAL | 1 | Use anon key only in Expo app |
| RLS policies missing | CRITICAL | 1 | Enable RLS before first INSERT; test with 2 accounts |
| handle_new_user trigger | HIGH | 1 | Create trigger in Phase 1 migration |
| UTC day boundary (history) | MEDIUM | 3 | Use `local_date` column or client-side grouping |
| UTC day boundary (streaks) | MEDIUM | 3 | Group by `local_date`, not UTC date |
| Goal threshold ambiguity | LOW | 2 | Single `isGoalMet()` function in lib/hydration.ts |
| Background fetch for reminders | HIGH | 4 | Use local notifications — not background fetch |
| Post-reinstall notification loss | HIGH | 4 | `syncRemindersFromDB()` on every authenticated start |
| Permission request timing | MEDIUM | 4 | Ask after user sets first reminder — not on cold start |
| URL polyfill import order | HIGH | 1 | `react-native-url-polyfill/auto` must be first import |
| NativeWind compatibility | MEDIUM | 1 | Verify Expo 54 + NativeWind v4 compatibility before install |

---

## Sources

- iOS 64 local notification limit: HIGH confidence — documented in Apple Human Interface Guidelines and community reports
- Android notification channels (API 26+): HIGH confidence — official Android documentation
- Android 13+ POST_NOTIFICATIONS: HIGH confidence — official Android documentation
- Supabase AsyncStorage adapter requirement: HIGH confidence — Supabase official React Native quickstart guide
- `detectSessionInUrl: false` requirement: HIGH confidence — Supabase official React Native documentation
- service_role key risks: HIGH confidence — Supabase official security documentation
- Background fetch unreliability on iOS: HIGH confidence — documented Apple limitation, common community finding
- `react-native-url-polyfill` first-import requirement: HIGH confidence — Supabase and community documentation
- NativeWind v4 New Architecture requirement: MEDIUM confidence — NativeWind documentation; verify current Expo 54 compatibility
