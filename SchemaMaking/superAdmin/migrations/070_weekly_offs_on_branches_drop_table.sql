-- Move weekly offs onto public.branches and drop employee.branch_weekly_offs

ALTER TABLE public.branches
  ADD COLUMN IF NOT EXISTS weekly_off_days SMALLINT[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.branches.weekly_off_days IS
  'Weekly off day(s) for the branch (0=Sun … 6=Sat). Empty = no weekly off configured. All employees at the branch follow these days.';

-- Migrate existing active offs from employee.branch_weekly_offs
UPDATE public.branches b
SET weekly_off_days = sub.days,
    updated_at = NOW()
FROM (
  SELECT
    branch_id,
    COALESCE(
      array_agg(day_of_week ORDER BY day_of_week)
        FILTER (WHERE is_active = TRUE),
      '{}'::smallint[]
    ) AS days
  FROM employee.branch_weekly_offs
  GROUP BY branch_id
) sub
WHERE b.id = sub.branch_id;

-- Constraint: each day must be 0–6
ALTER TABLE public.branches
  DROP CONSTRAINT IF EXISTS branches_weekly_off_days_valid;

ALTER TABLE public.branches
  ADD CONSTRAINT branches_weekly_off_days_valid
  CHECK (
    weekly_off_days <@ ARRAY[0,1,2,3,4,5,6]::smallint[]
  );

DROP TABLE IF EXISTS employee.branch_weekly_offs;

ANALYZE public.branches;
