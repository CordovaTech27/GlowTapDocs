CREATE TABLE sub_admins (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  full_name                   VARCHAR(255) NOT NULL,
  email                       VARCHAR(255) NOT NULL,
  phone                       VARCHAR(20),
  status                      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  disabled_by_role            VARCHAR(20),
  disabled_at                 TIMESTAMPTZ,
  disabled_by_super_admin_id  UUID REFERENCES super_admin_users(id),
  last_login_at               TIMESTAMPTZ,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, email)
);

CREATE TABLE sub_admin_branches (
  sub_admin_id  UUID NOT NULL REFERENCES sub_admins(id) ON DELETE CASCADE,
  branch_id     UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (sub_admin_id, branch_id)
);

CREATE TABLE sub_admin_modules (
  sub_admin_id  UUID NOT NULL REFERENCES sub_admins(id) ON DELETE CASCADE,
  module        VARCHAR(30) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (sub_admin_id, module)
);

CREATE TABLE user_access_actions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  target_type           VARCHAR(20) NOT NULL,
  sub_admin_id          UUID REFERENCES sub_admins(id) ON DELETE SET NULL,
  action                VARCHAR(30) NOT NULL,
  reason                TEXT,
  metadata              JSONB,
  performed_by          UUID REFERENCES super_admin_users(id),
  performed_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
