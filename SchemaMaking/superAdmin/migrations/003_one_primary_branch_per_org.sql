-- Ensure each organization has at most one primary branch.

CREATE UNIQUE INDEX idx_one_primary_branch_per_org
  ON branches (organization_id)
  WHERE is_primary = TRUE;
