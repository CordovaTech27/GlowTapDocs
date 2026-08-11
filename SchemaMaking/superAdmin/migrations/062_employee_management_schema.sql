-- Employee management (Admin Functional Spec §4.7–4.9)
-- Schema: employee
-- Each employee tagged to public.organizations + public.branches
-- Branch weekly offs = default; employee can override
-- Branch holidays apply to all staff at that branch

CREATE SCHEMA IF NOT EXISTS employee;

COMMENT ON SCHEMA employee IS
  'Salon staff — employees, weekly offs, leave, holidays, attendance';

-- ---------------------------------------------------------------------------
-- 1. Employees (onboard / edit / deactivate)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.employees (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id             UUID NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  employee_number       VARCHAR(30) NOT NULL,
  full_name             VARCHAR(255) NOT NULL,
  email                 VARCHAR(255),
  phone                 VARCHAR(20),
  designation           VARCHAR(100),
  photo_url             TEXT,
  date_of_joining       DATE NOT NULL DEFAULT CURRENT_DATE,
  date_of_exit          DATE,
  -- When TRUE → inherit branch_weekly_offs; when FALSE → use employee_weekly_offs
  follow_branch_weekly_off BOOLEAN NOT NULL DEFAULT TRUE,
  status                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'INACTIVE')),
  notes                 TEXT,
  deactivated_at        TIMESTAMPTZ,
  deactivated_reason    TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, employee_number),
  UNIQUE (organization_id, email)
);

CREATE INDEX idx_employees_org_branch_status
  ON employee.employees(organization_id, branch_id, status);
CREATE INDEX idx_employees_branch
  ON employee.employees(branch_id);

COMMENT ON COLUMN employee.employees.follow_branch_weekly_off IS
  'TRUE = use branch_weekly_offs; FALSE = use employee_weekly_offs override rows';

-- Same-org: branch must belong to employee org
CREATE OR REPLACE FUNCTION employee.enforce_employee_branch_same_org()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'employees: branch must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_employee_branch_same_org
  BEFORE INSERT OR UPDATE OF organization_id, branch_id ON employee.employees
  FOR EACH ROW EXECUTE FUNCTION employee.enforce_employee_branch_same_org();

-- ---------------------------------------------------------------------------
-- 2. Branch weekly offs (parent / default for all emp at branch)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.branch_weekly_offs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id         UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  -- 0=Sunday … 6=Saturday (ISO-friendly apps often use 1=Mon…7=Sun; we use JS-style 0–6)
  day_of_week       SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  effective_from    DATE NOT NULL DEFAULT CURRENT_DATE,
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (branch_id, day_of_week)
);

CREATE INDEX idx_branch_weekly_offs_org
  ON employee.branch_weekly_offs(organization_id, branch_id);

-- ---------------------------------------------------------------------------
-- 3. Employee weekly off overrides (when follow_branch_weekly_off = FALSE)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.employee_weekly_offs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id       UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  day_of_week       SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  -- Spec: weekly-off edit applies from next calendar day (enforce in app)
  effective_from    DATE NOT NULL DEFAULT CURRENT_DATE,
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (employee_id, day_of_week)
);

CREATE INDEX idx_employee_weekly_offs_emp
  ON employee.employee_weekly_offs(employee_id);

-- ---------------------------------------------------------------------------
-- 4. Branch holidays (all employees at branch follow)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.branch_holidays (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id           UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  holiday_date        DATE NOT NULL,
  name                VARCHAR(255) NOT NULL,
  is_recurring_annual BOOLEAN NOT NULL DEFAULT FALSE,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (branch_id, holiday_date)
);

CREATE INDEX idx_branch_holidays_branch_date
  ON employee.branch_holidays(branch_id, holiday_date);

-- ---------------------------------------------------------------------------
-- 5. Leave types (org-level catalog — Sick / Casual / Paid)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.leave_types (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  code              VARCHAR(30) NOT NULL,
  name              VARCHAR(100) NOT NULL,
  description       TEXT,
  is_paid           BOOLEAN NOT NULL DEFAULT TRUE,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order        INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, code)
);

-- ---------------------------------------------------------------------------
-- 6. Leave balances (standard SaaS annual entitlement)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.leave_balances (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id       UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  leave_type_id     UUID NOT NULL REFERENCES employee.leave_types(id) ON DELETE CASCADE,
  year              INT NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  entitled_days     NUMERIC(6, 2) NOT NULL DEFAULT 0,
  used_days         NUMERIC(6, 2) NOT NULL DEFAULT 0,
  carried_forward   NUMERIC(6, 2) NOT NULL DEFAULT 0,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (employee_id, leave_type_id, year)
);

