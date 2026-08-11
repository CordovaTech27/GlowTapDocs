-- Seed demo weekly offs so branch_weekly_offs is not empty.
-- Admin can edit/delete these; new branches still start with no offs until configured.
-- Using Wednesday (3) as a demo day — NOT an automatic Sunday default.

INSERT INTO employee.branch_weekly_offs (
  organization_id,
  branch_id,
  day_of_week,
  is_active,
  effective_from,
  notes
)
SELECT
  b.organization_id,
  b.id,
  3, -- Wednesday demo weekly off (0=Sun … 6=Sat)
  TRUE,
  CURRENT_DATE,
  'Demo weekly off — change or remove in Admin → Branch settings'
FROM public.branches b
WHERE NOT EXISTS (
  SELECT 1
  FROM employee.branch_weekly_offs w
  WHERE w.branch_id = b.id
);

ANALYZE employee.branch_weekly_offs;
