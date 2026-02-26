---
phase: 01-foundation
plan: 01
subsystem: infra
tags: [supabase, async-storage, url-polyfill, zustand, react-query, nativewind, tailwindcss, expo]

# Dependency graph
requires: []
provides:
  - Supabase client singleton (lib/supabase.ts) with AsyncStorage session persistence
  - react-native-url-polyfill wired as first import in app/_layout.tsx
  - All Phase 1 dependencies installed (zustand, react-query, date-fns, react-hook-form, nativewind)
  - NativeWind + Tailwind configured (tailwind.config.js, babel.config.js)
  - .env with real Supabase credentials excluded from git
affects: [01-02, 01-03, 02-auth, 03-onboarding, 04-reminders]

# Tech tracking
tech-stack:
  added:
    - "@supabase/supabase-js ^2.98.0"
    - "@react-native-async-storage/async-storage 2.2.0"
    - "react-native-url-polyfill ^3.0.0"
    - "zustand ^5.0.11"
    - "@tanstack/react-query ^5.90.21"
    - "date-fns ^4.1.0"
    - "react-hook-form ^7.71.2"
    - "nativewind ^4.2.2"
    - "tailwindcss ^3.4.19 (devDep)"
  patterns:
    - "Supabase client as singleton exported from lib/supabase.ts"
    - "URL polyfill as absolute first import in root layout"
    - "Env vars via EXPO_PUBLIC_ prefix for Expo client access"

key-files:
  created:
    - lib/supabase.ts
    - tailwind.config.js
    - babel.config.js
  modified:
    - app/_layout.tsx
    - package.json
    - .gitignore

key-decisions:
  - "NativeWind v4 installed successfully — compatible with Expo 54 / RN 0.81 (peer deps only require tailwindcss >3.3.0)"
  - "react-native-url-polyfill/auto placed as absolute first import in app/_layout.tsx before any navigation/theme imports"
  - "Supabase client configured with detectSessionInUrl: false (required for React Native, prevents URL parsing errors)"
  - ".env already contained real Supabase credentials from project setup — no placeholder values needed"

patterns-established:
  - "Supabase singleton: import { supabase } from '@/lib/supabase' for all auth and data operations"
  - "Env validation: throw Error at module load if required vars are missing (fail fast)"

requirements-completed: [AUTH-02]

# Metrics
duration: 8min
completed: 2026-02-26
---

# Phase 1 Plan 01: Dependency Installation and Supabase Client Setup Summary

**Supabase client singleton with AsyncStorage session persistence, react-native-url-polyfill as first import, NativeWind v4 configured, and all Phase 1 dependencies installed**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-02-26T15:08:47Z
- **Completed:** 2026-02-26T15:17:00Z
- **Tasks:** 2 of 3 (Task 3 is a human-verify checkpoint — awaiting user confirmation)
- **Files modified:** 6

## Accomplishments
- Installed all Phase 1 packages: async-storage, url-polyfill, zustand, react-query, date-fns, react-hook-form, nativewind + tailwindcss
- Created lib/supabase.ts with correct React Native auth settings (AsyncStorage, detectSessionInUrl: false, persistSession: true)
- Rewrote app/_layout.tsx with URL polyfill as absolute first import and added (auth)/(onboarding) Stack routes
- Created tailwind.config.js with nativewind/preset and primary brand color (#0a7ea4)
- Created babel.config.js with nativewind Babel preset for Tailwind class support

## Task Commits

Each task was committed atomically:

1. **Task 1: Install dependencies and configure environment** - `f39964a` (chore)
2. **Task 2: Create Supabase client singleton and wire URL polyfill** - `3c7c4fa` (feat)
3. **Task 3: Verify setup** — checkpoint:human-verify (not yet committed — awaiting user verification)

**Plan metadata:** (pending final docs commit after checkpoint approval)

## Files Created/Modified
- `lib/supabase.ts` - Supabase client singleton with AsyncStorage adapter, detectSessionInUrl: false
- `app/_layout.tsx` - Root layout with URL polyfill as first import, (auth) and (onboarding) routes added
- `tailwind.config.js` - NativeWind v4 preset config with primary color extension
- `babel.config.js` - Expo babel config with nativewind/babel preset
- `package.json` - All Phase 1 dependencies added
- `.gitignore` - Ensured .env* pattern covers all .env variants

## Decisions Made

**NativeWind: Installed (not skipped)**
NativeWind v4 peer dependencies only require `tailwindcss >3.3.0` — no React Native version constraint. The project uses RN 0.81.5 which is fully compatible. Installed nativewind@4.2.2 with tailwindcss@3.4.19.

**URL polyfill placement: Confirmed correct**
`import 'react-native-url-polyfill/auto'` is the absolute first import in app/_layout.tsx, before all navigation and theme imports.

**Env handling: Real credentials already present**
The .env file already contained real Supabase credentials from prior project setup. The .gitignore already had `.env*.local` and was updated to also include `.env*` to ensure all variants are excluded.

## Deviations from Plan

None - plan executed exactly as written. NativeWind was compatible and installed without issues.

## Issues Encountered

The plan's automated verify command for `react-native-url-polyfill` uses `node -e "require(...)"` which fails with Node.js v22 because the package uses ESM imports that reference React Native internals. This is expected behavior — the package is designed for Metro bundler (React Native), not Node.js. The package directory exists in node_modules and functions correctly in the Expo/Metro context.

## User Setup Required

**Task 3 is a human-verify checkpoint that requires:**
1. Open `.env` at the project root — confirm real Supabase credentials are present (URL and ANON_KEY)
2. Run: `npx expo start` from the project directory
3. Confirm the app launches without "URL is not a constructor" or AsyncStorage errors
4. Confirm `git status` does NOT show `.env` as an untracked file

The .env already contains real credentials (EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY). The anon key is safe to use in the mobile client. Do NOT use the service_role key.

## Next Phase Readiness
- Supabase client ready for auth operations (Plans 01-02, 01-03)
- All dependencies available for state management (zustand), data fetching (react-query), forms (react-hook-form)
- NativeWind available for Tailwind-based styling throughout the app
- Task 3 checkpoint required before proceeding to Plan 02

---
*Phase: 01-foundation*
*Completed: 2026-02-26*
