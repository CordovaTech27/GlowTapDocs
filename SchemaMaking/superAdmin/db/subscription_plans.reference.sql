-- Schema subscription — SaaS plans + org plan-change history

CREATE TABLE subscription.subscription_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(100) NOT NULL,
  description     TEXT,
  max_branches    INT NOT NULL,
  amount          DECIMAL(12, 2) NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- List price is monthly INR. Feature matrix lives in description JSON:
-- {
--   "tagline": "...",
--   "billing": "₹999/month",
--   "features": [
--     { "name": "Revenue Dashboard", "desc": "...", "isAllowed": true }
--   ]
-- }

COMMENT ON COLUMN subscription.subscription_plans.description IS
  'JSON: tagline, billing label, features[] with { name, desc, isAllowed }';

COMMENT ON COLUMN subscription.subscription_plans.max_branches IS
  'Hard branch cap. Growth = 5 (multi-branch dashboard). Pro = 999 (unlimited).';

COMMENT ON COLUMN subscription.subscription_plans.amount IS
  'Monthly list price in INR (Basic 999, Growth 2999, Pro 4999).';
