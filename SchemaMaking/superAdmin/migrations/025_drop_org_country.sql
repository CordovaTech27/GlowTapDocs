-- country already lives inside registered_address JSONB

ALTER TABLE organizations
  DROP COLUMN IF EXISTS country;
