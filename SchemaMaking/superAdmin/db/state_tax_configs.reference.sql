-- Per-state tax configuration — Super Admin managed

CREATE TABLE rms.state_tax_configs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state_id        UUID NOT NULL REFERENCES states(id) ON DELETE CASCADE,
  tax_code        VARCHAR(30) NOT NULL,
  tax_name        VARCHAR(100) NOT NULL,
  rate_pct        DECIMAL(5,2) NOT NULL,
  hsn_sac_code    VARCHAR(10),
  component_type  VARCHAR(20) NOT NULL,
  applies_to      VARCHAR(20) NOT NULL DEFAULT 'SERVICE',
  effective_from  DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_to    DATE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  notes           TEXT,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (state_id, tax_code, effective_from)
);
