-- Platform marketplace commission defaults

CREATE TABLE platform_commission_config (
  id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  default_pct                   DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
  min_pct                       DECIMAL(5, 2) NOT NULL DEFAULT 1.00,
  max_pct                       DECIMAL(5, 2) NOT NULL DEFAULT 25.00,
  apply_on_refunds              BOOLEAN NOT NULL DEFAULT TRUE,
  monthly_invoice_day           INT NOT NULL DEFAULT 1,
  invoice_due_days              INT NOT NULL DEFAULT 7,
  outstanding_invoice_threshold DECIMAL(12, 2) NOT NULL DEFAULT 5000.00,
  auto_recover_from_payouts     BOOLEAN NOT NULL DEFAULT TRUE,
  currency                      VARCHAR(3) NOT NULL DEFAULT 'INR',
  notes                         TEXT,
  updated_by                    UUID REFERENCES super_admin_users(id),
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
