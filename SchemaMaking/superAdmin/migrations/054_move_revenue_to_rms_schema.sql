-- Move revenue / billing / marketplace settlement tables into schema `rms`
-- (Revenue Management System). Core identity stays in `public`.
-- Cross-schema FKs to public.organizations / branches / states / super_admin_users
-- are preserved by ALTER TABLE ... SET SCHEMA.

CREATE SCHEMA IF NOT EXISTS rms;

COMMENT ON SCHEMA rms IS
  'Revenue Management System — SaaS billing, invoices/payments, marketplace commission & payouts';

-- ---------------------------------------------------------------------------
-- Move tables (order does not matter for FKs; Postgres rewrites constraint defs)
-- ---------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.subscription_plans SET SCHEMA rms;
ALTER TABLE IF EXISTS public.billing_cycles SET SCHEMA rms;
ALTER TABLE IF EXISTS public.billing_discount_configs SET SCHEMA rms;
ALTER TABLE IF EXISTS public.state_tax_configs SET SCHEMA rms;
ALTER TABLE IF EXISTS public.org_bill_structure SET SCHEMA rms;
ALTER TABLE IF EXISTS public.org_subscription_changes SET SCHEMA rms;
ALTER TABLE IF EXISTS public.invoices SET SCHEMA rms;
ALTER TABLE IF EXISTS public.invoice_line_items SET SCHEMA rms;
ALTER TABLE IF EXISTS public.invoice_tax_lines SET SCHEMA rms;
ALTER TABLE IF EXISTS public.payments SET SCHEMA rms;
ALTER TABLE IF EXISTS public.invoice_payments SET SCHEMA rms;
ALTER TABLE IF EXISTS public.credit_notes SET SCHEMA rms;
ALTER TABLE IF EXISTS public.credit_note_line_items SET SCHEMA rms;
ALTER TABLE IF EXISTS public.refunds SET SCHEMA rms;
ALTER TABLE IF EXISTS public.platform_commission_config SET SCHEMA rms;
ALTER TABLE IF EXISTS public.commission_rate_history SET SCHEMA rms;
ALTER TABLE IF EXISTS public.org_merchant_balances SET SCHEMA rms;
ALTER TABLE IF EXISTS public.salon_payouts SET SCHEMA rms;
ALTER TABLE IF EXISTS public.end_user_transactions SET SCHEMA rms;
ALTER TABLE IF EXISTS public.salon_payout_items SET SCHEMA rms;
ALTER TABLE IF EXISTS public.merchant_ledger_entries SET SCHEMA rms;

-- ---------------------------------------------------------------------------
-- Data API / app roles: expose rms like public
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA rms TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA rms TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA rms
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA rms TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA rms
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- Optional convenience for SQL sessions (does not remove public)
-- Apps should prefer fully-qualified rms.* names.
