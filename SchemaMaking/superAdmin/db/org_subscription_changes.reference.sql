-- Append-only subscription upgrade / downgrade history

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
