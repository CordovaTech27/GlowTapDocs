-- Subscription billing ledger (salon → GlowTap)
-- Pattern: Stripe/Chargebee invoice + payment objects, with Indian GST tax lines
-- Current commercial terms stay on org_bill_structure; money documents live here.

-- ---------------------------------------------------------------------------
-- Invoices
-- ---------------------------------------------------------------------------
CREATE TABLE invoices (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  org_bill_structure_id   UUID REFERENCES org_bill_structure(id) ON DELETE SET NULL,
  invoice_number          VARCHAR(50) NOT NULL UNIQUE,
  invoice_type            VARCHAR(20) NOT NULL
    CHECK (invoice_type IN (
      'PURCHASE', 'RENEWAL', 'UPGRADE', 'DOWNGRADE', 'CREDIT', 'MANUAL', 'ADJUSTMENT'
    )),
  status                  VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN (
      'DRAFT', 'OPEN', 'PAID', 'PARTIALLY_PAID', 'VOID', 'UNCOLLECTIBLE'
    )),
  currency                VARCHAR(3) NOT NULL DEFAULT 'INR',
  subtotal_amount         DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (subtotal_amount >= 0),
  discount_amount         DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (discount_amount >= 0),
  taxable_amount          DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (taxable_amount >= 0),
  tax_amount              DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (tax_amount >= 0),
  total_amount            DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (total_amount >= 0),
  amount_paid             DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (amount_paid >= 0),
  amount_due              DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (amount_due >= 0),
  billing_period_start    DATE,
  billing_period_end      DATE,
  issue_date              DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date                DATE,
  paid_at                 TIMESTAMPTZ,
  pdf_url                 TEXT,
  notes                   TEXT,
  org_subscription_change_id UUID REFERENCES org_subscription_changes(id) ON DELETE SET NULL,
  created_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (amount_paid + amount_due = total_amount OR status IN ('DRAFT', 'VOID'))
);

CREATE INDEX idx_invoices_org ON invoices(organization_id, issue_date DESC);
CREATE INDEX idx_invoices_status ON invoices(status, due_date);
CREATE INDEX idx_invoices_bill ON invoices(org_bill_structure_id);

