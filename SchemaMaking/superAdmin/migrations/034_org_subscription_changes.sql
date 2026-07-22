-- Append-only log of subscription plan upgrades / downgrades
-- Current plan stays on org_bill_structure; history is here (same pattern as org_status_actions)

CREATE TABLE org_subscription_changes (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  org_bill_structure_id       UUID NOT NULL REFERENCES org_bill_structure(id) ON DELETE CASCADE,
  change_type                 VARCHAR(20) NOT NULL
    CHECK (change_type IN ('UPGRADE', 'DOWNGRADE')),
  from_subscription_plan_id   UUID NOT NULL REFERENCES subscription_plans(id),
  to_subscription_plan_id     UUID NOT NULL REFERENCES subscription_plans(id),
  from_billing_cycle_id       UUID REFERENCES billing_cycles(id),
  to_billing_cycle_id         UUID REFERENCES billing_cycles(id),
  effective_date              DATE NOT NULL DEFAULT CURRENT_DATE,
  notes                       TEXT,
  performed_by                UUID REFERENCES super_admin_users(id),
  performed_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (from_subscription_plan_id <> to_subscription_plan_id)
);

CREATE INDEX idx_org_subscription_changes_org
  ON org_subscription_changes(organization_id, performed_at DESC);
CREATE INDEX idx_org_subscription_changes_bill
  ON org_subscription_changes(org_bill_structure_id, performed_at DESC);
CREATE INDEX idx_org_subscription_changes_type
  ON org_subscription_changes(change_type, performed_at DESC);

-- Demo: Looks Salon & Spa upgraded Starter → Growth (current plan on bill structure)
INSERT INTO org_subscription_changes (
  id,
  organization_id,
  org_bill_structure_id,
  change_type,
  from_subscription_plan_id,
  to_subscription_plan_id,
  from_billing_cycle_id,
  to_billing_cycle_id,
  effective_date,
  notes,
  performed_by,
  performed_at
)
SELECT
  'c3000000-0000-4000-8000-000000000001',
  obs.organization_id,
  obs.id,
  'UPGRADE',
  'd1000000-0000-4000-8000-000000000001', -- Starter
  obs.subscription_plan_id,               -- Growth (current)
  obs.billing_cycle_id,
  obs.billing_cycle_id,
  (CURRENT_DATE - INTERVAL '45 days')::date,
  'Upgraded to Growth to allow additional branch (Powai).',
  'a1000000-0000-4000-8000-000000000001',
  NOW() - INTERVAL '45 days'
FROM org_bill_structure obs
WHERE obs.organization_id = 'b1000000-0000-4000-8000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM org_subscription_changes
    WHERE id = 'c3000000-0000-4000-8000-000000000001'
  );

ALTER TABLE org_subscription_changes ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON org_subscription_changes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON org_subscription_changes TO authenticated;
