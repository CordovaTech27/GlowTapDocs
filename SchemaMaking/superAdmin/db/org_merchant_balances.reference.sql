CREATE TABLE org_merchant_balances (
  organization_id       UUID PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  outstanding_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0,
  pending_payout_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
  currency              VARCHAR(3) NOT NULL DEFAULT 'INR',
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
