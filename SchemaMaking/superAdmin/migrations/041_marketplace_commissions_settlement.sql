-- Marketplace B2C commissions, outstanding balance, payouts (Uber / Stripe Connect style)
-- Reuse existing invoices + payments for monthly commission settlement (salon → GlowTap).

-- ---------------------------------------------------------------------------
-- Platform defaults
-- ---------------------------------------------------------------------------
CREATE TABLE platform_commission_config (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  default_pct                 DECIMAL(5, 2) NOT NULL DEFAULT 5.00
    CHECK (default_pct >= 0 AND default_pct <= 100),
  min_pct                     DECIMAL(5, 2) NOT NULL DEFAULT 1.00
    CHECK (min_pct >= 0),
  max_pct                     DECIMAL(5, 2) NOT NULL DEFAULT 25.00
    CHECK (max_pct <= 100),
  apply_on_refunds            BOOLEAN NOT NULL DEFAULT TRUE,
  monthly_invoice_day         INT NOT NULL DEFAULT 1
    CHECK (monthly_invoice_day BETWEEN 1 AND 28),
  invoice_due_days            INT NOT NULL DEFAULT 7
    CHECK (invoice_due_days >= 0),
  outstanding_invoice_threshold DECIMAL(12, 2) NOT NULL DEFAULT 5000.00
    CHECK (outstanding_invoice_threshold >= 0),
  auto_recover_from_payouts   BOOLEAN NOT NULL DEFAULT TRUE,
  currency                    VARCHAR(3) NOT NULL DEFAULT 'INR',
  notes                       TEXT,
  updated_by                  UUID REFERENCES super_admin_users(id),
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (min_pct <= default_pct AND default_pct <= max_pct)
);

