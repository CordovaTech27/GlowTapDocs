CREATE TABLE rms.invoice_payments (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id     UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  payment_id     UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  amount_applied DECIMAL(12, 2) NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (invoice_id, payment_id)
);
