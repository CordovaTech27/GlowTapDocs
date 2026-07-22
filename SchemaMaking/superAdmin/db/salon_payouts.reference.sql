CREATE TABLE salon_payouts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_number         VARCHAR(50) NOT NULL UNIQUE,
  organization_id       UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  status                VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  currency              VARCHAR(3) NOT NULL DEFAULT 'INR',
  gross_collected       DECIMAL(12, 2) NOT NULL DEFAULT 0,
  commission_deducted   DECIMAL(12, 2) NOT NULL DEFAULT 0,
  gateway_fees_deducted DECIMAL(12, 2) NOT NULL DEFAULT 0,
  outstanding_recovered DECIMAL(12, 2) NOT NULL DEFAULT 0,
  net_payout_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0,
  gateway               VARCHAR(30),
  gateway_payout_id     VARCHAR(100),
  paid_at               TIMESTAMPTZ,
  notes                 TEXT,
  created_by            UUID REFERENCES super_admin_users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