INSERT INTO platform_commission_config (
  id, default_pct, min_pct, max_pct, notes, updated_by
) VALUES (
  'f4000000-0000-4000-8000-000000000001',
  5.00, 1.00, 25.00,
  'GlowTap marketplace defaults: recover cash commission from online payouts; monthly invoice on the 1st, due +7 days; instant invoice if outstanding ≥ ₹5,000.',
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- Commission rate audit (snapshot on txn; this is history of org rate changes)
-- ---------------------------------------------------------------------------
CREATE TABLE commission_rate_history (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id    UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  previous_pct       DECIMAL(5, 2),
  new_pct            DECIMAL(5, 2) NOT NULL
    CHECK (new_pct >= 0 AND new_pct <= 100),
  effective_from     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reason             TEXT,
  changed_by         UUID REFERENCES super_admin_users(id),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_commission_rate_history_org
  ON commission_rate_history(organization_id, effective_from DESC);

-- ---------------------------------------------------------------------------
-- Current merchant balances (denormalized snapshot — source of truth is ledger)
-- ---------------------------------------------------------------------------
CREATE TABLE org_merchant_balances (
  organization_id       UUID PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  outstanding_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (outstanding_amount >= 0),
  pending_payout_amount DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (pending_payout_amount >= 0),
  currency              VARCHAR(3) NOT NULL DEFAULT 'INR',
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- B2C end-user transactions (marketplace GMV)
-- ---------------------------------------------------------------------------
CREATE TABLE end_user_transactions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_ref         VARCHAR(50) NOT NULL UNIQUE,
  organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  branch_id               UUID NOT NULL REFERENCES branches(id),
  booking_ref             VARCHAR(50),
  end_user_ref            VARCHAR(50),
  payment_channel         VARCHAR(20) NOT NULL
    CHECK (payment_channel IN ('ONLINE', 'CASH', 'UPI_AT_SALON', 'CARD_AT_SALON', 'OTHER')),
  collection_model        VARCHAR(20) NOT NULL
    CHECK (collection_model IN ('MARKETPLACE', 'MERCHANT')),
  -- MARKETPLACE = customer → GlowTap → salon (Option 1)
  -- MERCHANT    = customer → salon (cash); GlowTap accrues commission receivable
  gross_amount            DECIMAL(12, 2) NOT NULL CHECK (gross_amount > 0),
  commission_pct          DECIMAL(5, 2) NOT NULL CHECK (commission_pct >= 0 AND commission_pct <= 100),
  commission_amount       DECIMAL(12, 2) NOT NULL CHECK (commission_amount >= 0),
  gateway_fee_amount      DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (gateway_fee_amount >= 0),
  net_to_salon            DECIMAL(12, 2) NOT NULL,
  -- ONLINE MARKETPLACE: net transferred this txn (after commission, fees, outstanding recovery)
  -- CASH MERCHANT: typically 0 (salon already holds cash); commission goes to outstanding
  currency                VARCHAR(3) NOT NULL DEFAULT 'INR',
  payment_method          VARCHAR(30) NOT NULL
    CHECK (payment_method IN (
      'UPI', 'CARD', 'NET_BANKING', 'WALLET', 'NACH',
      'CASH', 'UPI_AT_SALON', 'CARD_AT_SALON', 'OTHER'
    )),
  status                  VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN (
      'PENDING', 'SUCCESS', 'FAILED', 'REFUNDED',
      'PARTIALLY_REFUNDED', 'DISPUTED', 'CANCELLED'
    )),
  gateway                 VARCHAR(30)
    CHECK (gateway IS NULL OR gateway IN ('RAZORPAY', 'STRIPE', 'CASHFREE', 'MANUAL', 'OTHER')),
  gateway_order_id        VARCHAR(100),
  gateway_payment_id      VARCHAR(100),
  gateway_ref             VARCHAR(255),
  failure_code            VARCHAR(50),
  failure_message         TEXT,
  service_details         JSONB,
  outstanding_recovered   DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (outstanding_recovered >= 0),
  salon_payout_id         UUID,
  occurred_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (
    (collection_model = 'MARKETPLACE' AND payment_channel = 'ONLINE')
    OR (collection_model = 'MERCHANT' AND payment_channel <> 'ONLINE')
    OR payment_channel = 'OTHER'
  )
);

CREATE INDEX idx_eut_org_occurred
  ON end_user_transactions(organization_id, occurred_at DESC);
CREATE INDEX idx_eut_branch_occurred
  ON end_user_transactions(branch_id, occurred_at DESC);
CREATE INDEX idx_eut_status
  ON end_user_transactions(status);
CREATE INDEX idx_eut_channel
  ON end_user_transactions(payment_channel, occurred_at DESC);
CREATE INDEX idx_eut_gateway_payment
  ON end_user_transactions(gateway_payment_id)
  WHERE gateway_payment_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Salon payouts (GlowTap → salon bank for online collections)
-- ---------------------------------------------------------------------------
CREATE TABLE salon_payouts (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_number             VARCHAR(50) NOT NULL UNIQUE,
  organization_id           UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  status                    VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'PROCESSING', 'PAID', 'FAILED', 'CANCELLED')),
  currency                  VARCHAR(3) NOT NULL DEFAULT 'INR',
  gross_collected           DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (gross_collected >= 0),
  commission_deducted       DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (commission_deducted >= 0),
  gateway_fees_deducted     DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (gateway_fees_deducted >= 0),
  outstanding_recovered     DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (outstanding_recovered >= 0),
  net_payout_amount         DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (net_payout_amount >= 0),
  gateway                   VARCHAR(30)
    CHECK (gateway IS NULL OR gateway IN ('RAZORPAY', 'STRIPE', 'CASHFREE', 'MANUAL', 'OTHER')),
  gateway_payout_id         VARCHAR(100),
  gateway_ref               VARCHAR(255),
  period_start              TIMESTAMPTZ,
  period_end                TIMESTAMPTZ,
  paid_at                   TIMESTAMPTZ,
  failure_message           TEXT,
  notes                     TEXT,
  created_by                UUID REFERENCES super_admin_users(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salon_payouts_org
  ON salon_payouts(organization_id, created_at DESC);
CREATE INDEX idx_salon_payouts_status
  ON salon_payouts(status);

ALTER TABLE end_user_transactions
  ADD CONSTRAINT end_user_transactions_salon_payout_id_fkey
  FOREIGN KEY (salon_payout_id) REFERENCES salon_payouts(id) ON DELETE SET NULL;

CREATE TABLE salon_payout_items (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id                 UUID NOT NULL REFERENCES salon_payouts(id) ON DELETE CASCADE,
  end_user_transaction_id   UUID REFERENCES end_user_transactions(id) ON DELETE SET NULL,
  item_type                 VARCHAR(30) NOT NULL
    CHECK (item_type IN (
      'BOOKING_GROSS', 'COMMISSION', 'GATEWAY_FEE',
      'OUTSTANDING_RECOVERY', 'ADJUSTMENT', 'NET_TRANSFER'
    )),
  amount                    DECIMAL(12, 2) NOT NULL,
  description               VARCHAR(255),
  sort_order                INT NOT NULL DEFAULT 0,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salon_payout_items_payout
  ON salon_payout_items(payout_id, sort_order);

-- ---------------------------------------------------------------------------
-- Merchant ledger (outstanding + payable movements — Uber-style wallet log)
-- ---------------------------------------------------------------------------
CREATE TABLE merchant_ledger_entries (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id           UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  balance_bucket            VARCHAR(20) NOT NULL
    CHECK (balance_bucket IN ('OUTSTANDING', 'PAYABLE')),
  -- OUTSTANDING = salon owes GlowTap (cash commissions)
  -- PAYABLE     = GlowTap owes salon (online nets held for payout)
  direction                 VARCHAR(10) NOT NULL
    CHECK (direction IN ('INCREASE', 'DECREASE')),
  entry_type                VARCHAR(30) NOT NULL
    CHECK (entry_type IN (
      'COMMISSION_ACCRUAL',
      'OUTSTANDING_RECOVERY',
      'COMMISSION_INVOICE',
      'COMMISSION_PAYMENT',
      'PAYABLE_ACCRUAL',
      'PAYOUT',
      'REFUND_REVERSAL',
      'DISPUTE_HOLD',
      'ADJUSTMENT'
    )),
  amount                    DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  balance_after             DECIMAL(12, 2) NOT NULL CHECK (balance_after >= 0),
  currency                  VARCHAR(3) NOT NULL DEFAULT 'INR',
  end_user_transaction_id   UUID REFERENCES end_user_transactions(id) ON DELETE SET NULL,
  salon_payout_id           UUID REFERENCES salon_payouts(id) ON DELETE SET NULL,
  invoice_id                UUID REFERENCES invoices(id) ON DELETE SET NULL,
  payment_id                UUID REFERENCES payments(id) ON DELETE SET NULL,
  description               TEXT,
  occurred_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by                UUID REFERENCES super_admin_users(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_merchant_ledger_org_occurred
  ON merchant_ledger_entries(organization_id, occurred_at DESC);
CREATE INDEX idx_merchant_ledger_bucket
  ON merchant_ledger_entries(organization_id, balance_bucket, occurred_at DESC);
CREATE INDEX idx_merchant_ledger_txn
  ON merchant_ledger_entries(end_user_transaction_id)
  WHERE end_user_transaction_id IS NOT NULL;
CREATE INDEX idx_merchant_ledger_invoice
  ON merchant_ledger_entries(invoice_id)
  WHERE invoice_id IS NOT NULL;

-- Allow COMMISSION on existing invoices (monthly cash-commission settlement)
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_invoice_type_check;
ALTER TABLE invoices ADD CONSTRAINT invoices_invoice_type_check
  CHECK (invoice_type IN (
    'PURCHASE', 'RENEWAL', 'UPGRADE', 'DOWNGRADE',
    'CREDIT', 'MANUAL', 'ADJUSTMENT', 'COMMISSION'
  ));

-- ---------------------------------------------------------------------------
-- Seed balances for active orgs
-- ---------------------------------------------------------------------------
INSERT INTO org_merchant_balances (organization_id, outstanding_amount, pending_payout_amount)
SELECT o.id, 0, 0
FROM organizations o
WHERE o.status IN ('ACTIVE', 'SUSPENDED')
ON CONFLICT (organization_id) DO NOTHING;

INSERT INTO commission_rate_history (
  id, organization_id, previous_pct, new_pct, effective_from, reason, changed_by
) VALUES
(
  'f4000000-0000-4000-8000-000000000011',
  'b1000000-0000-4000-8000-000000000001',
  NULL, 8.00, TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  'Initial commission at onboarding',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f4000000-0000-4000-8000-000000000012',
  'b1000000-0000-4000-8000-000000000003',
  NULL, 10.00, TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  'Initial commission at onboarding',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f4000000-0000-4000-8000-000000000013',
  'b1000000-0000-4000-8000-000000000004',
  NULL, 5.00, TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  'Initial commission at onboarding',
  'a1000000-0000-4000-8000-000000000001'
);

-- ===========================================================================
-- MOCK DATA — Enrich Salon (10%): cash outstanding + online recovery (textbook)
-- ===========================================================================

-- Cash 1: ₹1,000 → commission ₹100 → outstanding 100
INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, service_details, outstanding_recovered, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000001',
  'GT-B2C-2026-00001',
  'b1000000-0000-4000-8000-000000000003',
  'c1000000-0000-4000-8000-000000000006',
  'BK-ENR-1001', 'EU-9001',
  'CASH', 'MERCHANT',
  1000.00, 10.00, 100.00, 0, 0,
  'CASH', 'SUCCESS',
  '{"service":"Haircut","notes":"Paid at salon in cash"}'::jsonb,
  0,
  TIMESTAMPTZ '2026-07-05 11:20:00+05:30'
);

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, description, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000101',
  'b1000000-0000-4000-8000-000000000003',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 100.00, 100.00,
  'f5000000-0000-4000-8000-000000000001',
  'Cash booking commission GT-B2C-2026-00001',
  TIMESTAMPTZ '2026-07-05 11:20:00+05:30'
);

-- Cash 2: ₹2,000 → commission ₹200 → outstanding 300
INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, service_details, outstanding_recovered, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000002',
  'GT-B2C-2026-00002',
  'b1000000-0000-4000-8000-000000000003',
  'c1000000-0000-4000-8000-000000000006',
  'BK-ENR-1002', 'EU-9002',
  'CASH', 'MERCHANT',
  2000.00, 10.00, 200.00, 0, 0,
  'CASH', 'SUCCESS',
  '{"service":"Keratin treatment"}'::jsonb,
  0,
  TIMESTAMPTZ '2026-07-12 16:05:00+05:30'
);

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, description, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000102',
  'b1000000-0000-4000-8000-000000000003',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 200.00, 300.00,
  'f5000000-0000-4000-8000-000000000002',
  'Cash booking commission GT-B2C-2026-00002',
  TIMESTAMPTZ '2026-07-12 16:05:00+05:30'
);

