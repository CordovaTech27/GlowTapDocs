-- Branch-level leave policy config
-- - Leave year ends in a configurable month (default March)
-- - Carry-forward % of unused balance at year completion
-- - Monthly accrual days per leave type

CREATE TABLE employee.branch_leave_policies (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id               UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  -- Leave year ends at end of this month (1=Jan … 12=Dec). March = 3.
  leave_year_end_month    SMALLINT NOT NULL DEFAULT 3
    CHECK (leave_year_end_month BETWEEN 1 AND 12),
  leave_year_end_day      SMALLINT NOT NULL DEFAULT 31
    CHECK (leave_year_end_day BETWEEN 1 AND 31),
  carry_forward_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
  -- % of unused balance that may carry to next leave year (0–100)
  carry_forward_pct       NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (carry_forward_pct >= 0 AND carry_forward_pct <= 100),
  -- Optional hard cap on days carried (NULL = no cap beyond %)
  carry_forward_max_days  NUMERIC(6, 2),
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (branch_id)
);

COMMENT ON TABLE employee.branch_leave_policies IS
  'Per-branch leave year settings: year-end month (e.g. March), carry-forward %, active flag';

COMMENT ON COLUMN employee.branch_leave_policies.leave_year_end_month IS
  'Month when leave year completes (default 3 = March). Next leave year starts the following day.';

COMMENT ON COLUMN employee.branch_leave_policies.carry_forward_pct IS
  'Percentage of unused leave that carries forward at year end (0–100).';

CREATE INDEX idx_branch_leave_policies_org
  ON employee.branch_leave_policies(organization_id);

-- Monthly accrual: how many days added each month per leave type at this branch
CREATE TABLE employee.branch_leave_accrual_rules (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id               UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  leave_type_id           UUID NOT NULL REFERENCES employee.leave_types(id) ON DELETE CASCADE,
  days_per_month          NUMERIC(6, 2) NOT NULL DEFAULT 0
    CHECK (days_per_month >= 0),
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (branch_id, leave_type_id)
);

COMMENT ON TABLE employee.branch_leave_accrual_rules IS
  'Per branch + leave type: how many leave days are credited each calendar month';

COMMENT ON COLUMN employee.branch_leave_accrual_rules.days_per_month IS
  'Days added to employee balance each month for this leave type at this branch';

CREATE INDEX idx_branch_leave_accrual_branch
  ON employee.branch_leave_accrual_rules(branch_id);

-- Same-org checks
CREATE OR REPLACE FUNCTION employee.enforce_branch_leave_policy_same_org()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_policies: branch must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_branch_leave_policy_same_org
  BEFORE INSERT OR UPDATE OF organization_id, branch_id ON employee.branch_leave_policies
  FOR EACH ROW EXECUTE FUNCTION employee.enforce_branch_leave_policy_same_org();

CREATE OR REPLACE FUNCTION employee.enforce_branch_leave_accrual_same_org()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
  type_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  SELECT organization_id INTO type_org FROM employee.leave_types WHERE id = NEW.leave_type_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_accrual_rules: branch must belong to the same organization';
  END IF;
  IF type_org IS NULL OR type_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_accrual_rules: leave_type must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_branch_leave_accrual_same_org
  BEFORE INSERT OR UPDATE OF organization_id, branch_id, leave_type_id
  ON employee.branch_leave_accrual_rules
  FOR EACH ROW EXECUTE FUNCTION employee.enforce_branch_leave_accrual_same_org();

GRANT SELECT, INSERT, UPDATE, DELETE ON employee.branch_leave_policies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON employee.branch_leave_accrual_rules TO authenticated;

-- Seed: one policy example for each branch that has leave types in its org
-- Year end = March, carry forward 50%, sample monthly accruals
DO $$
DECLARE
  r RECORD;
  lt RECORD;
  policy_exists BOOLEAN;
BEGIN
  FOR r IN
    SELECT b.id AS branch_id, b.organization_id
    FROM public.branches b
  LOOP
    INSERT INTO employee.branch_leave_policies (
      organization_id,
      branch_id,
      leave_year_end_month,
      leave_year_end_day,
      carry_forward_enabled,
      carry_forward_pct,
      carry_forward_max_days,
      notes
    ) VALUES (
      r.organization_id,
      r.branch_id,
      3,          -- March
      31,
      TRUE,
      50.00,      -- 50% carry forward
      6.00,       -- max 6 days CF
      'Default: leave year ends 31 Mar; 50% CF capped at 6 days'
    )
    ON CONFLICT (branch_id) DO UPDATE
      SET leave_year_end_month = EXCLUDED.leave_year_end_month,
          carry_forward_enabled = EXCLUDED.carry_forward_enabled,
          carry_forward_pct = EXCLUDED.carry_forward_pct,
          carry_forward_max_days = EXCLUDED.carry_forward_max_days,
          notes = EXCLUDED.notes,
          updated_at = NOW();

    -- Accrual rules only if this org has leave types
    FOR lt IN
      SELECT id, code FROM employee.leave_types
      WHERE organization_id = r.organization_id AND is_active = TRUE
    LOOP
      INSERT INTO employee.branch_leave_accrual_rules (
        organization_id, branch_id, leave_type_id, days_per_month, carry_forward_allowed, notes
      ) VALUES (
        r.organization_id,
        r.branch_id,
        lt.id,
        CASE lt.code
          WHEN 'SICK' THEN 0.50
          WHEN 'CASUAL' THEN 0.50
          WHEN 'PAID' THEN 1.00
          ELSE 0.50
        END,
        CASE lt.code
          WHEN 'PAID' THEN TRUE
          WHEN 'CASUAL' THEN TRUE
          ELSE FALSE
        END,
        'Monthly accrual for ' || lt.code
      )
      ON CONFLICT (branch_id, leave_type_id) DO UPDATE
        SET days_per_month = EXCLUDED.days_per_month,
            carry_forward_allowed = EXCLUDED.carry_forward_allowed,
            notes = EXCLUDED.notes,
            updated_at = NOW();
    END LOOP;
  END LOOP;
END $$;

ANALYZE employee.branch_leave_policies;
ANALYZE employee.branch_leave_accrual_rules;
