-- Which leave types can carry forward — configured per branch + leave type
-- (under branch leave policy / accrual rules)

ALTER TABLE employee.branch_leave_accrual_rules
  ADD COLUMN IF NOT EXISTS carry_forward_allowed BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN employee.branch_leave_accrual_rules.carry_forward_allowed IS
  'If TRUE, unused balance for this leave type may carry forward at leave year end using branch_leave_policies.carry_forward_pct / max_days. If FALSE, unused days lapse.';

COMMENT ON COLUMN employee.branch_leave_policies.carry_forward_enabled IS
  'Master switch for the branch. Carry-forward also requires carry_forward_allowed = TRUE on each leave type accrual rule.';

-- Seed sensible defaults: Paid + Casual can CF; Sick cannot
UPDATE employee.branch_leave_accrual_rules a
SET carry_forward_allowed = CASE lt.code
      WHEN 'PAID' THEN TRUE
      WHEN 'CASUAL' THEN TRUE
      WHEN 'SICK' THEN FALSE
      ELSE FALSE
    END,
    updated_at = NOW()
FROM employee.leave_types lt
WHERE lt.id = a.leave_type_id;

ANALYZE employee.branch_leave_accrual_rules;