-- Online: ₹2,000 — commission 200, gateway 40, recover outstanding 300 → salon net 1,460
INSERT INTO salon_payouts (
  id, payout_number, organization_id, status, currency,
  gross_collected, commission_deducted, gateway_fees_deducted, outstanding_recovered,
  net_payout_amount, gateway, gateway_payout_id, gateway_ref,
  period_start, period_end, paid_at, notes, created_by
) VALUES (
  'f5000000-0000-4000-8000-000000000201',
  'GT-PO-2026-00001',
  'b1000000-0000-4000-8000-000000000003',
  'PAID', 'INR',
  2000.00, 200.00, 40.00, 300.00,
  1460.00, 'RAZORPAY', 'pout_enrich_20260718', 'RAZORPAYX-ENR-0718',
  TIMESTAMPTZ '2026-07-18 10:00:00+05:30',
  TIMESTAMPTZ '2026-07-18 10:05:00+05:30',
  TIMESTAMPTZ '2026-07-18 10:06:00+05:30',
  'Instant payout after online booking; outstanding cash commissions recovered.',
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, gateway, gateway_order_id, gateway_payment_id, gateway_ref,
  service_details, outstanding_recovered, salon_payout_id, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000003',
  'GT-B2C-2026-00003',
  'b1000000-0000-4000-8000-000000000003',
  'c1000000-0000-4000-8000-000000000006',
  'BK-ENR-1003', 'EU-9003',
  'ONLINE', 'MARKETPLACE',
  2000.00, 10.00, 200.00, 40.00, 1460.00,
  'UPI', 'SUCCESS', 'RAZORPAY',
  'order_enrich_online_0718', 'pay_enrich_online_0718', 'upi_enrich_0718',
  '{"service":"Bridal package deposit"}'::jsonb,
  300.00,
  'f5000000-0000-4000-8000-000000000201',
  TIMESTAMPTZ '2026-07-18 10:02:00+05:30'
);

