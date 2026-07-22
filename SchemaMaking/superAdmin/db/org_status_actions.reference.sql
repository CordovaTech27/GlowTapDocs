-- Org suspend / resume / terminate action audit log

CREATE TABLE org_status_actions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  action           VARCHAR(20) NOT NULL
    CHECK (action IN ('SUSPEND', 'RESUME', 'TERMINATE')),
  from_status      VARCHAR(20) NOT NULL,
  to_status        VARCHAR(20) NOT NULL,
  reason_code_id   UUID REFERENCES reason_codes(id),
  notes            TEXT,
  performed_by     UUID REFERENCES super_admin_users(id),
  performed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
