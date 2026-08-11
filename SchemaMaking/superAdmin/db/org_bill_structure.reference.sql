-- Per-organization billing terms (post migration 016)

CREATE TABLE rms.org_bill_structure (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  subscription_plan_id  UUID NOT NULL REFERENCES subscription_plans(id),
  billing_cycle_id      UUID NOT NULL REFERENCES billing_cycles(id),
  state_id              UUID REFERENCES states(id),
  start_date            DATE NOT NULL,
  renewal_date          DATE NOT NULL,
  payment_method        VARCHAR(30) NOT NULL,
  commission_pct        DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
  platform_fee_amount   DECIMAL(12, 2),
  currency              VARCHAR(3) NOT NULL DEFAULT 'INR',
  auto_renew            BOOLEAN NOT NULL DEFAULT TRUE,
  grace_period_days     INT NOT NULL DEFAULT 7,
  free_usage_days       INT NOT NULL DEFAULT 0,
  last_payment_at       TIMESTAMPTZ,
  payment_reference     VARCHAR(100),
  status                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  notes                 TEXT,
  configured_by         UUID REFERENCES super_admin_users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