INSERT INTO salon_payout_items (id, payout_id, end_user_transaction_id, item_type, amount, description, sort_order) VALUES
('f5000000-0000-4000-8000-000000000211', 'f5000000-0000-4000-8000-000000000201', 'f5000000-0000-4000-8000-000000000003', 'BOOKING_GROSS', 2000.00, 'Customer paid online', 10),
('f5000000-0000-4000-8000-000000000212', 'f5000000-0000-4000-8000-000000000201', 'f5000000-0000-4000-8000-000000000003', 'COMMISSION', -200.00, 'GlowTap commission 10%', 20),
('f5000000-0000-4000-8000-000000000213', 'f5000000-0000-4000-8000-000000000201', 'f5000000-0000-4000-8000-000000000003', 'GATEWAY_FEE', -40.00, 'Payment gateway fee', 30),
('f5000000-0000-4000-8000-000000000214', 'f5000000-0000-4000-8000-000000000201', 'f5000000-0000-4000-8000-000000000003', 'OUTSTANDING_RECOVERY', -300.00, 'Recover cash commission outstanding', 40),
('f5000000-0000-4000-8000-000000000215', 'f5000000-0000-4000-8000-000000000201', 'f5000000-0000-4000-8000-000000000003', 'NET_TRANSFER', 1460.00, 'Net transferred to salon', 50);

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, salon_payout_id, description, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000103',
  'b1000000-0000-4000-8000-000000000003',
  'OUTSTANDING', 'DECREASE', 'OUTSTANDING_RECOVERY', 300.00, 0.00,
  'f5000000-0000-4000-8000-000000000003',
  'f5000000-0000-4000-8000-000000000201',
  'Recovered ₹300 outstanding from online payout GT-PO-2026-00001',
  TIMESTAMPTZ '2026-07-18 10:06:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000104',
  'b1000000-0000-4000-8000-000000000003',
  'PAYABLE', 'INCREASE', 'PAYABLE_ACCRUAL', 1460.00, 1460.00,
  'f5000000-0000-4000-8000-000000000003',
  'f5000000-0000-4000-8000-000000000201',
  'Online net due to salon before payout',
  TIMESTAMPTZ '2026-07-18 10:02:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000105',
  'b1000000-0000-4000-8000-000000000003',
  'PAYABLE', 'DECREASE', 'PAYOUT', 1460.00, 0.00,
  'f5000000-0000-4000-8000-000000000003',
  'f5000000-0000-4000-8000-000000000201',
  'Payout GT-PO-2026-00001 paid',
  TIMESTAMPTZ '2026-07-18 10:06:00+05:30'
);

