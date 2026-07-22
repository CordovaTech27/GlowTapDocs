-- invoice_tax_lines: take tax definition from state_tax_configs via FK
-- Keep only invoice-specific amounts (taxable_amount, tax_amount)

-- Platform SaaS GST configs (distinct from salon service SAC 999714)
INSERT INTO state_tax_configs (
  id, state_id, tax_code, tax_name, rate_pct, hsn_sac_code,
  component_type, applies_to, effective_from, is_active, notes, created_by
) VALUES
(
  'e3000000-0000-4000-8000-000000000001',
  'e1000000-0000-4000-8000-000000000027', -- Maharashtra
  'CGST_SAAS',
  'CGST on platform subscription',
  9.00,
  '998314',
  'CGST',
  'SERVICE',
  DATE '2024-01-01',
  TRUE,
  'GlowTap SaaS / platform fee — intra-state',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'e3000000-0000-4000-8000-000000000002',
  'e1000000-0000-4000-8000-000000000027',
  'SGST_SAAS',
  'SGST on platform subscription',
  9.00,
  '998314',
  'SGST',
  'SERVICE',
  DATE '2024-01-01',
  TRUE,
  'GlowTap SaaS / platform fee — intra-state',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'e3000000-0000-4000-8000-000000000003',
  'e1000000-0000-4000-8000-000000000027',
  'IGST_SAAS',
  'IGST on platform subscription',
  18.00,
  '998314',
  'IGST',
  'SERVICE',
  DATE '2024-01-01',
  TRUE,
  'GlowTap SaaS / platform fee — inter-state',
  'a1000000-0000-4000-8000-000000000001'
)
ON CONFLICT (state_id, tax_code, effective_from) DO NOTHING;

-- Backfill seed tax lines → config FKs
UPDATE invoice_tax_lines
SET state_tax_config_id = 'e3000000-0000-4000-8000-000000000001'
WHERE id = 'e2000000-0000-4000-8000-000000000021';

UPDATE invoice_tax_lines
SET state_tax_config_id = 'e3000000-0000-4000-8000-000000000002'
WHERE id = 'e2000000-0000-4000-8000-000000000022';

ALTER TABLE invoice_tax_lines
  DROP COLUMN IF EXISTS tax_code,
  DROP COLUMN IF EXISTS tax_name,
  DROP COLUMN IF EXISTS component_type,
  DROP COLUMN IF EXISTS rate_pct;

ALTER TABLE invoice_tax_lines
  ALTER COLUMN state_tax_config_id SET NOT NULL;

ALTER TABLE invoice_tax_lines
  DROP CONSTRAINT IF EXISTS invoice_tax_lines_state_tax_config_id_fkey;

ALTER TABLE invoice_tax_lines
  ADD CONSTRAINT invoice_tax_lines_state_tax_config_id_fkey
  FOREIGN KEY (state_tax_config_id) REFERENCES state_tax_configs(id);
