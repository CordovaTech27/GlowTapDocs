-- pricing_impact lives on reason_codes; resolve via reason_code_id

ALTER TABLE org_status_actions
  DROP COLUMN IF EXISTS pricing_impact;
