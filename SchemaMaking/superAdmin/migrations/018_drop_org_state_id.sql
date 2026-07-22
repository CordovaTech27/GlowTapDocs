-- State jurisdiction moved to org_bill_structure (billing) and branches (outlets)

DROP INDEX IF EXISTS idx_organizations_state_id;

ALTER TABLE organizations
  DROP COLUMN IF EXISTS state_id;
