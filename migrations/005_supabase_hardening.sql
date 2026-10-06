-- =====================================================================
-- Supabase hardening migration (record of changes applied to my-skillbridge-db)
-- Covers: auth link, RLS + policies, timestamps, constraints, indexes,
--         views security_invoker, column-level privileges.
-- Safe to re-run: uses IF EXISTS / IF NOT EXISTS / guards where possible.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. users: link to Supabase Auth, remove password_hash
-- ---------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS auth_user_id UUID UNIQUE
  REFERENCES auth.users(id) ON DELETE SET NULL;

-- Views that depend on users.created_at must be dropped before the type change
DROP VIEW IF EXISTS public.active_users;
DROP VIEW IF EXISTS public.verified_users;

-- Supabase Auth handles passwords; do not store them here
ALTER TABLE public.users DROP COLUMN IF EXISTS password_hash;

-- ---------------------------------------------------------------------
-- 2. users: timestamps -> TIMESTAMPTZ (guarded so a re-run does not shift values)
-- ---------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users'
      AND column_name = 'created_at'
      AND data_type = 'timestamp without time zone'
  ) THEN
    ALTER TABLE public.users
      ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC',
      ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'UTC',
      ALTER COLUMN last_login TYPE TIMESTAMPTZ USING last_login AT TIME ZONE 'UTC';
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- 3. Recreate views, then set security_invoker on all 5 views
-- ---------------------------------------------------------------------
CREATE VIEW public.active_users AS
  SELECT user_id,
    username,
    email,
    role,
    created_at
  FROM users
  WHERE ((account_status)::text = 'ACTIVE'::text);

CREATE VIEW public.verified_users AS
  SELECT user_id,
    username,
    email,
    created_at
  FROM users
  WHERE ((is_verified = true) AND ((account_status)::text = 'ACTIVE'::text));

ALTER VIEW IF EXISTS public.active_users SET (security_invoker = true);
ALTER VIEW IF EXISTS public.verified_users SET (security_invoker = true);
ALTER VIEW IF EXISTS public.active_freelancers SET (security_invoker = true);
ALTER VIEW IF EXISTS public.active_freelancers_report SET (security_invoker = true);
ALTER VIEW IF EXISTS public.database_documentation SET (security_invoker = true);

-- ---------------------------------------------------------------------
-- 4. updated_at trigger on users
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS users_set_updated_at ON public.users;
CREATE TRIGGER users_set_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------
-- 5. RLS + policies
--    Ownership is resolved through users.auth_user_id = auth.uid()
-- ---------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own row" ON public.users;
CREATE POLICY "Users can view own row"
ON public.users FOR SELECT
USING (auth.uid() = auth_user_id);

DROP POLICY IF EXISTS "Users can update own row" ON public.users;
CREATE POLICY "Users can update own row"
ON public.users FOR UPDATE
USING (auth.uid() = auth_user_id)
WITH CHECK (auth.uid() = auth_user_id);

-- plans, premium_plans: pricing visible to everyone
DROP POLICY IF EXISTS "plans_public_read" ON public.plans;
CREATE POLICY "plans_public_read" ON public.plans
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "premium_plans_public_read" ON public.premium_plans;
CREATE POLICY "premium_plans_public_read" ON public.premium_plans
  FOR SELECT USING (true);

-- orders: client sees own orders
DROP POLICY IF EXISTS "Users view own orders" ON public.orders;
CREATE POLICY "Users view own orders" ON public.orders
  FOR SELECT TO authenticated
  USING (client_id = (SELECT u.user_id FROM public.users u
                      WHERE u.auth_user_id = (SELECT auth.uid())));

-- subscriptions / user_subscriptions: own rows only
DROP POLICY IF EXISTS "Users view own subscriptions" ON public.subscriptions;
CREATE POLICY "Users view own subscriptions" ON public.subscriptions
  FOR SELECT TO authenticated
  USING (user_id = (SELECT u.user_id FROM public.users u
                    WHERE u.auth_user_id = (SELECT auth.uid())));

DROP POLICY IF EXISTS "Users view own user_subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users view own user_subscriptions" ON public.user_subscriptions
  FOR SELECT TO authenticated
  USING (user_id = (SELECT u.user_id FROM public.users u
                    WHERE u.auth_user_id = (SELECT auth.uid())));

