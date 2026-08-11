-- Simplify weekly offs: branch-level only (all employees follow).
-- Remove employee-level weekly-off override.
-- Seed richer branch holiday + weekly-off data.

-- Drop emp override table
DROP TABLE IF EXISTS employee.employee_weekly_offs;

-- Remove override flag from employees
ALTER TABLE employee.employees
  DROP COLUMN IF EXISTS follow_branch_weekly_off;

COMMENT ON TABLE employee.branch_weekly_offs IS
  'Branch weekly offs — all employees at the branch must follow; no emp-level override';

COMMENT ON TABLE employee.branch_holidays IS
  'Branch holidays — all employees at the branch must follow';

-- Seed holidays only (NOT weekly offs — admin configures off days per branch)
DO $$
DECLARE
  r RECORD;
  y INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
BEGIN
  FOR r IN
    SELECT b.id AS branch_id, b.organization_id
    FROM public.branches b
  LOOP
    -- Common Indian / salon holidays for current year
    INSERT INTO employee.branch_holidays (
      organization_id, branch_id, holiday_date, name, is_recurring_annual, notes
    ) VALUES
      (r.organization_id, r.branch_id, make_date(y, 1, 26), 'Republic Day', TRUE, NULL),
      (r.organization_id, r.branch_id, make_date(y, 3, 14), 'Holi', FALSE, 'Date varies yearly — adjust as needed'),
      (r.organization_id, r.branch_id, make_date(y, 8, 15), 'Independence Day', TRUE, NULL),
      (r.organization_id, r.branch_id, make_date(y, 10, 2), 'Gandhi Jayanti', TRUE, NULL),
      (r.organization_id, r.branch_id, make_date(y, 10, 20), 'Diwali', FALSE, 'Date varies yearly — adjust as needed'),
      (r.organization_id, r.branch_id, make_date(y, 12, 25), 'Christmas', TRUE, NULL)
    ON CONFLICT (branch_id, holiday_date) DO UPDATE
      SET name = EXCLUDED.name,
          is_recurring_annual = EXCLUDED.is_recurring_annual,
          notes = EXCLUDED.notes,
          updated_at = NOW();
  END LOOP;
END $$;

ANALYZE employee.branch_weekly_offs;
ANALYZE employee.branch_holidays;
ANALYZE employee.employees;
