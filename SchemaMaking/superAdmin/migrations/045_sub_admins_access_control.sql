-- §4.8 User Access Control
-- Salon Admin = organizations.owner_* (+ portal status columns)
-- Sub Admins = created under org with branch + module access

-- ---------------------------------------------------------------------------
-- Salon Admin portal fields on organizations (profile stays owner_*)
-- ---------------------------------------------------------------------------
ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS owner_portal_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (owner_portal_status IN ('ACTIVE', 'DISABLED')),
  ADD COLUMN IF NOT EXISTS owner_last_login_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS owner_disabled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS owner_disabled_by UUID REFERENCES super_admin_users(id);

COMMENT ON COLUMN organizations.owner_portal_status IS
  'Salon Admin login gate. DISABLED blocks portal without deleting org/owner data.';

-- ---------------------------------------------------------------------------
-- Sub Admins (created by Salon Admin; Super Admin view + disable only)
-- ---------------------------------------------------------------------------
CREATE TABLE sub_admins (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  full_name                   VARCHAR(255) NOT NULL,
  email                       VARCHAR(255) NOT NULL,
  phone                       VARCHAR(20),
  status                      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'DISABLED')),
  -- Who last disabled (Salon Admin owns day-to-day; Super Admin for fraud)
  disabled_by_role            VARCHAR(20)
    CHECK (disabled_by_role IS NULL OR disabled_by_role IN ('SALON_ADMIN', 'SUPER_ADMIN')),
  disabled_at                 TIMESTAMPTZ,
  disabled_by_super_admin_id  UUID REFERENCES super_admin_users(id),
  last_login_at               TIMESTAMPTZ,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, email)
);

CREATE INDEX idx_sub_admins_org_status
  ON sub_admins(organization_id, status);
CREATE INDEX idx_sub_admins_email
  ON sub_admins(email);

-- Branch access (must belong to same org — enforced in app + trigger)
CREATE TABLE sub_admin_branches (
  sub_admin_id  UUID NOT NULL REFERENCES sub_admins(id) ON DELETE CASCADE,
  branch_id     UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (sub_admin_id, branch_id)
);

CREATE INDEX idx_sub_admin_branches_branch
  ON sub_admin_branches(branch_id);

CREATE OR REPLACE FUNCTION enforce_sub_admin_branch_same_org()
RETURNS TRIGGER AS $$
DECLARE
  admin_org UUID;
  branch_org UUID;
BEGIN
  SELECT organization_id INTO admin_org FROM sub_admins WHERE id = NEW.sub_admin_id;
  SELECT organization_id INTO branch_org FROM branches WHERE id = NEW.branch_id;
  IF admin_org IS NULL OR branch_org IS NULL OR admin_org <> branch_org THEN
    RAISE EXCEPTION 'sub_admin_branches: branch must belong to the same organization as sub_admin';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sub_admin_branch_same_org
  BEFORE INSERT OR UPDATE ON sub_admin_branches
  FOR EACH ROW EXECUTE FUNCTION enforce_sub_admin_branch_same_org();

-- Module permissions (Admin Functional Spec §2.1)
CREATE TABLE sub_admin_modules (
  sub_admin_id  UUID NOT NULL REFERENCES sub_admins(id) ON DELETE CASCADE,
  module        VARCHAR(30) NOT NULL
    CHECK (module IN (
      'BRANCH_PROFILE',
      'EMPLOYEES',
      'LEAVE_HOLIDAYS',
      'ATTENDANCE',
      'SERVICES',
      'APPOINTMENTS',
      'TRANSACTIONS',
      'REPORTS'
    )),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (sub_admin_id, module)
);

-- ---------------------------------------------------------------------------
-- Audit: Super Admin (and future Salon Admin) access actions
-- ---------------------------------------------------------------------------
CREATE TABLE user_access_actions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  target_type           VARCHAR(20) NOT NULL
    CHECK (target_type IN ('SALON_ADMIN', 'SUB_ADMIN')),
  sub_admin_id          UUID REFERENCES sub_admins(id) ON DELETE SET NULL,
  action                VARCHAR(30) NOT NULL
    CHECK (action IN (
      'DISABLE', 'ENABLE', 'RESET_PASSWORD', 'UPDATE_CONTACT', 'UPDATE_EMAIL'
    )),
  reason                TEXT,
  metadata              JSONB,
  performed_by          UUID REFERENCES super_admin_users(id),
  performed_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_access_actions_org
  ON user_access_actions(organization_id, performed_at DESC);
CREATE INDEX idx_user_access_actions_sub
  ON user_access_actions(sub_admin_id, performed_at DESC)
  WHERE sub_admin_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- RLS / Data API
-- ---------------------------------------------------------------------------
ALTER TABLE sub_admins ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON sub_admins
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON sub_admins TO authenticated;

ALTER TABLE sub_admin_branches ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON sub_admin_branches
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON sub_admin_branches TO authenticated;

ALTER TABLE sub_admin_modules ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON sub_admin_modules
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON sub_admin_modules TO authenticated;

ALTER TABLE user_access_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON user_access_actions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON user_access_actions TO authenticated;

