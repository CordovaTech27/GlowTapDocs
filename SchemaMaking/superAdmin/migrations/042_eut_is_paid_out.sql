-- EOD payout: per-transaction paid flag (batch status remains on salon_payouts)

ALTER TABLE end_user_transactions
  ADD COLUMN IF NOT EXISTS is_paid_out BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN end_user_transactions.is_paid_out IS
  'ONLINE marketplace: false until EOD salon_payout is PAID; then true. Cash/merchant txns stay false (no GlowTap payout).';

CREATE INDEX IF NOT EXISTS idx_eut_unpaid_online
  ON end_user_transactions(organization_id, occurred_at)
  WHERE payment_channel = 'ONLINE'
    AND collection_model = 'MARKETPLACE'
    AND status = 'SUCCESS'
    AND is_paid_out = FALSE;

-- Backfill seeded online txns that already have a paid payout
UPDATE end_user_transactions eut
SET is_paid_out = TRUE
FROM salon_payouts sp
WHERE eut.salon_payout_id = sp.id
  AND sp.status = 'PAID'
  AND eut.is_paid_out = FALSE;
