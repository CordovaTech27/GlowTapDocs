-- is_paid_out is redundant: derive from salon_payout_id + salon_payouts.status = PAID

DROP INDEX IF EXISTS idx_eut_unpaid_online;

ALTER TABLE end_user_transactions
  DROP COLUMN IF EXISTS is_paid_out;
