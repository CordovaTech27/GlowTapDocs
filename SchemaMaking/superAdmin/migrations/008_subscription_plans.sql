-- Subscription plans catalog + link organizations via FK

CREATE TABLE subscription_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(100) NOT NULL,
  description     TEXT,
  max_branches    INT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO subscription_plans (id, name, description, max_branches) VALUES
(
  'd1000000-0000-4000-8000-000000000001',
  'Starter',
  'Single-location salon. 1 branch included.',
  1
),
(
  'd1000000-0000-4000-8000-000000000002',
  'Growth',
  'Small multi-location chain. Up to 3 branches.',
  3
),
(
  'd1000000-0000-4000-8000-000000000003',
  'Professional',
  'Mid-size salon chain. Up to 10 branches.',
  10
),
(
  'd1000000-0000-4000-8000-000000000004',
  'Enterprise',
  'Large franchise or national chain. Unlimited branches.',
  999
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  max_branches = EXCLUDED.max_branches,
  updated_at = NOW();

ALTER TABLE organizations
  ADD COLUMN subscription_plan_id UUID REFERENCES subscription_plans(id);

UPDATE organizations SET subscription_plan_id = 'd1000000-0000-4000-8000-000000000001'
  WHERE subscription_plan = 'STARTER_1M';

UPDATE organizations SET subscription_plan_id = 'd1000000-0000-4000-8000-000000000002'
  WHERE subscription_plan = 'GROWTH_6M';

UPDATE organizations SET subscription_plan_id = 'd1000000-0000-4000-8000-000000000003'
  WHERE subscription_plan = 'PRO_12M';

UPDATE organizations SET subscription_plan_id = 'd1000000-0000-4000-8000-000000000004'
  WHERE subscription_plan = 'ENTERPRISE_24M';

ALTER TABLE organizations DROP COLUMN IF EXISTS subscription_plan;
ALTER TABLE organizations DROP COLUMN IF EXISTS max_branches;

CREATE INDEX idx_organizations_subscription_plan ON organizations(subscription_plan_id);
