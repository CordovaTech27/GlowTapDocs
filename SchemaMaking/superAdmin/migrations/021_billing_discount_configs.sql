-- Discount rules: plan + billing cycle → % off or fixed amount off

CREATE TABLE billing_discount_configs (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                    VARCHAR(100) NOT NULL,
  subscription_plan_id    UUID REFERENCES subscription_plans(id) ON DELETE CASCADE,
  billing_cycle_id        UUID REFERENCES billing_cycles(id) ON DELETE CASCADE,
  discount_type           VARCHAR(20) NOT NULL
    CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT')),
  discount_value          DECIMAL(12, 2) NOT NULL
    CHECK (discount_value > 0),
  priority                INT NOT NULL DEFAULT 100,
  is_stackable            BOOLEAN NOT NULL DEFAULT FALSE,
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  effective_from          DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_to            DATE,
  notes                   TEXT,
  created_by              UUID REFERENCES super_admin_users(id),
  updated_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CHECK (
    (discount_type = 'PERCENTAGE' AND discount_value <= 100)
    OR discount_type = 'FIXED_AMOUNT'
  ),
  CHECK (
    subscription_plan_id IS NOT NULL OR billing_cycle_id IS NOT NULL
  )
);

CREATE INDEX idx_billing_discount_configs_plan
  ON billing_discount_configs(subscription_plan_id);
CREATE INDEX idx_billing_discount_configs_cycle
  ON billing_discount_configs(billing_cycle_id);
CREATE INDEX idx_billing_discount_configs_active
  ON billing_discount_configs(is_active, priority)
  WHERE is_active = TRUE;

-- Seed samples (plan IDs d100..., cycle IDs f100...)
INSERT INTO billing_discount_configs (
  id, name, subscription_plan_id, billing_cycle_id,
  discount_type, discount_value, priority, notes, created_by
) VALUES
(
  'c1000000-0000-4000-8000-000000000001',
  'Yearly — 10% off all plans',
  NULL,
  'f1000000-0000-4000-8000-000000000004',
  'PERCENTAGE',
  10.00,
  100,
  'Any plan billed yearly gets 10% off catalog amount.',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000002',
  'Half Yearly — 5% off all plans',
  NULL,
  'f1000000-0000-4000-8000-000000000003',
  'PERCENTAGE',
  5.00,
  100,
  'Any plan billed half-yearly gets 5% off.',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000003',
  'Growth Yearly — extra ₹500 off',
  'd1000000-0000-4000-8000-000000000002',
  'f1000000-0000-4000-8000-000000000004',
  'FIXED_AMOUNT',
  500.00,
  50,
  'Growth + Yearly flat ₹500 off (higher priority than generic yearly %).',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000004',
  'Enterprise Yearly — ₹1,000 off',
  'd1000000-0000-4000-8000-000000000004',
  'f1000000-0000-4000-8000-000000000004',
  'FIXED_AMOUNT',
  1000.00,
  50,
  'Enterprise + Yearly flat ₹1,000 off.',
  'a1000000-0000-4000-8000-000000000001'
);

ALTER TABLE billing_discount_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON billing_discount_configs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON billing_discount_configs TO authenticated;