UPDATE org_merchant_balances
SET outstanding_amount = 0, pending_payout_amount = 0, updated_at = NOW()
WHERE organization_id = 'b1000000-0000-4000-8000-000000000003';

-- ===========================================================================
-- MOCK — Looks Salon (8%): cash outstanding left → monthly COMMISSION invoice
-- Reuses invoices + payments pattern for salon → GlowTap settlement
-- ===========================================================================

INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, service_details, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000004',
  'GT-B2C-2026-00004',
  'b1000000-0000-4000-8000-000000000001',
  'c1000000-0000-4000-8000-000000000001',
  'BK-LKS-2001', 'EU-9101',
  'CASH', 'MERCHANT',
  2500.00, 8.00, 200.00, 0, 0,
  'CASH', 'SUCCESS',
  '{"service":"Spa package"}'::jsonb,
  TIMESTAMPTZ '2026-07-08 13:00:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000005',
  'GT-B2C-2026-00005',
  'b1000000-0000-4000-8000-000000000001',
  'c1000000-0000-4000-8000-000000000001',
  'BK-LKS-2002', 'EU-9102',
  'UPI_AT_SALON', 'MERCHANT',
  3125.00, 8.00, 250.00, 0, 0,
  'UPI_AT_SALON', 'SUCCESS',
  '{"service":"Hair colour"}'::jsonb,
  TIMESTAMPTZ '2026-07-22 18:40:00+05:30'
);

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, description, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000106',
  'b1000000-0000-4000-8000-000000000001',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 200.00, 200.00,
  'f5000000-0000-4000-8000-000000000004',
  'Cash commission GT-B2C-2026-00004',
  TIMESTAMPTZ '2026-07-08 13:00:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000107',
  'b1000000-0000-4000-8000-000000000001',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 250.00, 450.00,
  'f5000000-0000-4000-8000-000000000005',
  'UPI-at-salon commission GT-B2C-2026-00005',
  TIMESTAMPTZ '2026-07-22 18:40:00+05:30'
);

