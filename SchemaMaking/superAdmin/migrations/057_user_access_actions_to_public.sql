-- user_access_actions is shared audit (Super Admin + Salon Admin targets)
-- Keep it in public; Sub Admin entity tables stay in admin_org.

ALTER TABLE IF EXISTS admin_org.user_access_actions SET SCHEMA public;

-- Ensure Data API grants still apply (table may have moved with admin_org grants)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_access_actions TO authenticated;
