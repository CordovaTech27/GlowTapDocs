CREATE TABLE merchant_ledger_entries (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  balance_bucket          VARCHAR(20) NOT NULL,
  direction               VARCHAR(10) NOT NULL,
  entry_type              VARCHAR(30) NOT NULL,
  amount                  DECIMAL(12, 2) NOT NULL,
  balance_after           DECIMAL(12, 2) NOT NULL,
  currency                VARCHAR(3) NOT NULL DEFAULT 'INR',
  end_user_transaction_id UUID REFERENCES end_user_transactions(id) ON DELETE SET NULL,
  salon_payout_id         UUID REFERENCES salon_payouts(id) ON DELETE SET NULL,
  invoice_id              UUID REFERENCES invoices(id) ON DELETE SET NULL,
  payment_id              UUID REFERENCES payments(id) ON DELETE SET NULL,
  description             TEXT,
  occurred_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