-- ---------------------------------------------------------------------------
-- 7. Leave applications / requests
-- ---------------------------------------------------------------------------
CREATE TABLE employee.leave_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id         UUID NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  employee_id       UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  leave_type_id     UUID NOT NULL REFERENCES employee.leave_types(id),
  start_date        DATE NOT NULL,
  end_date          DATE NOT NULL,
  total_days        NUMERIC(6, 2) NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
  reason            TEXT,
  admin_note        TEXT,
  decided_by_ref    VARCHAR(100),
  decided_at        TIMESTAMPTZ,
  cancelled_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (end_date >= start_date)
);

CREATE INDEX idx_leave_requests_emp_dates
  ON employee.leave_requests(employee_id, start_date, end_date);
CREATE INDEX idx_leave_requests_org_status
  ON employee.leave_requests(organization_id, status);
CREATE INDEX idx_leave_requests_branch
  ON employee.leave_requests(branch_id, start_date);

-- ---------------------------------------------------------------------------
-- 8. Attendance (mark in/out + status)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.attendance_records (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id         UUID NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  employee_id       UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  attendance_date   DATE NOT NULL,
  check_in_at       TIMESTAMPTZ,
  check_out_at      TIMESTAMPTZ,
  status            VARCHAR(20) NOT NULL DEFAULT 'PRESENT'
    CHECK (status IN (
      'PRESENT', 'ABSENT', 'HALF_DAY', 'ON_LEAVE', 'WEEKLY_OFF', 'HOLIDAY'
    )),
  source            VARCHAR(20) NOT NULL DEFAULT 'MANUAL'
    CHECK (source IN ('MANUAL', 'SYSTEM', 'BIOMETRIC', 'GEO')),
  notes             TEXT,
  marked_by_ref     VARCHAR(100),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (employee_id, attendance_date),
  CHECK (check_out_at IS NULL OR check_in_at IS NULL OR check_out_at >= check_in_at)
);

CREATE INDEX idx_attendance_branch_date
  ON employee.attendance_records(branch_id, attendance_date);
CREATE INDEX idx_attendance_org_date
  ON employee.attendance_records(organization_id, attendance_date);

-- ---------------------------------------------------------------------------
-- 9. Attendance edit audit (spec: edit with audit log)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.attendance_audit_actions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_id     UUID NOT NULL REFERENCES employee.attendance_records(id) ON DELETE CASCADE,
  action            VARCHAR(30) NOT NULL
    CHECK (action IN ('CREATE', 'UPDATE', 'DELETE')),
  before_data       JSONB,
  after_data        JSONB,
  reason            TEXT,
  performed_by_ref  VARCHAR(100),
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attendance_audit_att
  ON employee.attendance_audit_actions(attendance_id, performed_at DESC);

-- ---------------------------------------------------------------------------
-- 10. Employee lifecycle audit (deactivate / reactivate / transfer)
-- ---------------------------------------------------------------------------
CREATE TABLE employee.employee_actions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  employee_id       UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  action            VARCHAR(30) NOT NULL
    CHECK (action IN (
      'CREATE', 'UPDATE', 'DEACTIVATE', 'REACTIVATE', 'TRANSFER_BRANCH', 'WEEKLY_OFF_CHANGE'
    )),
  reason            TEXT,
  metadata          JSONB,
  performed_by_ref  VARCHAR(100),
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_employee_actions_emp
  ON employee.employee_actions(employee_id, performed_at DESC);

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA employee TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA employee TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA employee
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA employee TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA employee
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- ---------------------------------------------------------------------------
-- Seed: leave types + sample staff for Glamour (if org exists)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  org_id UUID;
  br_id UUID;
  emp1 UUID := 'f1000000-0000-4000-8000-000000000001';
  emp2 UUID := 'f1000000-0000-4000-8000-000000000002';
  lt_sick UUID;
  lt_casual UUID;
  lt_paid UUID;
