-- Rate belongs on tax code master (national), not repeated per state config

ALTER TABLE tax_codes
  ADD COLUMN IF NOT EXISTS rate_pct DECIMAL(5, 2)
    CHECK (rate_pct IS NULL OR (rate_pct >= 0 AND rate_pct <= 100));

-- Backfill from any existing state config (rates are uniform today)
UPDATE tax_codes tc
SET rate_pct = sub.rate_pct
FROM (
  SELECT DISTINCT ON (tax_code_id) tax_code_id, rate_pct
  FROM state_tax_configs
  WHERE is_active = TRUE
  ORDER BY tax_code_id, effective_from DESC
) sub
WHERE tc.id = sub.tax_code_id
  AND tc.rate_pct IS NULL;

UPDATE tax_codes SET rate_pct = 9.00  WHERE code IN ('CGST_SALON', 'SGST_SALON') AND rate_pct IS NULL;
UPDATE tax_codes SET rate_pct = 18.00 WHERE code = 'IGST_SALON' AND rate_pct IS NULL;
UPDATE tax_codes SET rate_pct = 9.00  WHERE code IN ('CGST_PLATFORM', 'SGST_PLATFORM') AND rate_pct IS NULL;
UPDATE tax_codes SET rate_pct = 18.00 WHERE code = 'IGST_PLATFORM' AND rate_pct IS NULL;

ALTER TABLE tax_codes
  ALTER COLUMN rate_pct SET NOT NULL;

ALTER TABLE state_tax_configs
  DROP COLUMN IF EXISTS rate_pct;
