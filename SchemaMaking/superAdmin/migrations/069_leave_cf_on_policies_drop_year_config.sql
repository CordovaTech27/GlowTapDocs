-- Move carry_forward_pct, carry_forward_max_days, and leave year-end
-- onto branch_leave_policies (per leave type). Drop branch_leave_year_configs.

ALTER TABLE employee.branch_leave_policies
  ADD COLUMN IF NOT EXISTS leave_year_end_month SMALLINT NOT NULL DEFAULT 3
    CHECK (leave_year_end_month BETWEEN 1 AND 12),
  ADD COLUMN IF NOT EXISTS leave_year_end_day SMALLINT NOT NULL DEFAULT 31
    CHECK (leave_year_end_day BETWEEN 1 AND 31),
  ADD COLUMN IF NOT EXISTS carry_forward_pct NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (carry_forward_pct >= 0 AND carry_forward_pct <= 100),
  ADD COLUMN IF NOT EXISTS carry_forward_max_days NUMERIC(6, 2);

-- Copy values from year_configs onto each policy line for that branch
UPDATE employee.branch_leave_policies p
SET
  leave_year_end_month = y.leave_year_end_month,
  leave_year_end_day = y.leave_year_end_day,
  carry_forward_pct = CASE
    WHEN p.carry_forward_allowed THEN y.carry_forward_pct
    ELSE 0
  END,
  carry_forward_max_days = CASE
    WHEN p.carry_forward_allowed THEN y.carry_forward_max_days
    ELSE NULL
  END,
  updated_at = NOW()
FROM employee.branch_leave_year_configs y
WHERE y.branch_id = p.branch_id;

COMMENT ON COLUMN employee.branch_leave_policies.carry_forward_pct IS
  'Unused leave % that may carry forward for this leave type (0 if carry_forward_allowed is false)';

COMMENT ON COLUMN employee.branch_leave_policies.carry_forward_max_days IS
  'Optional cap on days carried for this leave type';

COMMENT ON COLUMN employee.branch_leave_policies.leave_year_end_month IS
  'Leave year end month for this branch policy line (typically same across types at a branch, e.g. 3 = March)';

-- Drop year_config table + its trigger/function
DROP TRIGGER IF EXISTS trg_branch_leave_year_config_same_org ON employee.branch_leave_year_configs;
DROP TABLE IF EXISTS employee.branch_leave_year_configs;
DROP FUNCTION IF EXISTS employee.enforce_branch_leave_year_config_same_org();

ANALYZE employee.branch_leave_policies;
