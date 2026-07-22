-- city / pincode already live inside registered_address JSONB

DROP INDEX IF EXISTS idx_organizations_city;

ALTER TABLE organizations
  DROP COLUMN IF EXISTS city,
  DROP COLUMN IF EXISTS pincode;
