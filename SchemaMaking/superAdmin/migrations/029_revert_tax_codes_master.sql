-- Revert tax_codes master: restore denormalized columns on state_tax_configs

ALTER TABLE state_tax_configs
  ADD COLUMN IF NOT EXISTS tax_code VARCHAR(30),
  ADD COLUMN IF NOT EXISTS tax_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS hsn_sac_code VARCHAR(10),
  ADD COLUMN IF NOT EXISTS component_type VARCHAR(20),
  ADD COLUMN IF NOT EXISTS applies_to VARCHAR(20) DEFAULT 'SERVICE',
  ADD COLUMN IF NOT EXISTS rate_pct DECIMAL(5, 2);

UPDATE state_tax_configs stc
SET
  tax_code = tc.code,
  tax_name = tc.name,
  hsn_sac_code = tc.hsn_sac_code,
  component_type = tc.component_type,
  applies_to = tc.applies_to,
  rate_pct = tc.rate_pct
FROM tax_codes tc
WHERE tc.id = stc.tax_code_id;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM state_tax_configs
    WHERE tax_code IS NULL OR tax_name IS NULL OR component_type IS NULL OR rate_pct IS NULL
  ) THEN
    RAISE EXCEPTION 'state_tax_configs backfill from tax_codes failed';
  END IF;
END $$;

ALTER TABLE state_tax_configs
  ALTER COLUMN tax_code SET NOT NULL,
  ALTER COLUMN tax_name SET NOT NULL,
  ALTER COLUMN component_type SET NOT NULL,
  ALTER COLUMN applies_to SET NOT NULL,
  ALTER COLUMN rate_pct SET NOT NULL;

ALTER TABLE state_tax_configs
  DROP CONSTRAINT IF EXISTS state_tax_configs_component_type_check;

ALTER TABLE state_tax_configs
  ADD CONSTRAINT state_tax_configs_component_type_check
    CHECK (component_type IN ('CGST', 'SGST', 'IGST', 'CESS', 'COMPOSITE'));

ALTER TABLE state_tax_configs
  DROP CONSTRAINT IF EXISTS state_tax_configs_applies_to_check;

ALTER TABLE state_tax_configs
  ADD CONSTRAINT state_tax_configs_applies_to_check
    CHECK (applies_to IN ('SERVICE', 'PRODUCT', 'BOTH'));

ALTER TABLE state_tax_configs
  DROP CONSTRAINT IF EXISTS state_tax_configs_rate_pct_check;

ALTER TABLE state_tax_configs
  ADD CONSTRAINT state_tax_configs_rate_pct_check
    CHECK (rate_pct >= 0 AND rate_pct <= 100);

ALTER TABLE state_tax_configs
  DROP CONSTRAINT IF EXISTS uq_state_tax_configs_state_tax_effective;

ALTER TABLE state_tax_configs
  DROP CONSTRAINT IF EXISTS state_tax_configs_tax_code_id_fkey;

ALTER TABLE state_tax_configs
  DROP COLUMN IF EXISTS tax_code_id;

DROP INDEX IF EXISTS idx_state_tax_configs_tax_code_id;

ALTER TABLE state_tax_configs
  ADD CONSTRAINT state_tax_configs_state_id_tax_code_effective_from_key
    UNIQUE (state_id, tax_code, effective_from);

DROP POLICY IF EXISTS data_api_authenticated_all ON tax_codes;
DROP TABLE IF EXISTS tax_codes;
