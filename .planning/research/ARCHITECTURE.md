# Architecture Patterns

**Domain:** Mobile hydration reminder app (Expo + Supabase)
**Researched:** 2026-02-26
**Confidence:** HIGH — based on official Expo/Supabase documentation patterns and established community conventions

---

## Recommended Architecture

Client-first architecture where the mobile client owns all user-facing logic. Supabase acts as the backend-as-a-service layer (auth, database). Local notifications handle reminder scheduling without any custom server.

```
┌──────────────────────────────────────────────────────┐
│                   Mobile Client (Expo)               │
│                                                      │
│  ┌─────────┐  ┌──────────┐  ┌───────────────────┐   │
│  │  Auth   │  │  Data    │  │  Notifications    │   │
│  │  Layer  │  │  Layer   │  │  Layer            │   │
│  │(Supabase│  │(Supabase │  │(expo-notifications│   │
│  │  Auth)  │  │  DB)     │  │  local scheduler) │   │
│  └────┬────┘  └────┬─────┘  └────────┬──────────┘   │
│       │            │                 │               │
│  ┌────▼────────────▼─────────────────▼──────────┐   │
│  │              React Context / Hooks            │   │
│  │  (AuthContext, HydrationContext)              │   │
│  └────────────────────┬──────────────────────────┘   │
│                       │                              │
│  ┌────────────────────▼──────────────────────────┐   │
│  │              Screen Components                │   │
│  │  (expo-router file-based navigation)          │   │
│  └───────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│   Supabase      │
│  - Auth         │
│  - PostgreSQL   │
│  - Row-Level    │
│    Security     │
└─────────────────┘
```

**Key architectural decision:** Use **local notifications** (scheduled on-device via expo-notifications) for reminders, NOT a server-triggered push flow. Local scheduling works when the app is in the background or foreground without any server infrastructure.

---

## Folder Structure

```
hydro-reminder/
├── app/                          # All screens (file-based routing via expo-router)
│   ├── _layout.tsx               # Root layout — providers, auth gate
│   ├── (auth)/                   # Auth group (unauthenticated)
│   │   ├── _layout.tsx
│   │   ├── sign-in.tsx
│   │   └── sign-up.tsx
│   ├── (tabs)/                   # Main app group (authenticated)
│   │   ├── _layout.tsx           # Tab bar layout
│   │   ├── index.tsx             # Today's dashboard (goal progress, log drink)
│   │   ├── history.tsx           # Calendar + drink history
│   │   ├── trends.tsx            # Streaks + trend charts
│   │   └── settings.tsx          # Goal, reminders, unit preference
│   └── modal.tsx                 # Quick-log modal (from notification tap)
│
├── lib/                          # Pure logic, no React
│   ├── supabase.ts               # Supabase client singleton
│   ├── notifications.ts          # expo-notifications registration + scheduling
│   └── hydration.ts              # Goal math (ml/oz conversions, progress %)
│
├── hooks/                        # Custom React hooks
│   ├── use-auth.ts
│   ├── use-hydration.ts          # Today's intake, log drink, goal
│   ├── use-history.ts            # Fetch drink logs by date range
│   ├── use-reminders.ts          # Read/write reminder schedules
│   └── use-streaks.ts            # Compute streak from drink_logs
│
├── contexts/
│   ├── auth-context.tsx          # Session, user — wraps root layout
│   └── hydration-context.tsx     # Today's state — wraps (tabs) layout
│
├── components/
│   ├── ui/                       # Primitives — already exists
│   ├── drink-log-button.tsx
│   ├── progress-ring.tsx
│   ├── reminder-time-picker.tsx
│   ├── history-calendar.tsx
│   └── streak-badge.tsx
│
├── constants/
│   └── theme.ts                  # Already exists
├── assets/                       # Already exists
├── app.json
└── package.json
```

---

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `lib/supabase.ts` | Supabase client singleton, auth helpers | Everything that needs DB or auth |
| `lib/notifications.ts` | Permissions, push token, schedule/cancel local notifications | `hooks/use-reminders.ts` |
| `lib/hydration.ts` | Unit conversions (ml/oz), goal progress math | `hooks/use-hydration.ts`, screen components |
| `contexts/auth-context.tsx` | Session state, sign-in/out, auth redirect | Root `_layout.tsx` |
| `contexts/hydration-context.tsx` | Today's drink logs in memory, optimistic updates | `(tabs)/index.tsx` |
| `hooks/use-hydration.ts` | Today's intake from Supabase + local state | `(tabs)/index.tsx` |
| `hooks/use-history.ts` | Paged/ranged drink log queries | `(tabs)/history.tsx` |
| `hooks/use-reminders.ts` | CRUD on reminder schedules, syncs to local notifications | `(tabs)/settings.tsx` |
| `hooks/use-streaks.ts` | Derives streak count from drink_logs | `(tabs)/trends.tsx` |

---

## Data Flow

### Auth Flow
```
App launch
  └── root _layout.tsx mounts AuthContext
        └── AuthContext checks supabase.auth.getSession()
              ├── session exists → render (tabs) group
              └── no session    → redirect to (auth)/sign-in
```

### Drink Log Flow (Today Dashboard)
```
User taps "Log Drink" with amount
  └── use-hydration.logDrink(amount, unit)
        ├── Optimistic update: add to local state immediately (UI feels instant)
        └── INSERT into drink_logs (user_id, amount_ml, logged_at)
              ├── success → confirm local state
              └── error   → revert local state, show error toast
```

