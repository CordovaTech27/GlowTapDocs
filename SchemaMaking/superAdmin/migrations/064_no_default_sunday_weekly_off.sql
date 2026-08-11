-- Weekly offs are opt-in: no default Sunday off.
-- Admin must explicitly configure day(s) per branch.
-- Clear previously seeded default Sunday offs.

DELETE FROM employee.branch_weekly_offs
WHERE notes = 'Default Sunday weekly off'
   OR (day_of_week = 0 AND notes ILIKE '%default%sunday%');

-- If any leftover auto-seeded Sunday-only rows remain with no custom notes, remove those too
-- (keep rows that admins may have intentionally set — we only wipe the known seed)
-- Already handled above. For fresh DBs that only have seed Sundays:
DELETE FROM employee.branch_weekly_offs
WHERE day_of_week = 0
  AND (notes IS NULL OR notes = 'Default Sunday weekly off');

COMMENT ON TABLE employee.branch_weekly_offs IS
  'Branch weekly offs — opt-in. No default day. Admin configures which day(s) are off; all employees at the branch follow.';

ANALYZE employee.branch_weekly_offs;