-- Month-end commission invoice (reuses invoices) — OPEN, due +7 days
INSERT INTO invoices (
  id, organization_id, org_bill_structure_id, invoice_number, invoice_type, status,
  currency, subtotal_amount, discount_amount, taxable_amount, tax_amount, total_amount,
  amount_paid, amount_due,
  billing_period_start, billing_period_end, issue_date, due_date,
  notes, created_by
) VALUES (
  'f5000000-0000-4000-8000-000000000301',
  'b1000000-0000-4000-8000-000000000001',
  '44c60fc0-7ac4-406d-bd99-6b1cfe6d910b',
  'GT-INV-2026-00002',
  'COMMISSION',
  'OPEN',
  'INR',
  450.00, 0, 450.00, 0, 450.00,
  0, 450.00,
  DATE '2026-07-01', DATE '2026-07-31',
  DATE '2026-08-01', DATE '2026-08-08',
  'July 2026 marketplace commission outstanding (cash / UPI-at-salon). Pay by due date or auto-recover from next online payouts.',
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO invoice_line_items (
  id, invoice_id, line_type, description, quantity, unit_amount, amount,
  discount_amount, taxable_amount, sort_order
) VALUES (
  'f5000000-0000-4000-8000-000000000311',
  'f5000000-0000-4000-8000-000000000301',
  'FEE',
  'Marketplace commission outstanding — July 2026',
  1, 450.00, 450.00, 0, 450.00, 10
);

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  invoice_id, description, occurred_at, created_by
) VALUES (
  'f5000000-0000-4000-8000-000000000108',
  'b1000000-0000-4000-8000-000000000001',
  'OUTSTANDING', 'DECREASE', 'COMMISSION_INVOICE', 450.00, 0.00,
  'f5000000-0000-4000-8000-000000000301',
  'Moved outstanding to commission invoice GT-INV-2026-00002 (still receivable until paid)',
  TIMESTAMPTZ '2026-08-01 00:05:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
);

