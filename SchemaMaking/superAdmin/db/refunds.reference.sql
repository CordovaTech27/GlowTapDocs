CREATE TABLE refunds (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id        UUID NOT NULL REFERENCES payments(id) ON DELETE RESTRICT,
  credit_note_id    UUID REFERENCES credit_notes(id) ON DELETE SET NULL,
  amount            DECIMAL(12, 2) NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  gateway_refund_id VARCHAR(100),
  reason            TEXT,
  refunded_at       TIMESTAMPTZ,
  created_by        UUID REFERENCES super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