-- ---------------------------------------------------------------------------
-- Invoice line items
-- ---------------------------------------------------------------------------
CREATE TABLE invoice_line_items (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id              UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  line_type               VARCHAR(20) NOT NULL
    CHECK (line_type IN (
      'PLAN', 'DISCOUNT', 'PRORATION', 'FEE', 'CREDIT', 'TAX', 'ADJUSTMENT'
    )),
  description             VARCHAR(255) NOT NULL,
  subscription_plan_id    UUID REFERENCES subscription_plans(id),
  billing_cycle_id        UUID REFERENCES billing_cycles(id),
  quantity                DECIMAL(12, 2) NOT NULL DEFAULT 1
    CHECK (quantity > 0),
  unit_amount             DECIMAL(12, 2) NOT NULL DEFAULT 0,
  amount                  DECIMAL(12, 2) NOT NULL DEFAULT 0,
  discount_amount         DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (discount_amount >= 0),
  taxable_amount          DECIMAL(12, 2) NOT NULL DEFAULT 0,
  sort_order              INT NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoice_line_items_invoice ON invoice_line_items(invoice_id, sort_order);

-- ---------------------------------------------------------------------------
-- Invoice tax lines (CGST / SGST / IGST — Chargebee/Zoho-style GST break-up)
-- ---------------------------------------------------------------------------
CREATE TABLE invoice_tax_lines (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_line_item_id UUID NOT NULL REFERENCES invoice_line_items(id) ON DELETE CASCADE,
  state_tax_config_id  UUID NOT NULL REFERENCES state_tax_configs(id),
  taxable_amount       DECIMAL(12, 2) NOT NULL
    CHECK (taxable_amount >= 0),
  tax_amount           DECIMAL(12, 2) NOT NULL
    CHECK (tax_amount >= 0),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoice_tax_lines_line ON invoice_tax_lines(invoice_line_item_id);

-- ---------------------------------------------------------------------------
-- Payments (gateway attempts — Stripe PaymentIntent / Razorpay Payment style)
-- ---------------------------------------------------------------------------
CREATE TABLE payments (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  payment_number          VARCHAR(50) NOT NULL UNIQUE,
  amount                  DECIMAL(12, 2) NOT NULL
    CHECK (amount > 0),
  currency                VARCHAR(3) NOT NULL DEFAULT 'INR',
  status                  VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN (
      'PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED',
      'CANCELLED', 'REFUNDED', 'PARTIALLY_REFUNDED'
    )),
  payment_method          VARCHAR(30) NOT NULL
    CHECK (payment_method IN (
      'NACH', 'UPI', 'CARD', 'NET_BANKING', 'BANK_TRANSFER', 'CHEQUE', 'OTHER'
    )),
  gateway                 VARCHAR(30) NOT NULL DEFAULT 'MANUAL'
    CHECK (gateway IN ('RAZORPAY', 'STRIPE', 'CASHFREE', 'MANUAL', 'OTHER')),
  gateway_order_id        VARCHAR(100),
  gateway_payment_id      VARCHAR(100),
  gateway_ref             VARCHAR(255),
  failure_code            VARCHAR(50),
  failure_message         TEXT,
  initiated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at                 TIMESTAMPTZ,
  notes                   TEXT,
  created_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_org ON payments(organization_id, initiated_at DESC);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_gateway_payment ON payments(gateway_payment_id)
  WHERE gateway_payment_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Invoice ↔ Payment allocations (supports partial / multi-invoice payments)
-- ---------------------------------------------------------------------------
CREATE TABLE invoice_payments (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id              UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  payment_id              UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  amount_applied          DECIMAL(12, 2) NOT NULL
    CHECK (amount_applied > 0),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (invoice_id, payment_id)
);

CREATE INDEX idx_invoice_payments_payment ON invoice_payments(payment_id);

-- ---------------------------------------------------------------------------
-- Credit notes (against an invoice — SaaS standard for refunds/credits)
-- ---------------------------------------------------------------------------
CREATE TABLE credit_notes (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id              UUID NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
  credit_note_number      VARCHAR(50) NOT NULL UNIQUE,
  status                  VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT', 'ISSUED', 'VOID')),
  reason                  TEXT,
  subtotal_amount         DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (subtotal_amount >= 0),
  tax_amount              DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (tax_amount >= 0),
  total_amount            DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (total_amount >= 0),
  pdf_url                 TEXT,
  issued_at               TIMESTAMPTZ,
  created_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_credit_notes_invoice ON credit_notes(invoice_id, created_at DESC);

CREATE TABLE credit_note_line_items (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  credit_note_id          UUID NOT NULL REFERENCES credit_notes(id) ON DELETE CASCADE,
  invoice_line_item_id    UUID REFERENCES invoice_line_items(id) ON DELETE SET NULL,
  description             VARCHAR(255) NOT NULL,
  amount                  DECIMAL(12, 2) NOT NULL DEFAULT 0,
  tax_amount              DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (tax_amount >= 0),
  sort_order              INT NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_credit_note_line_items_cn ON credit_note_line_items(credit_note_id, sort_order);

-- ---------------------------------------------------------------------------
-- Refunds (money returned against a successful payment)
-- ---------------------------------------------------------------------------
CREATE TABLE refunds (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id              UUID NOT NULL REFERENCES payments(id) ON DELETE RESTRICT,
  credit_note_id          UUID REFERENCES credit_notes(id) ON DELETE SET NULL,
  amount                  DECIMAL(12, 2) NOT NULL
    CHECK (amount > 0),
  status                  VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
  gateway_refund_id       VARCHAR(100),
  reason                  TEXT,
  refunded_at             TIMESTAMPTZ,
  created_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refunds_payment ON refunds(payment_id);

-- ---------------------------------------------------------------------------
-- Seed: Looks Salon & Spa — paid monthly Growth renewal invoice + payment
-- Taxable ₹2,499 | CGST 9% ₹224.91 | SGST 9% ₹224.91 | Total ₹2,948.82
-- ---------------------------------------------------------------------------
INSERT INTO invoices (
  id, organization_id, org_bill_structure_id, invoice_number, invoice_type, status,
  currency, subtotal_amount, discount_amount, taxable_amount, tax_amount, total_amount,
  amount_paid, amount_due,
  billing_period_start, billing_period_end, issue_date, due_date, paid_at,
  notes, org_subscription_change_id, created_by
) VALUES (
  'e2000000-0000-4000-8000-000000000001',
  'b1000000-0000-4000-8000-000000000001',
  '44c60fc0-7ac4-406d-bd99-6b1cfe6d910b',
  'GT-INV-2026-00001',
  'RENEWAL',
  'PAID',
  'INR',
  2499.00,
  0.00,
  2499.00,
  449.82,
  2948.82,
  2948.82,
  0.00,
  DATE '2026-06-01',
  DATE '2026-06-30',
  DATE '2026-06-01',
  DATE '2026-06-07',
  TIMESTAMPTZ '2026-06-01 10:15:00+05:30',
  'Monthly Growth renewal — Maharashtra intra-state GST.',
  NULL,
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO invoice_line_items (
  id, invoice_id, line_type, description,
  subscription_plan_id, billing_cycle_id,
  quantity, unit_amount, amount, discount_amount, taxable_amount,
  sort_order
) VALUES (
  'e2000000-0000-4000-8000-000000000011',
  'e2000000-0000-4000-8000-000000000001',
  'PLAN',
  'GlowTap Growth — Monthly subscription',
  'd1000000-0000-4000-8000-000000000002',
  'f1000000-0000-4000-8000-000000000001',
  1,
  2499.00,
  2499.00,
  0.00,
  2499.00,
  10
);

-- Platform SaaS GST for Maharashtra (used by invoice_tax_lines FK)
INSERT INTO state_tax_configs (
  id, state_id, tax_code, tax_name, rate_pct, hsn_sac_code,
  component_type, applies_to, effective_from, is_active, notes, created_by
) VALUES
(
  'e3000000-0000-4000-8000-000000000001',
  'e1000000-0000-4000-8000-000000000027',
  'CGST_SAAS',
  'CGST on platform subscription',
  9.00,
  '998314',
  'CGST',
  'SERVICE',
  DATE '2024-01-01',
  TRUE,
  'GlowTap SaaS / platform fee — intra-state',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'e3000000-0000-4000-8000-000000000002',
  'e1000000-0000-4000-8000-000000000027',
  'SGST_SAAS',
  'SGST on platform subscription',
  9.00,
  '998314',
  'SGST',
  'SERVICE',
  DATE '2024-01-01',
  TRUE,
  'GlowTap SaaS / platform fee — intra-state',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'e3000000-0000-4000-8000-000000000003',
  'e1000000-0000-4000-8000-000000000027',
  'IGST_SAAS',
  'IGST on platform subscription',
  18.00,
  '998314',
  'IGST',
  'SERVICE',
  DATE '2024-01-01',
  TRUE,
  'GlowTap SaaS / platform fee — inter-state',
  'a1000000-0000-4000-8000-000000000001'
)
ON CONFLICT (state_id, tax_code, effective_from) DO NOTHING;

INSERT INTO invoice_tax_lines (
  id, invoice_line_item_id,
  state_tax_config_id, taxable_amount, tax_amount
) VALUES
(
  'e2000000-0000-4000-8000-000000000021',
  'e2000000-0000-4000-8000-000000000011',
  'e3000000-0000-4000-8000-000000000001', -- CGST_SAAS MH
  2499.00,
  224.91
),
(
  'e2000000-0000-4000-8000-000000000022',
  'e2000000-0000-4000-8000-000000000011',
  'e3000000-0000-4000-8000-000000000002', -- SGST_SAAS MH
  2499.00,
  224.91
);

INSERT INTO payments (
  id, organization_id, payment_number, amount, currency, status,
  payment_method, gateway, gateway_order_id, gateway_payment_id, gateway_ref,
  initiated_at, paid_at, notes, created_by
) VALUES (
  'e2000000-0000-4000-8000-000000000031',
  'b1000000-0000-4000-8000-000000000001',
  'GT-PAY-2026-00001',
  2948.82,
  'INR',
  'SUCCEEDED',
  'NACH',
  'RAZORPAY',
  'order_looks_growth_20260601',
  'pay_looks_growth_20260601',
  'NACH-MUM-20260601-001',
  TIMESTAMPTZ '2026-06-01 10:14:00+05:30',
  TIMESTAMPTZ '2026-06-01 10:15:00+05:30',
  'Auto-debit for June 2026 renewal.',
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO invoice_payments (id, invoice_id, payment_id, amount_applied)
VALUES (
  'e2000000-0000-4000-8000-000000000041',
  'e2000000-0000-4000-8000-000000000001',
  'e2000000-0000-4000-8000-000000000031',
  2948.82
);

-- Sync last payment snapshot on bill structure
UPDATE org_bill_structure
SET
  last_payment_at = TIMESTAMPTZ '2026-06-01 10:15:00+05:30',
  payment_reference = 'NACH-MUM-20260601-001',
  updated_at = NOW()
WHERE id = '44c60fc0-7ac4-406d-bd99-6b1cfe6d910b';

-- RLS + Data API grants
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON invoices
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON invoices TO authenticated;

ALTER TABLE invoice_line_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON invoice_line_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_line_items TO authenticated;

ALTER TABLE invoice_tax_lines ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON invoice_tax_lines
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_tax_lines TO authenticated;

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON payments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON payments TO authenticated;

ALTER TABLE invoice_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON invoice_payments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_payments TO authenticated;

ALTER TABLE credit_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON credit_notes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON credit_notes TO authenticated;

ALTER TABLE credit_note_line_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON credit_note_line_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON credit_note_line_items TO authenticated;

ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON refunds
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON refunds TO authenticated;
