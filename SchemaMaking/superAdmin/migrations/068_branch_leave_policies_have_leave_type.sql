-- Restructure leave config so branch_leave_policies includes leave_type_id.
-- Year-end / CF % (branch-wide) → branch_leave_year_configs
-- Per leave type (accrual + CF allowed) → branch_leave_policies

-- 1. Year-level settings (one row per branch)
CREATE TABLE employee.branch_leave_year_configs (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id               UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  leave_year_end_month    SMALLINT NOT NULL DEFAULT 3
    CHECK (leave_year_end_month BETWEEN 1 AND 12),
  leave_year_end_day      SMALLINT NOT NULL DEFAULT 31
    CHECK (leave_year_end_day BETWEEN 1 AND 31),
  carry_forward_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
  carry_forward_pct       NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (carry_forward_pct >= 0 AND carry_forward_pct <= 100),
  carry_forward_max_days  NUMERIC(6, 2),
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (branch_id)
);

COMMENT ON TABLE employee.branch_leave_year_configs IS
  'Branch leave year settings: year-end month (e.g. March), master carry-forward % / max days';

INSERT INTO employee.branch_leave_year_configs (
  id, organization_id, branch_id,
  leave_year_end_month, leave_year_end_day,
  carry_forward_enabled, carry_forward_pct, carry_forward_max_days,
  is_active, notes, created_at, updated_at
)
SELECT
  id, organization_id, branch_id,
  leave_year_end_month, leave_year_end_day,
  carry_forward_enabled, carry_forward_pct, carry_forward_max_days,
  is_active, notes, created_at, updated_at
FROM employee.branch_leave_policies;

-- 2. Drop old year-level policies table
DROP TRIGGER IF EXISTS trg_branch_leave_policy_same_org ON employee.branch_leave_policies;
DROP TABLE employee.branch_leave_policies;

-- 3. Rename accrual rules → policies (these already have leave_type_id)
ALTER TABLE employee.branch_leave_accrual_rules
  RENAME TO branch_leave_policies;

ALTER INDEX IF EXISTS employee.idx_branch_leave_accrual_branch
  RENAME TO idx_branch_leave_policies_branch;

-- Rename unique / trigger function references
DROP TRIGGER IF EXISTS trg_branch_leave_accrual_same_org ON employee.branch_leave_policies;

CREATE OR REPLACE FUNCTION employee.enforce_branch_leave_policy_line_same_org()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
  type_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  SELECT organization_id INTO type_org FROM employee.leave_types WHERE id = NEW.leave_type_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_policies: branch must belong to the same organization';
  END IF;
  IF type_org IS NULL OR type_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_policies: leave_type must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_branch_leave_policy_line_same_org
  BEFORE INSERT OR UPDATE OF organization_id, branch_id, leave_type_id
  ON employee.branch_leave_policies
  FOR EACH ROW EXECUTE FUNCTION employee.enforce_branch_leave_policy_line_same_org();

CREATE OR REPLACE FUNCTION employee.enforce_branch_leave_year_config_same_org()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_year_configs: branch must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_branch_leave_year_config_same_org
  BEFORE INSERT OR UPDATE OF organization_id, branch_id ON employee.branch_leave_year_configs
  FOR EACH ROW EXECUTE FUNCTION employee.enforce_branch_leave_year_config_same_org();

DROP FUNCTION IF EXISTS employee.enforce_branch_leave_accrual_same_org();
DROP FUNCTION IF EXISTS employee.enforce_branch_leave_policy_same_org();

COMMENT ON TABLE employee.branch_leave_policies IS
  'Per branch + leave type: monthly accrual days and whether this leave type can carry forward';

COMMENT ON COLUMN employee.branch_leave_policies.leave_type_id IS
  'FK to leave_types — which leave type this policy line applies to';

COMMENT ON COLUMN employee.branch_leave_policies.carry_forward_allowed IS
  'If TRUE (and year_config.carry_forward_enabled), unused balance may CF using year_config pct/max';

GRANT SELECT, INSERT, UPDATE, DELETE ON employee.branch_leave_year_configs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON employee.branch_leave_policies TO authenticated;

ANALYZE employee.branch_leave_year_configs;
ANALYZE employee.branch_leave_policies;
