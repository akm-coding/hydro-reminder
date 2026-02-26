-- ============================================================
-- Phase 1 Foundation Migration
-- Apply via Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. profiles table
-- Extends auth.users. One row per user. Created automatically via trigger.
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_goal_ml INT NOT NULL DEFAULT 2000,
  unit_pref     TEXT NOT NULL DEFAULT 'ml' CHECK (unit_pref IN ('ml', 'oz')),
  onboarding_complete BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. drink_logs table
-- One row per drink event. amount_ml is always stored in ml.
CREATE TABLE IF NOT EXISTS public.drink_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount_ml  INT NOT NULL CHECK (amount_ml > 0),
  local_date TEXT NOT NULL,  -- 'yyyy-MM-dd' in device local time, avoids UTC boundary bugs
  logged_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_drink_logs_user_date
  ON public.drink_logs (user_id, logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_drink_logs_user_local_date
  ON public.drink_logs (user_id, local_date DESC);

-- 3. reminder_schedules table
-- One row per user-defined reminder time. hour/minute (not UTC timestamps).
CREATE TABLE IF NOT EXISTS public.reminder_schedules (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  hour       SMALLINT NOT NULL CHECK (hour BETWEEN 0 AND 23),
  minute     SMALLINT NOT NULL CHECK (minute BETWEEN 0 AND 59),
  enabled    BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reminder_unique_time
  ON public.reminder_schedules (user_id, hour, minute);

-- 4. user_settings table
-- Per-user settings including push token, notification toggle.
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id        UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_token     TEXT,
  notif_enabled  BOOLEAN NOT NULL DEFAULT true,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Row Level Security
-- CRITICAL: Enable before any INSERT or data is permanently exposed
-- ============================================================
ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drink_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings      ENABLE ROW LEVEL SECURITY;

-- Owner-only policies: users can only read/write their own rows
CREATE POLICY "profiles_owner"
  ON public.profiles FOR ALL USING (id = auth.uid());

CREATE POLICY "drink_logs_owner"
  ON public.drink_logs FOR ALL USING (user_id = auth.uid());

CREATE POLICY "reminders_owner"
  ON public.reminder_schedules FOR ALL USING (user_id = auth.uid());

CREATE POLICY "settings_owner"
  ON public.user_settings FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- Auto-provision profile + settings on signup
-- CRITICAL: Without this trigger, new users have no profile row
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Drop and recreate trigger to ensure idempotency
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
