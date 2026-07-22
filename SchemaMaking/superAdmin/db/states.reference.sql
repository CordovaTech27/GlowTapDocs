-- Indian GST states / UTs master (post migration 013)

CREATE TABLE states (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                VARCHAR(2) NOT NULL UNIQUE,
  name                VARCHAR(100) NOT NULL,
  iso_code            VARCHAR(3),
  is_union_territory  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