BEGIN
  SELECT id INTO org_id FROM public.organizations
  WHERE id = 'a1000000-0000-4000-8000-000000000001' LIMIT 1;
  IF org_id IS NULL THEN
    SELECT id INTO org_id FROM public.organizations ORDER BY created_at LIMIT 1;
  END IF;
  IF org_id IS NULL THEN
    RAISE NOTICE 'No organizations — skip employee seed';
    RETURN;
  END IF;

  SELECT id INTO br_id FROM public.branches
  WHERE organization_id = org_id AND is_primary = TRUE LIMIT 1;
  IF br_id IS NULL THEN
    SELECT id INTO br_id FROM public.branches WHERE organization_id = org_id LIMIT 1;
  END IF;
  IF br_id IS NULL THEN
    RAISE NOTICE 'No branches — skip employee seed';
    RETURN;
  END IF;

  INSERT INTO employee.leave_types (organization_id, code, name, is_paid, sort_order)
  VALUES
    (org_id, 'SICK', 'Sick Leave', TRUE, 10),
    (org_id, 'CASUAL', 'Casual Leave', TRUE, 20),
    (org_id, 'PAID', 'Paid Leave', TRUE, 30)
  ON CONFLICT (organization_id, code) DO NOTHING;

  SELECT id INTO lt_sick FROM employee.leave_types WHERE organization_id = org_id AND code = 'SICK';
  SELECT id INTO lt_casual FROM employee.leave_types WHERE organization_id = org_id AND code = 'CASUAL';
  SELECT id INTO lt_paid FROM employee.leave_types WHERE organization_id = org_id AND code = 'PAID';

  -- Branch weekly offs: do NOT seed — admin configures day(s) per branch (no default Sunday)

  -- Branch holiday sample
  INSERT INTO employee.branch_holidays (organization_id, branch_id, holiday_date, name, is_recurring_annual)
  VALUES (org_id, br_id, DATE '2026-08-15', 'Independence Day', TRUE)
  ON CONFLICT (branch_id, holiday_date) DO NOTHING;

  INSERT INTO employee.employees (
    id, organization_id, branch_id, employee_number, full_name, email, phone,
    designation, date_of_joining, status
  ) VALUES
    (emp1, org_id, br_id, 'EMP-00001', 'Priya Sharma', 'priya.s@glamour.example', '9876500001',
     'Senior Stylist', DATE '2025-01-15', 'ACTIVE'),
    (emp2, org_id, br_id, 'EMP-00002', 'Rahul Verma', 'rahul.v@glamour.example', '9876500002',
     'Therapist', DATE '2025-03-01', 'ACTIVE')
  ON CONFLICT (organization_id, employee_number) DO NOTHING;

  IF lt_sick IS NOT NULL THEN
    INSERT INTO employee.leave_balances (employee_id, leave_type_id, year, entitled_days, used_days)
    VALUES
      (emp1, lt_sick, 2026, 6, 0),
      (emp1, lt_casual, 2026, 6, 1),
      (emp1, lt_paid, 2026, 12, 0),
      (emp2, lt_sick, 2026, 6, 0),
      (emp2, lt_casual, 2026, 6, 0),
      (emp2, lt_paid, 2026, 12, 2)
    ON CONFLICT (employee_id, leave_type_id, year) DO NOTHING;
  END IF;

  INSERT INTO employee.leave_requests (
    organization_id, branch_id, employee_id, leave_type_id,
    start_date, end_date, total_days, status, reason, decided_at, decided_by_ref
  )
  SELECT org_id, br_id, emp1, lt_casual,
         DATE '2026-07-10', DATE '2026-07-10', 1, 'APPROVED',
         'Personal work', NOW() - INTERVAL '20 days', 'salon_admin'
  WHERE lt_casual IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM employee.leave_requests
      WHERE employee_id = emp1 AND start_date = DATE '2026-07-10'
    );

  INSERT INTO employee.attendance_records (
    organization_id, branch_id, employee_id, attendance_date,
    check_in_at, check_out_at, status, source, marked_by_ref
  ) VALUES
    (org_id, br_id, emp1, CURRENT_DATE - 1,
     (CURRENT_DATE - 1) + TIME '10:05', (CURRENT_DATE - 1) + TIME '19:10',
     'PRESENT', 'MANUAL', 'salon_admin'),
    (org_id, br_id, emp2, CURRENT_DATE - 1,
     NULL, NULL, 'ABSENT', 'MANUAL', 'salon_admin')
  ON CONFLICT (employee_id, attendance_date) DO NOTHING;

  INSERT INTO employee.employee_actions (
    organization_id, employee_id, action, reason, performed_by_ref
  )
  SELECT org_id, emp1, 'CREATE', 'Onboarded', 'salon_admin'
  WHERE EXISTS (SELECT 1 FROM employee.employees WHERE id = emp1)
    AND NOT EXISTS (
      SELECT 1 FROM employee.employee_actions WHERE employee_id = emp1 AND action = 'CREATE'
    );

  INSERT INTO employee.employee_actions (
    organization_id, employee_id, action, reason, performed_by_ref
  )
  SELECT org_id, emp2, 'CREATE', 'Onboarded', 'salon_admin'
  WHERE EXISTS (SELECT 1 FROM employee.employees WHERE id = emp2)
    AND NOT EXISTS (
      SELECT 1 FROM employee.employee_actions WHERE employee_id = emp2 AND action = 'CREATE'
    );
END $$;

ANALYZE employee.employees;
ANALYZE employee.branch_weekly_offs;
ANALYZE employee.employee_weekly_offs;
ANALYZE employee.branch_holidays;
ANALYZE employee.leave_types;
ANALYZE employee.leave_balances;
ANALYZE employee.leave_requests;
ANALYZE employee.attendance_records;
ANALYZE employee.attendance_audit_actions;
ANALYZE employee.employee_actions;
