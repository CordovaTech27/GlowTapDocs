-- Master reason codes for Super Admin org lifecycle actions

CREATE TABLE reason_codes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category        VARCHAR(20) NOT NULL
    CHECK (category IN ('SUSPEND', 'RESUME', 'TERMINATE')),
  code            VARCHAR(50) NOT NULL,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  pricing_impact  JSONB,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category, code)
);
