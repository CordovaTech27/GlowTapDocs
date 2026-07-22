-- Organizations: replace text state with state_id → states

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS state_id UUID REFERENCES states(id);

UPDATE organizations o
SET state_id = s.id
FROM states s
WHERE o.state_id IS NULL
  AND LOWER(o.state) = LOWER(s.name);

-- Fail loudly if any row could not be mapped
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM organizations WHERE state_id IS NULL) THEN
    RAISE EXCEPTION 'organizations.state_id backfill failed: unmatched state text remains';
  END IF;
END $$;

ALTER TABLE organizations
  ALTER COLUMN state_id SET NOT NULL;

ALTER TABLE organizations
  DROP COLUMN IF EXISTS state;

CREATE INDEX IF NOT EXISTS idx_organizations_state_id ON organizations(state_id);
