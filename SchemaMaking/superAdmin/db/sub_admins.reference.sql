-- admin_org — Salon Admin portal access (not Super Admin)
-- FKs → public.organizations / public.branches / public.super_admin_users
-- Salon Admin profile itself = public.organizations.owner_*

CREATE TABLE admin_org.sub_admins (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id             UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  full_name                   VARCHAR(255) NOT NULL,
  email                       VARCHAR(255) NOT NULL,
  phone                       VARCHAR(20),
  status                      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  disabled_by_role            VARCHAR(20),
  disabled_at                 TIMESTAMPTZ,
  disabled_by_super_admin_id  UUID REFERENCES public.super_admin_users(id),
  last_login_at               TIMESTAMPTZ,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, email)
);

CREATE TABLE admin_org.sub_admin_branches (
  sub_admin_id  UUID NOT NULL REFERENCES admin_org.sub_admins(id) ON DELETE CASCADE,
  branch_id     UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (sub_admin_id, branch_id)
);

CREATE TABLE admin_org.sub_admin_modules (
  sub_admin_id  UUID NOT NULL REFERENCES admin_org.sub_admins(id) ON DELETE CASCADE,
  module        VARCHAR(30) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (sub_admin_id, module)
);

-- Shared access audit lives in public (not admin_org)
CREATE TABLE public.user_access_actions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  target_type           VARCHAR(20) NOT NULL,
  sub_admin_id          UUID REFERENCES admin_org.sub_admins(id) ON DELETE SET NULL,
  action                VARCHAR(30) NOT NULL,
  reason                TEXT,
  metadata              JSONB,
  performed_by          UUID REFERENCES public.super_admin_users(id),
  performed_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
