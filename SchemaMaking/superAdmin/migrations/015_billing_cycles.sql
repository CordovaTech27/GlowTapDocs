-- Billing cycle master + FK on organizations

CREATE TABLE billing_cycles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code              VARCHAR(30) NOT NULL UNIQUE,
  name              VARCHAR(50) NOT NULL,
  description       TEXT,
  interval_months   INT NOT NULL CHECK (interval_months > 0),
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO billing_cycles (id, code, name, description, interval_months) VALUES
(
  'f1000000-0000-4000-8000-000000000001',
  'MONTHLY',
  'Monthly',
  'Billed every month.',
  1
),
(
  'f1000000-0000-4000-8000-000000000002',
  'QUARTERLY',
  'Quarterly',
  'Billed every 3 months.',
  3
),
(
  'f1000000-0000-4000-8000-000000000003',
  'HALF_YEARLY',
  'Half Yearly',
  'Billed every 6 months.',
  6
),
(
  'f1000000-0000-4000-8000-000000000004',
  'YEARLY',
  'Yearly',
  'Billed once a year.',
  12
)
ON CONFLICT (id) DO UPDATE SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  interval_months = EXCLUDED.interval_months,
  updated_at = NOW();

ALTER TABLE organizations
  ADD COLUMN billing_cycle_id UUID REFERENCES billing_cycles(id);

CREATE INDEX idx_organizations_billing_cycle_id ON organizations(billing_cycle_id);

-- Seed org billing cycles
UPDATE organizations SET billing_cycle_id = 'f1000000-0000-4000-8000-000000000001' WHERE slug = 'looks-salon-spa';
UPDATE organizations SET billing_cycle_id = 'f1000000-0000-4000-8000-000000000002' WHERE slug = 'glamour-zone';
UPDATE organizations SET billing_cycle_id = 'f1000000-0000-4000-8000-000000000003' WHERE slug = 'enrich-salon';
UPDATE organizations SET billing_cycle_id = 'f1000000-0000-4000-8000-000000000004' WHERE slug = 'naturals-salon-partners';
UPDATE organizations SET billing_cycle_id = 'f1000000-0000-4000-8000-000000000001' WHERE slug = 'blush-and-bloom';

ALTER TABLE billing_cycles ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON billing_cycles
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON billing_cycles TO authenticated;
