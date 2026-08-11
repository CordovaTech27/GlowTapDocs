-- Billing cycle options (post migration 015)

CREATE TABLE rms.billing_cycles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code              VARCHAR(30) NOT NULL UNIQUE,
  name              VARCHAR(50) NOT NULL,
  description       TEXT,
  interval_months   INT NOT NULL,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