-- Note: after invoicing, operational outstanding for auto-recovery may stay tracked
-- against unpaid COMMISSION invoices; snapshot outstanding reset to 0 for accrual bucket.
UPDATE org_merchant_balances
SET outstanding_amount = 0, pending_payout_amount = 0, updated_at = NOW()
WHERE organization_id = 'b1000000-0000-4000-8000-000000000001';

-- ===========================================================================
-- MOCK — Looks online booking without prior outstanding
-- ===========================================================================
INSERT INTO salon_payouts (
  id, payout_number, organization_id, status, currency,
  gross_collected, commission_deducted, gateway_fees_deducted, outstanding_recovered,
  net_payout_amount, gateway, gateway_payout_id, paid_at, created_by
) VALUES (
  'f5000000-0000-4000-8000-000000000202',
  'GT-PO-2026-00002',
  'b1000000-0000-4000-8000-000000000001',
  'PAID', 'INR',
  2000.00, 160.00, 40.00, 0,
  1800.00, 'RAZORPAY', 'pout_looks_20260720',
  TIMESTAMPTZ '2026-07-20 12:10:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, gateway, gateway_order_id, gateway_payment_id,
  service_details, outstanding_recovered, salon_payout_id, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000006',
  'GT-B2C-2026-00006',
  'b1000000-0000-4000-8000-000000000001',
  'c1000000-0000-4000-8000-000000000001',
  'BK-LKS-2003', 'EU-9103',
  'ONLINE', 'MARKETPLACE',
  2000.00, 8.00, 160.00, 40.00, 1800.00,
  'CARD', 'SUCCESS', 'RAZORPAY',
  'order_looks_online_0720', 'pay_looks_online_0720',
  '{"service":"Hair spa"}'::jsonb,
  0,
  'f5000000-0000-4000-8000-000000000202',
  TIMESTAMPTZ '2026-07-20 12:05:00+05:30'
);

INSERT INTO salon_payout_items (id, payout_id, end_user_transaction_id, item_type, amount, description, sort_order) VALUES
('f5000000-0000-4000-8000-000000000221', 'f5000000-0000-4000-8000-000000000202', 'f5000000-0000-4000-8000-000000000006', 'BOOKING_GROSS', 2000.00, 'Customer paid online', 10),
('f5000000-0000-4000-8000-000000000222', 'f5000000-0000-4000-8000-000000000202', 'f5000000-0000-4000-8000-000000000006', 'COMMISSION', -160.00, 'GlowTap commission 8%', 20),
('f5000000-0000-4000-8000-000000000223', 'f5000000-0000-4000-8000-000000000202', 'f5000000-0000-4000-8000-000000000006', 'GATEWAY_FEE', -40.00, 'Payment gateway fee', 30),
('f5000000-0000-4000-8000-000000000224', 'f5000000-0000-4000-8000-000000000202', 'f5000000-0000-4000-8000-000000000006', 'NET_TRANSFER', 1800.00, 'Net transferred to salon', 40);

-- RLS
ALTER TABLE platform_commission_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON platform_commission_config
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON platform_commission_config TO authenticated;

ALTER TABLE commission_rate_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON commission_rate_history
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON commission_rate_history TO authenticated;

ALTER TABLE org_merchant_balances ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON org_merchant_balances
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON org_merchant_balances TO authenticated;

ALTER TABLE end_user_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON end_user_transactions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON end_user_transactions TO authenticated;

ALTER TABLE salon_payouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON salon_payouts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON salon_payouts TO authenticated;

ALTER TABLE salon_payout_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON salon_payout_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON salon_payout_items TO authenticated;

ALTER TABLE merchant_ledger_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON merchant_ledger_entries
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON merchant_ledger_entries TO authenticated;

ANALYZE end_user_transactions;
ANALYZE merchant_ledger_entries;
ANALYZE salon_payouts;
ANALYZE org_merchant_balances;
ANALYZE invoices;
