# Stack Recommendations

**Domain:** Mobile hydration reminder app (Expo + Supabase)
**Researched:** 2026-02-26
**Confidence:** MEDIUM-HIGH overall

---

## Recommended Stack

### Existing Scaffold (Keep As-Is)

| Package | Version | Notes |
|---------|---------|-------|
| Expo | ~54 | Current — no changes needed |
| React Native | 0.81 | Current |
| React | 19 | Current |
| expo-router | ~6 | File-based routing — correct choice |

> The existing scaffold is already current and well-chosen. No changes to installed packages.

### Supabase Integration

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `@supabase/supabase-js` | latest | HIGH | Core Supabase client |
| `@react-native-async-storage/async-storage` | latest | HIGH | Required for Supabase Auth session persistence |
| `react-native-url-polyfill` | latest | HIGH | **Must be imported first in entry file** — this is the #1 gotcha |

**Install:**
```bash
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill
```

**Critical:** Import `react-native-url-polyfill/auto` as the very first line in `app/_layout.tsx` (or entry point).

### Push Notifications

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `expo-notifications` | latest | HIGH | Use **local scheduled notifications** — not remote push |

**Key decision:** Use `scheduleNotificationAsync` for v1. Reminder times are known at schedule time — no server needed. This avoids backend complexity and works reliably offline.

**Install:**
```bash
npx expo install expo-notifications
```

### State Management

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `zustand` | ^5 | MEDIUM-HIGH | Client/UI state (user prefs, goal, unit toggle) |
| `@tanstack/react-query` | ^5 | MEDIUM-HIGH | Server state for Supabase queries (drink logs, history) |

**Rationale:** Use Zustand for local UI state + TanStack Query for Supabase server state. Using one library for both leads to hand-rolled cache logic.

**Install:**
```bash
npm install zustand @tanstack/react-query
```

### Forms

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `react-hook-form` | ^7 | HIGH | Goal setup, drink amount entry, reminder time picker |

**Install:**
```bash
npm install react-hook-form
```

### Date Utilities

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `date-fns` | ^3 | HIGH | Streak calculation, history grouping, formatting. No native deps. |

**Install:**
```bash
npm install date-fns
```

### UI / Styling

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `nativewind` | ^4 | MEDIUM | Tailwind-style classes for React Native |
| `tailwindcss` | latest | MEDIUM | Peer dependency for NativeWind |

**Install:**
```bash
npm install nativewind && npm install --save-dev tailwindcss
```

> **Verify:** NativeWind v4 requires React Native 0.76+ new architecture. Confirm compatibility with Expo 54 before installing. Check NativeWind changelog.

### Charts (for Trends view)

| Package | Options | Confidence | Notes |
|---------|---------|------------|-------|
| `react-native-gifted-charts` | Primary option | MEDIUM | Good RN support, lightweight |
| `victory-native` | Alternative | MEDIUM | More features, heavier |

**Defer decision** until trends phase — evaluate both options then.

### Testing

| Package | Version | Confidence | Notes |
|---------|---------|------------|-------|
| `jest-expo` | latest | HIGH | Expo-native test runner |
| `@testing-library/react-native` | latest | HIGH | Component testing |

**Install:**
```bash
npx expo install jest-expo && npm install --save-dev @testing-library/react-native
```

---

## What NOT to Use

| Package | Why Avoid |
|---------|-----------|
| Redux / Redux Toolkit | Overkill for this app size — Zustand is simpler |
| MobX | Adds complexity without benefit at this scale |
| Remote push (Expo Push Service) for v1 | Local scheduled notifications are sufficient — no server needed for fixed reminder times |
| `expo-background-fetch` for v1 | Background fetch on iOS is unreliable; local notifications are the correct tool |
| Moment.js | Deprecated; date-fns is the modern replacement |

---

## Full Install Command

```bash
# Supabase
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill

# Notifications
npx expo install expo-notifications

# State
npm install zustand @tanstack/react-query

# Dates + Forms
npm install date-fns react-hook-form

# UI
npm install nativewind && npm install --save-dev tailwindcss

# Testing
npx expo install jest-expo && npm install --save-dev @testing-library/react-native
```

---

## Confidence Summary

| Area | Level | Reason |
|------|-------|--------|
| Expo scaffold | HIGH | Read directly from package.json |
| Supabase integration | HIGH | Stable, documented pattern |
| expo-notifications (local) | HIGH | Prescribed + Expo-native |
| Zustand v5 + TanStack Query v5 | MEDIUM-HIGH | Dominant community pattern, React 19 compatible |
| NativeWind v4 | MEDIUM | Newer; verify peer deps before install |
| date-fns v3 | HIGH | Stable, no native deps |

---

## Open Questions

1. NativeWind v4 + Expo 54 compatibility — verify before installing
2. Chart library selection — defer to trends phase
3. If v2 needs server-triggered nudges → research Expo Push Service + Supabase Edge Functions then
