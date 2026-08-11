-- subscription_plans + org_subscription_changes → schema `subscription`
-- platform_commission_config → public (platform defaults, not RMS settlement ledger)

CREATE SCHEMA IF NOT EXISTS subscription;

COMMENT ON SCHEMA subscription IS
  'SaaS subscription plans and org plan-change history';

ALTER TABLE IF EXISTS rms.subscription_plans SET SCHEMA subscription;
ALTER TABLE IF EXISTS rms.org_subscription_changes SET SCHEMA subscription;

ALTER TABLE IF EXISTS rms.platform_commission_config SET SCHEMA public;

GRANT USAGE ON SCHEMA subscription TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA subscription TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA subscription
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA subscription TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA subscription
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.platform_commission_config TO authenticated;
