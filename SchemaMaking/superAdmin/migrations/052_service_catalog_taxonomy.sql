-- Super Admin platform service catalog taxonomy (2-level)
-- Category → Subcategory
-- Single-level services: same display name on both rows, different IDs
-- Salon product/service names under subcategory = later (Admin portal)

-- ---------------------------------------------------------------------------
-- Categories (level 1)
-- ---------------------------------------------------------------------------
CREATE TABLE service_categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(255) NOT NULL,
  description     TEXT,
  icon_url        TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  -- true when this category is a single-level leaf (mirrored subcategory exists with same name)
  is_single_level BOOLEAN NOT NULL DEFAULT FALSE,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_service_categories_active
  ON service_categories(is_active, sort_order);

-- ---------------------------------------------------------------------------
-- Subcategories (level 2) — always present; may mirror category name
-- ---------------------------------------------------------------------------
CREATE TABLE service_subcategories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
  code            VARCHAR(50) NOT NULL,
  name            VARCHAR(255) NOT NULL,
  description     TEXT,
  icon_url        TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  -- true when name intentionally mirrors parent category (single hierarchy)
  mirrors_category BOOLEAN NOT NULL DEFAULT FALSE,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category_id, code)
);

CREATE INDEX idx_service_subcategories_category
  ON service_subcategories(category_id, is_active, sort_order);

COMMENT ON TABLE service_categories IS
  'Super Admin master: service Category (e.g. Hair Cut). Salon products attach under subcategory later.';
COMMENT ON TABLE service_subcategories IS
  'Super Admin master: Subcategory (e.g. Men''s / Women''s). Single-level: same name as category, different id.';
COMMENT ON COLUMN service_categories.is_single_level IS
  'When true, exactly one subcategory should exist with mirrors_category=true and same display name.';

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON service_categories
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON service_categories TO authenticated;

ALTER TABLE service_subcategories ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON service_subcategories
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON service_subcategories TO authenticated;

-- ---------------------------------------------------------------------------
-- Seed — 2-level: Hair Cut → Men's / Women's
-- ---------------------------------------------------------------------------
INSERT INTO service_categories (
  id, code, name, description, is_single_level, sort_order, created_by
) VALUES (
  'fa000000-0000-4000-8000-000000000001',
  'HAIR_CUT',
  'Hair Cut',
  'Hair cutting and styling services',
  FALSE,
  10,
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO service_subcategories (
  id, category_id, code, name, mirrors_category, sort_order, created_by
) VALUES
(
  'fa000000-0000-4000-8000-000000000101',
  'fa000000-0000-4000-8000-000000000001',
  'MENS',
  'Men''s',
  FALSE,
  10,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'fa000000-0000-4000-8000-000000000102',
  'fa000000-0000-4000-8000-000000000001',
  'WOMENS',
  'Women''s',
  FALSE,
  20,
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- Seed — 2-level: Hair Color → Men's / Women's
-- ---------------------------------------------------------------------------
INSERT INTO service_categories (
  id, code, name, description, is_single_level, sort_order, created_by
) VALUES (
  'fa000000-0000-4000-8000-000000000002',
  'HAIR_COLOR',
  'Hair Color',
  'Colouring and highlights',
  FALSE,
  20,
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO service_subcategories (
  id, category_id, code, name, mirrors_category, sort_order, created_by
) VALUES
(
  'fa000000-0000-4000-8000-000000000103',
  'fa000000-0000-4000-8000-000000000002',
  'MENS',
  'Men''s',
  FALSE,
  10,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'fa000000-0000-4000-8000-000000000104',
  'fa000000-0000-4000-8000-000000000002',
  'WOMENS',
  'Women''s',
  FALSE,
  20,
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- Seed — 1-level mirror: Spa (category name = subcategory name, different IDs)
-- ---------------------------------------------------------------------------
INSERT INTO service_categories (
  id, code, name, description, is_single_level, sort_order, created_by
) VALUES (
  'fa000000-0000-4000-8000-000000000003',
  'SPA',
  'Spa',
  'Spa packages — single hierarchy (mirrored subcategory)',
  TRUE,
  30,
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO service_subcategories (
  id, category_id, code, name, mirrors_category, sort_order, created_by
) VALUES (
  'fa000000-0000-4000-8000-000000000105',
  'fa000000-0000-4000-8000-000000000003',
  'SPA',
  'Spa',
  TRUE,
  10,
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- Seed — 1-level mirror: Beard Grooming
-- ---------------------------------------------------------------------------
INSERT INTO service_categories (
  id, code, name, description, is_single_level, sort_order, created_by
) VALUES (
  'fa000000-0000-4000-8000-000000000004',
  'BEARD_GROOMING',
  'Beard Grooming',
  'Beard trim and grooming — single hierarchy',
  TRUE,
  40,
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO service_subcategories (
  id, category_id, code, name, mirrors_category, sort_order, created_by
) VALUES (
  'fa000000-0000-4000-8000-000000000106',
  'fa000000-0000-4000-8000-000000000004',
  'BEARD_GROOMING',
  'Beard Grooming',
  TRUE,
  10,
  'a1000000-0000-4000-8000-000000000001'
);

ANALYZE service_categories;
ANALYZE service_subcategories;
