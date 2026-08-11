-- Schema subscription — append-only upgrade / downgrade history
-- FKs → public.organizations, rms.org_bill_structure, subscription.subscription_plans, rms.billing_cycles

CREATE TABLE subscription.org_subscription_changes (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  org_bill_structure_id       UUID NOT NULL REFERENCES rms.org_bill_structure(id) ON DELETE CASCADE,
  change_type                 VARCHAR(20) NOT NULL
    CHECK (change_type IN ('UPGRADE', 'DOWNGRADE')),
  from_subscription_plan_id   UUID NOT NULL REFERENCES subscription.subscription_plans(id),
  to_subscription_plan_id     UUID NOT NULL REFERENCES subscription.subscription_plans(id),
  from_billing_cycle_id       UUID REFERENCES rms.billing_cycles(id),
  to_billing_cycle_id         UUID REFERENCES rms.billing_cycles(id),
  effective_date              DATE NOT NULL DEFAULT CURRENT_DATE,
  notes                       TEXT,
  performed_by                UUID REFERENCES public.super_admin_users(id),
  performed_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
