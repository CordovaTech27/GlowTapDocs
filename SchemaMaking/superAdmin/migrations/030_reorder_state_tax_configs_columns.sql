-- Restore original physical column order on state_tax_configs
-- (ADD COLUMN after tax_codes revert appended tax fields at the end)

ALTER TABLE state_tax_configs RENAME TO state_tax_configs_old;

ALTER INDEX IF EXISTS state_tax_configs_pkey
  RENAME TO state_tax_configs_old_pkey;
ALTER INDEX IF EXISTS state_tax_configs_state_id_tax_code_effective_from_key
  RENAME TO state_tax_configs_old_uq;
ALTER INDEX IF EXISTS idx_state_tax_configs_state_id
  RENAME TO idx_state_tax_configs_old_state_id;
ALTER INDEX IF EXISTS idx_state_tax_configs_active
  RENAME TO idx_state_tax_configs_old_active;

ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_rate_pct_check
  TO state_tax_configs_old_rate_pct_check;
ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_component_type_check
  TO state_tax_configs_old_component_type_check;
ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_applies_to_check
  TO state_tax_configs_old_applies_to_check;
ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_check
  TO state_tax_configs_old_dates_check;
ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_state_id_fkey
  TO state_tax_configs_old_state_id_fkey;
ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_created_by_fkey
  TO state_tax_configs_old_created_by_fkey;
ALTER TABLE state_tax_configs_old
  RENAME CONSTRAINT state_tax_configs_updated_by_fkey
  TO state_tax_configs_old_updated_by_fkey;

CREATE TABLE state_tax_configs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state_id        UUID NOT NULL REFERENCES states(id) ON DELETE CASCADE,
  tax_code        VARCHAR(30) NOT NULL,
  tax_name        VARCHAR(100) NOT NULL,
  rate_pct        NUMERIC(5, 2) NOT NULL
    CHECK (rate_pct >= 0 AND rate_pct <= 100),
  hsn_sac_code    VARCHAR(10),
  component_type  VARCHAR(20) NOT NULL
    CHECK (component_type IN ('CGST', 'SGST', 'IGST', 'CESS', 'COMPOSITE')),
  applies_to      VARCHAR(20) NOT NULL DEFAULT 'SERVICE'
    CHECK (applies_to IN ('SERVICE', 'PRODUCT', 'BOTH')),
  effective_from  DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_to    DATE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  notes           TEXT,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (state_id, tax_code, effective_from),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

INSERT INTO state_tax_configs (
  id, state_id, tax_code, tax_name, rate_pct, hsn_sac_code,
  component_type, applies_to, effective_from, effective_to,
  is_active, notes, created_by, updated_by, created_at, updated_at
)
SELECT
  id, state_id, tax_code, tax_name, rate_pct, hsn_sac_code,
  component_type, applies_to, effective_from, effective_to,
  is_active, notes, created_by, updated_by, created_at, updated_at
FROM state_tax_configs_old;

DROP TABLE state_tax_configs_old;

CREATE INDEX idx_state_tax_configs_state_id ON state_tax_configs(state_id);
CREATE INDEX idx_state_tax_configs_active ON state_tax_configs(state_id, is_active)
  WHERE is_active = TRUE;

ALTER TABLE state_tax_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY data_api_authenticated_all ON state_tax_configs
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON state_tax_configs TO authenticated;
