-- Billing jurisdiction state (GST state for platform fee invoicing)

ALTER TABLE org_bill_structure
  ADD COLUMN state_id UUID REFERENCES states(id);

UPDATE org_bill_structure obs
SET state_id = o.state_id
FROM organizations o
WHERE o.id = obs.organization_id
  AND obs.state_id IS NULL;

CREATE INDEX idx_org_bill_structure_state_id ON org_bill_structure(state_id);
