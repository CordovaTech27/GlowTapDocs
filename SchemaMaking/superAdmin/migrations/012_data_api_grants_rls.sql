-- Data API: grants + RLS for authenticated Neon Auth users
-- Run after enabling Neon Auth + Data API in the Neon Console.
-- WARNING: Any signed-in Neon Auth user can read/write these tables until
-- you add tighter policies (e.g. map auth.user_id() to super_admin_users).

GRANT USAGE ON SCHEMA public TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- super_admin_users
ALTER TABLE super_admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON super_admin_users
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- subscription_plans
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON subscription_plans
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- organizations
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON organizations
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- branches
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON branches
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);