-- ---------------------------------------------------------------------------
-- MOCK — Looks: two sub-admins with different branch/module scopes
-- ---------------------------------------------------------------------------
INSERT INTO sub_admins (
  id, organization_id, full_name, email, phone, status, last_login_at
) VALUES
(
  'f6000000-0000-4000-8000-000000000001',
  'b1000000-0000-4000-8000-000000000001',
  'Ananya Shah',
  'ananya.manager@lookssalon.in',
  '+91 98201 11101',
  'ACTIVE',
  TIMESTAMPTZ '2026-07-21 09:15:00+05:30'
),
(
  'f6000000-0000-4000-8000-000000000002',
  'b1000000-0000-4000-8000-000000000001',
  'Rohan Desai',
  'rohan.bandra@lookssalon.in',
  '+91 98201 11102',
  'ACTIVE',
  TIMESTAMPTZ '2026-07-20 18:40:00+05:30'
);

-- Ananya: Andheri + Bandra — appointments/services/employees/reports
INSERT INTO sub_admin_branches (sub_admin_id, branch_id) VALUES
('f6000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000001'),
('f6000000-0000-4000-8000-000000000001', 'c1000000-0000-4000-8000-000000000002');

INSERT INTO sub_admin_modules (sub_admin_id, module) VALUES
('f6000000-0000-4000-8000-000000000001', 'EMPLOYEES'),
('f6000000-0000-4000-8000-000000000001', 'SERVICES'),
('f6000000-0000-4000-8000-000000000001', 'APPOINTMENTS'),
('f6000000-0000-4000-8000-000000000001', 'REPORTS');

-- Rohan: Bandra only — front-desk modules
INSERT INTO sub_admin_branches (sub_admin_id, branch_id) VALUES
('f6000000-0000-4000-8000-000000000002', 'c1000000-0000-4000-8000-000000000002');

INSERT INTO sub_admin_modules (sub_admin_id, module) VALUES
('f6000000-0000-4000-8000-000000000002', 'BRANCH_PROFILE'),
('f6000000-0000-4000-8000-000000000002', 'APPOINTMENTS'),
('f6000000-0000-4000-8000-000000000002', 'TRANSACTIONS'),
('f6000000-0000-4000-8000-000000000002', 'ATTENDANCE');

-- ---------------------------------------------------------------------------
-- MOCK — Enrich: one sub-admin on Koramangala; one Super-Admin-disabled
-- ---------------------------------------------------------------------------
INSERT INTO sub_admins (
  id, organization_id, full_name, email, phone, status,
  disabled_by_role, disabled_at, disabled_by_super_admin_id, last_login_at
) VALUES
(
  'f6000000-0000-4000-8000-000000000003',
  'b1000000-0000-4000-8000-000000000003',
  'Sneha Iyer',
  'sneha@enrichsalon.com',
  '+91 98450 22001',
  'ACTIVE',
  NULL, NULL, NULL,
  TIMESTAMPTZ '2026-07-19 11:00:00+05:30'
),
(
  'f6000000-0000-4000-8000-000000000004',
  'b1000000-0000-4000-8000-000000000003',
  'Vikram Rao',
  'vikram.suspended@enrichsalon.com',
  '+91 98450 22002',
  'DISABLED',
  'SUPER_ADMIN',
  TIMESTAMPTZ '2026-07-15 16:20:00+05:30',
  'a1000000-0000-4000-8000-000000000001',
  TIMESTAMPTZ '2026-07-14 20:05:00+05:30'
);

INSERT INTO sub_admin_branches (sub_admin_id, branch_id) VALUES
('f6000000-0000-4000-8000-000000000003', 'c1000000-0000-4000-8000-000000000006'),
('f6000000-0000-4000-8000-000000000004', 'c1000000-0000-4000-8000-000000000006');

INSERT INTO sub_admin_modules (sub_admin_id, module) VALUES
('f6000000-0000-4000-8000-000000000003', 'EMPLOYEES'),
('f6000000-0000-4000-8000-000000000003', 'LEAVE_HOLIDAYS'),
('f6000000-0000-4000-8000-000000000003', 'ATTENDANCE'),
('f6000000-0000-4000-8000-000000000003', 'SERVICES'),
('f6000000-0000-4000-8000-000000000003', 'APPOINTMENTS'),
('f6000000-0000-4000-8000-000000000004', 'APPOINTMENTS'),
('f6000000-0000-4000-8000-000000000004', 'TRANSACTIONS');

INSERT INTO user_access_actions (
  id, organization_id, target_type, sub_admin_id, action, reason, performed_by, performed_at
) VALUES (
  'f6000000-0000-4000-8000-000000000101',
  'b1000000-0000-4000-8000-000000000003',
  'SUB_ADMIN',
  'f6000000-0000-4000-8000-000000000004',
  'DISABLE',
  'Suspected credential sharing / policy violation',
  'a1000000-0000-4000-8000-000000000001',
  TIMESTAMPTZ '2026-07-15 16:20:00+05:30'
);

-- Seed last login on Looks salon admin (org owner)
UPDATE organizations
SET owner_last_login_at = TIMESTAMPTZ '2026-07-21 08:55:00+05:30'
WHERE id = 'b1000000-0000-4000-8000-000000000001';

ANALYZE sub_admins;
ANALYZE sub_admin_branches;
ANALYZE sub_admin_modules;
ANALYZE user_access_actions;
