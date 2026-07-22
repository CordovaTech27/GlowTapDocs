-- Master tax codes; state_tax_configs references tax_code_id

CREATE TABLE tax_codes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code              VARCHAR(30) NOT NULL UNIQUE,
  name              VARCHAR(100) NOT NULL,
  hsn_sac_code      VARCHAR(10),
  component_type    VARCHAR(20) NOT NULL
    CHECK (component_type IN ('CGST', 'SGST', 'IGST', 'CESS', 'COMPOSITE')),
  applies_to        VARCHAR(20) NOT NULL DEFAULT 'SERVICE'
    CHECK (applies_to IN ('SERVICE', 'PRODUCT', 'BOTH')),
  description       TEXT,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO tax_codes (id, code, name, hsn_sac_code, component_type, applies_to, description) VALUES
(
  'a2000000-0000-4000-8000-000000000001',
  'CGST_SALON',
  'CGST on salon services',
  '999714',
  'CGST',
  'SERVICE',
  'Intra-state central component for beauty / salon services'
),
(
  'a2000000-0000-4000-8000-000000000002',
  'SGST_SALON',
  'SGST on salon services',
  '999714',
  'SGST',
  'SERVICE',
  'Intra-state state component for beauty / salon services'
),
(
  'a2000000-0000-4000-8000-000000000003',
  'IGST_SALON',
  'IGST on salon services',
  '999714',
  'IGST',
  'SERVICE',
  'Inter-state supply for beauty / salon services'
),
(
  'a2000000-0000-4000-8000-000000000004',
  'CGST_PLATFORM',
  'CGST on platform subscription',
  NULL,
  'CGST',
  'SERVICE',
  'Intra-state central component for GlowTap SaaS fee (SAC to be set by ops)'
),
(
  'a2000000-0000-4000-8000-000000000005',
  'SGST_PLATFORM',
  'SGST on platform subscription',
  NULL,
  'SGST',
  'SERVICE',
  'Intra-state state component for GlowTap SaaS fee (SAC to be set by ops)'
),
(
  'a2000000-0000-4000-8000-000000000006',
  'IGST_PLATFORM',
  'IGST on platform subscription',
  NULL,
  'IGST',
  'SERVICE',
  'Inter-state GlowTap SaaS fee (SAC to be set by ops)'
)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  hsn_sac_code = EXCLUDED.hsn_sac_code,
  component_type = EXCLUDED.component_type,
  applies_to = EXCLUDED.applies_to,
  description = EXCLUDED.description,
  updated_at = NOW();

ALTER TABLE state_tax_configs
  ADD COLUMN IF NOT EXISTS tax_code_id UUID REFERENCES tax_codes(id);

UPDATE state_tax_configs stc
SET tax_code_id = tc.id
FROM tax_codes tc
WHERE stc.tax_code_id IS NULL
  AND stc.tax_code = tc.code;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM state_tax_configs WHERE tax_code_id IS NULL) THEN
    RAISE EXCEPTION 'state_tax_configs.tax_code_id backfill failed';
  END IF;
END $$;

ALTER TABLE state_tax_configs
  ALTER COLUMN tax_code_id SET NOT NULL;

ALTER TABLE state_tax_configs
  DROP CONSTRAINT IF EXISTS state_tax_configs_state_id_tax_code_effective_from_key;

ALTER TABLE state_tax_configs
  DROP COLUMN IF EXISTS tax_code,
  DROP COLUMN IF EXISTS tax_name,
  DROP COLUMN IF EXISTS hsn_sac_code,
  DROP COLUMN IF EXISTS component_type,
  DROP COLUMN IF EXISTS applies_to;

ALTER TABLE state_tax_configs
  ADD CONSTRAINT uq_state_tax_configs_state_tax_effective
    UNIQUE (state_id, tax_code_id, effective_from);

CREATE INDEX IF NOT EXISTS idx_state_tax_configs_tax_code_id
  ON state_tax_configs(tax_code_id);

ALTER TABLE tax_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON tax_codes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON tax_codes TO authenticated;