-- user_settings: own settings, read and write
DROP POLICY IF EXISTS "Users manage own settings" ON public.user_settings;
CREATE POLICY "Users manage own settings" ON public.user_settings
  FOR ALL TO authenticated
  USING (user_id = (SELECT u.user_id FROM public.users u
                    WHERE u.auth_user_id = (SELECT auth.uid())))
  WITH CHECK (user_id = (SELECT u.user_id FROM public.users u
                         WHERE u.auth_user_id = (SELECT auth.uid())));

-- payments: previous policy compared auth.uid() (uuid) with user_id (bigint); fixed
DROP POLICY IF EXISTS "Users view own payments" ON public.payments;
CREATE POLICY "Users view own payments" ON public.payments
  FOR SELECT TO authenticated
  USING (user_id = (SELECT u.user_id FROM public.users u
                    WHERE u.auth_user_id = (SELECT auth.uid())));

-- projects: same uuid/bigint fix (projects_public_read is left unchanged)
DROP POLICY IF EXISTS "Users manage own projects" ON public.projects;
CREATE POLICY "Users manage own projects" ON public.projects
  FOR ALL TO authenticated
  USING (user_id = (SELECT u.user_id FROM public.users u
                    WHERE u.auth_user_id = (SELECT auth.uid())))
  WITH CHECK (user_id = (SELECT u.user_id FROM public.users u
                         WHERE u.auth_user_id = (SELECT auth.uid())));

-- user_sessions: own sessions, read only
DROP POLICY IF EXISTS "Users view own sessions" ON public.user_sessions;
CREATE POLICY "Users view own sessions" ON public.user_sessions
  FOR SELECT TO authenticated
  USING (user_id = (SELECT u.user_id FROM public.users u
                    WHERE u.auth_user_id = (SELECT auth.uid())));

-- ---------------------------------------------------------------------
-- 6. Column-level privileges
--    RLS controls rows only, so columns are restricted with GRANT/REVOKE.
-- ---------------------------------------------------------------------
-- users: client can update profile-safe columns only
-- (role, account_status, auth_user_id, user_id, created_at, email,
--  is_verified, last_login are server-controlled)
REVOKE UPDATE ON public.users FROM anon, authenticated;
GRANT UPDATE (first_name, last_name, username, bio, profile_photo,
              phone, gender, date_of_birth)
ON public.users TO authenticated;

-- user_sessions: session_token is server-only; writes are server-only
REVOKE SELECT ON public.user_sessions FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.user_sessions FROM anon, authenticated;
GRANT SELECT (session_id, user_id, login_time, expires_at, is_active)
ON public.user_sessions TO authenticated;

-- ---------------------------------------------------------------------
-- 7. Constraints
-- ---------------------------------------------------------------------
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS chk_order_quantity_positive;
ALTER TABLE public.orders
  ADD CONSTRAINT chk_order_quantity_positive CHECK (quantity > 0);

ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_payment_status_check;
ALTER TABLE public.payments
  ADD CONSTRAINT payments_payment_status_check
  CHECK (payment_status IN ('PENDING', 'SUCCESS', 'FAILED'));

-- ---------------------------------------------------------------------
-- 8. Indexes: add missing FK indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id
  ON public.subscriptions (plan_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id
  ON public.user_subscriptions (plan_id);

CREATE INDEX IF NOT EXISTS idx_user_settings_user_id
  ON public.user_settings (user_id);
CREATE INDEX IF NOT EXISTS idx_password_resets_user_id
  ON public.password_resets (user_id);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user_id
  ON public.email_verifications (user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id
  ON public.user_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_user_id
  ON public.security_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_projects_user_id
  ON public.projects (user_id);

-- ---------------------------------------------------------------------
-- 9. Indexes: drop duplicates
--    orders: idx_orders_gig_id and idx_orders_client_id are kept
--    users: unique indexes (users_username_key, users_phone_key,
--           users_email_key) already cover these columns
-- ---------------------------------------------------------------------
DROP INDEX IF EXISTS public.idx_orders_gig;
DROP INDEX IF EXISTS public.idx_orders_client;
DROP INDEX IF EXISTS public.idx_users_username;
DROP INDEX IF EXISTS public.idx_users_phone;
DROP INDEX IF EXISTS public.idx_users_email;

COMMIT;
