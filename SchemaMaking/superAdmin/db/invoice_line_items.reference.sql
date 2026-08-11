CREATE TABLE rms.invoice_line_items (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id           UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  line_type            VARCHAR(20) NOT NULL,
  description          VARCHAR(255) NOT NULL,
  subscription_plan_id UUID REFERENCES subscription_plans(id),
  billing_cycle_id     UUID REFERENCES billing_cycles(id),
  quantity             DECIMAL(12, 2) NOT NULL DEFAULT 1,
  unit_amount          DECIMAL(12, 2) NOT NULL DEFAULT 0,
  amount               DECIMAL(12, 2) NOT NULL DEFAULT 0,
  discount_amount      DECIMAL(12, 2) NOT NULL DEFAULT 0,
  taxable_amount       DECIMAL(12, 2) NOT NULL DEFAULT 0,
  sort_order           INT NOT NULL DEFAULT 0,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
