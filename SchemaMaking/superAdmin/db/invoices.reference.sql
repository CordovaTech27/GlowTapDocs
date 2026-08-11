-- Salon → GlowTap subscription invoices

CREATE TABLE rms.invoices (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id            UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  org_bill_structure_id      UUID REFERENCES org_bill_structure(id) ON DELETE SET NULL,
  invoice_number             VARCHAR(50) NOT NULL UNIQUE,
  invoice_type               VARCHAR(20) NOT NULL,
  status                     VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  currency                   VARCHAR(3) NOT NULL DEFAULT 'INR',
  subtotal_amount            DECIMAL(12, 2) NOT NULL DEFAULT 0,
  discount_amount            DECIMAL(12, 2) NOT NULL DEFAULT 0,
  taxable_amount             DECIMAL(12, 2) NOT NULL DEFAULT 0,
  tax_amount                 DECIMAL(12, 2) NOT NULL DEFAULT 0,
  total_amount               DECIMAL(12, 2) NOT NULL DEFAULT 0,
  amount_paid                DECIMAL(12, 2) NOT NULL DEFAULT 0,
  amount_due                 DECIMAL(12, 2) NOT NULL DEFAULT 0,
  billing_period_start       DATE,
  billing_period_end         DATE,
  issue_date                 DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date                   DATE,
  paid_at                    TIMESTAMPTZ,
  pdf_url                    TEXT,
  notes                      TEXT,
  org_subscription_change_id UUID REFERENCES org_subscription_changes(id) ON DELETE SET NULL,
  created_by                 UUID REFERENCES super_admin_users(id),
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
