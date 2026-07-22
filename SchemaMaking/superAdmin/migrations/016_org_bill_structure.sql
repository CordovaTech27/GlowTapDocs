-- Org billing terms: plan, cycle, dates, payment — moved off organizations

CREATE TABLE org_bill_structure (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  subscription_plan_id  UUID NOT NULL REFERENCES subscription_plans(id),
  billing_cycle_id      UUID NOT NULL REFERENCES billing_cycles(id),
  start_date            DATE NOT NULL,
  renewal_date          DATE NOT NULL,
  payment_method        VARCHAR(30) NOT NULL
    CHECK (payment_method IN (
      'BANK_TRANSFER', 'UPI', 'CARD', 'NET_BANKING', 'NACH', 'CHEQUE', 'OTHER'
    )),
  commission_pct        DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
  platform_fee_amount   DECIMAL(12, 2),
  currency              VARCHAR(3) NOT NULL DEFAULT 'INR',
  auto_renew            BOOLEAN NOT NULL DEFAULT TRUE,
  grace_period_days     INT NOT NULL DEFAULT 7 CHECK (grace_period_days >= 0),
  last_payment_at       TIMESTAMPTZ,
  payment_reference     VARCHAR(100),
  status                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'CANCELLED', 'EXPIRED')),
  notes                 TEXT,
  configured_by         UUID REFERENCES super_admin_users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (renewal_date >= start_date)
);

CREATE UNIQUE INDEX idx_one_active_bill_structure_per_org
  ON org_bill_structure(organization_id)
  WHERE status = 'ACTIVE';

CREATE INDEX idx_org_bill_structure_org_id ON org_bill_structure(organization_id);
CREATE INDEX idx_org_bill_structure_renewal_date ON org_bill_structure(renewal_date);
CREATE INDEX idx_org_bill_structure_status ON org_bill_structure(status);

-- Migrate existing org plan / cycle / commission into bill structure
INSERT INTO org_bill_structure (
  organization_id,
  subscription_plan_id,
  billing_cycle_id,
  start_date,
  renewal_date,
  payment_method,
  commission_pct,
  platform_fee_amount,
  auto_renew,
  status,
  configured_by,
  last_payment_at
)
SELECT
  o.id,
  o.subscription_plan_id,
  o.billing_cycle_id,
  COALESCE(o.onboarded_at, o.approved_at, o.created_at)::date,
  (
    COALESCE(o.onboarded_at, o.approved_at, o.created_at)::date
    + (bc.interval_months || ' months')::interval
  )::date,
  CASE o.slug
    WHEN 'looks-salon-spa' THEN 'NACH'
    WHEN 'glamour-zone' THEN 'BANK_TRANSFER'
    WHEN 'enrich-salon' THEN 'UPI'
    WHEN 'naturals-salon-partners' THEN 'NACH'
    WHEN 'blush-and-bloom' THEN 'UPI'
    ELSE 'BANK_TRANSFER'
  END,
  o.commission_pct,
  CASE sp.name
    WHEN 'Starter' THEN 999.00
    WHEN 'Growth' THEN 2499.00
    WHEN 'Professional' THEN 4999.00
    WHEN 'Enterprise' THEN 9999.00
    ELSE NULL
  END,
  CASE WHEN o.status IN ('ACTIVE', 'PENDING') THEN TRUE ELSE FALSE END,
  CASE
    WHEN o.status = 'ACTIVE' THEN 'ACTIVE'
    WHEN o.status = 'PENDING' THEN 'PENDING'
    ELSE 'SUSPENDED'
  END,
  o.approved_by,
  CASE WHEN o.status = 'ACTIVE' THEN o.onboarded_at ELSE NULL END
FROM organizations o
JOIN billing_cycles bc ON bc.id = o.billing_cycle_id
JOIN subscription_plans sp ON sp.id = o.subscription_plan_id
WHERE o.subscription_plan_id IS NOT NULL
  AND o.billing_cycle_id IS NOT NULL;

ALTER TABLE organizations
  DROP COLUMN IF EXISTS subscription_plan_id,
  DROP COLUMN IF EXISTS billing_cycle_id,
  DROP COLUMN IF EXISTS commission_pct;

DROP INDEX IF EXISTS idx_organizations_subscription_plan;
DROP INDEX IF EXISTS idx_organizations_billing_cycle_id;

ALTER TABLE org_bill_structure ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON org_bill_structure
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON org_bill_structure TO authenticated;
