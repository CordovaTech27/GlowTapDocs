-- One discount rule per (plan, cycle) pair — NULLs treated as distinct keys too

CREATE UNIQUE INDEX IF NOT EXISTS uq_billing_discount_plan_cycle
  ON billing_discount_configs (subscription_plan_id, billing_cycle_id)
  NULLS NOT DISTINCT;