### Reminder Scheduling Flow
```
User saves reminder time (e.g., 9:00 AM) in Settings
  └── use-reminders.addReminder(hour, minute)
        ├── INSERT into reminder_schedules (user_id, hour, minute, enabled)
        └── notifications.scheduleDailyReminder(hour, minute)
              └── Notifications.scheduleNotificationAsync({
                    trigger: { type: 'daily', hour, minute }
                  })
                    └── OS delivers local notification at scheduled time
                          └── User taps → deep link opens app/modal.tsx
```

### Cross-Device Sync Flow
```
User logs in on second device
  └── AuthContext: session established
        └── (tabs) layout mounts HydrationContext
              └── useHydration fetches today's drink_logs from Supabase
                    └── Shows synced progress

v1: Refetch on AppState 'active' event (no Realtime subscription)
v2: Add Supabase Realtime subscriptions for live cross-device sync
```

---

## Supabase Schema

### `profiles`
Extends Supabase Auth's `auth.users`. Created via trigger on signup.

```sql
CREATE TABLE profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_goal_ml INT NOT NULL DEFAULT 2000,
  unit_pref    TEXT NOT NULL DEFAULT 'ml' CHECK (unit_pref IN ('ml', 'oz')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### `drink_logs`
One row per drink event.

```sql
CREATE TABLE drink_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount_ml  INT NOT NULL CHECK (amount_ml > 0),
  logged_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_drink_logs_user_date ON drink_logs (user_id, logged_at DESC);
```

**Key decision:** Store amounts in ml universally. Convert to oz on the client. This avoids mixed-unit aggregation bugs.

### `reminder_schedules`
One row per user-defined reminder time.

```sql
CREATE TABLE reminder_schedules (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  hour       SMALLINT NOT NULL CHECK (hour BETWEEN 0 AND 23),
  minute     SMALLINT NOT NULL CHECK (minute BETWEEN 0 AND 59),
  enabled    BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_reminder_unique_time ON reminder_schedules (user_id, hour, minute);
```

**Key decision:** Store hour/minute (not timestamp). Reminders repeat daily. DB is source of truth; OS notifications are derived from it.

### `user_settings`

```sql
CREATE TABLE user_settings (
  user_id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_token          TEXT,
  notif_enabled       BOOLEAN DEFAULT true,
  onboarding_complete BOOLEAN DEFAULT false,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### RLS Policies

```sql
-- Enable RLS on all tables
ALTER TABLE profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE drink_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings      ENABLE ROW LEVEL SECURITY;

-- Owner-only policies
CREATE POLICY "profiles_owner"  ON profiles           USING (id = auth.uid());
CREATE POLICY "drink_logs_owner" ON drink_logs         USING (user_id = auth.uid());
CREATE POLICY "reminders_owner" ON reminder_schedules  USING (user_id = auth.uid());
CREATE POLICY "settings_owner"  ON user_settings       USING (user_id = auth.uid());

-- Auto-create profile + settings on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id);
  INSERT INTO public.user_settings (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## Notification Architecture

### Local Notifications (v1)

Use `expo-notifications` with `scheduleNotificationAsync` and `DailyTriggerInput`. No server needed.

```typescript
// lib/notifications.ts exports:
registerForPushNotifications()     // request permission, store push token
scheduleDailyReminder(id, h, m)    // schedule repeating local notification
cancelReminder(id)                 // cancel by identifier
cancelAllReminders()               // clear all on sign-out or disable
syncRemindersFromDB(schedules)     // restore notifications from DB on app start
```

### Sync-on-Start Pattern

On every authenticated app start, cancel all existing scheduled notifications and reschedule from DB. This handles reinstall, cross-device login, and settings changes.

### Notification Tap Deep Link

```typescript
// app/_layout.tsx
Notifications.addNotificationResponseReceivedListener((response) => {
  const url = response.notification.request.content.data?.url;
  if (url) router.push(url as Href);
});
```

Notification payload: `{ data: { url: '/modal' } }`

---

## Key Patterns

### Optimistic Updates for Drink Logging
Update local state before Supabase INSERT resolves. Revert on error.

### ml-Canonical Storage with Client-Side Conversion
Always INSERT in ml. Convert from oz input before INSERT. Convert to oz for display.

```typescript
// lib/hydration.ts
export const ozToMl = (oz: number) => Math.round(oz * 29.5735);
export const mlToOz = (ml: number) => parseFloat((ml / 29.5735).toFixed(1));
```

### Scoped Context Placement
```
AuthContext       → app/_layout.tsx        (needed everywhere)
HydrationContext  → app/(tabs)/_layout.tsx  (only in authenticated tabs)
```

---

## Build Order (Phase Dependencies)

```
Phase 1: Foundation (auth + Supabase)
  ├── Supabase project + schema + RLS policies + trigger
  ├── lib/supabase.ts client singleton
  ├── contexts/auth-context.tsx
  └── app/(auth)/sign-in.tsx + sign-up.tsx

         ↓ auth must work before any data can be read/written

Phase 2: Core Loop (today's dashboard + drink logging)
  ├── hooks/use-hydration.ts
  ├── contexts/hydration-context.tsx
  ├── components/progress-ring.tsx + drink-log-button.tsx
  ├── app/(tabs)/index.tsx
  └── app/modal.tsx

         ↓ drink logging must produce data before history is meaningful

Phase 3: History + Trends
  ├── hooks/use-history.ts + use-streaks.ts
  ├── components/history-calendar.tsx + streak-badge.tsx
  ├── app/(tabs)/history.tsx
  └── app/(tabs)/trends.tsx

         ↓ goal + unit settings must exist before notifications reference them

Phase 4: Notifications + Settings
  ├── lib/notifications.ts
  ├── hooks/use-reminders.ts
  ├── components/reminder-time-picker.tsx
  └── app/(tabs)/settings.tsx
```
