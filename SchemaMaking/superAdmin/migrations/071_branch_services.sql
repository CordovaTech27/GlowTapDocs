-- Branch services offered by Salon Admin (Admin Spec §4.10)
-- Admin picks platform category + subcategory, then defines branch-specific
-- name, price, duration, photo, offline payment, specialists.

CREATE TABLE services.branch_services (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id           UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id                 UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  category_id               UUID NOT NULL REFERENCES services.service_categories(id) ON DELETE RESTRICT,
  subcategory_id            UUID NOT NULL REFERENCES services.service_subcategories(id) ON DELETE RESTRICT,
  name                      VARCHAR(255) NOT NULL,
  description               TEXT,
  price                     NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
  currency                  VARCHAR(3) NOT NULL DEFAULT 'INR',
  duration_minutes          INT NOT NULL CHECK (duration_minutes > 0),
  photo_url                 TEXT,
  offline_payment_allowed   BOOLEAN NOT NULL DEFAULT TRUE,
  status                    VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'INACTIVE')),
  sort_order                INT NOT NULL DEFAULT 0,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE services.branch_services IS
  'Services a branch offers — Admin selects category/subcategory from platform catalog, then sets branch name/price/duration';

CREATE INDEX idx_branch_services_branch_status
  ON services.branch_services(branch_id, status);
CREATE INDEX idx_branch_services_org
  ON services.branch_services(organization_id);
CREATE INDEX idx_branch_services_category
  ON services.branch_services(category_id, subcategory_id);
CREATE INDEX idx_branch_services_name
  ON services.branch_services(branch_id, name);

-- Specialists tagged to a branch service (employees who can perform it)
CREATE TABLE services.branch_service_specialists (
  branch_service_id   UUID NOT NULL REFERENCES services.branch_services(id) ON DELETE CASCADE,
  employee_id         UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (branch_service_id, employee_id)
);

CREATE INDEX idx_branch_service_specialists_emp
  ON services.branch_service_specialists(employee_id);

COMMENT ON TABLE services.branch_service_specialists IS
  'Employees tagged as specialists for a branch service';

-- Integrity: branch belongs to org; subcategory belongs to category
CREATE OR REPLACE FUNCTION services.enforce_branch_service_refs()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
  sub_cat UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_services: branch must belong to the same organization';
  END IF;

  SELECT category_id INTO sub_cat
  FROM services.service_subcategories WHERE id = NEW.subcategory_id;
  IF sub_cat IS NULL OR sub_cat <> NEW.category_id THEN
    RAISE EXCEPTION 'branch_services: subcategory must belong to the selected category';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_branch_service_refs
  BEFORE INSERT OR UPDATE OF organization_id, branch_id, category_id, subcategory_id
  ON services.branch_services
  FOR EACH ROW EXECUTE FUNCTION services.enforce_branch_service_refs();

-- Specialist must be ACTIVE employee in same org (and same branch preferred)
CREATE OR REPLACE FUNCTION services.enforce_service_specialist_same_scope()
RETURNS TRIGGER AS $$
DECLARE
  svc RECORD;
  emp RECORD;
BEGIN
  SELECT organization_id, branch_id INTO svc
  FROM services.branch_services WHERE id = NEW.branch_service_id;

  SELECT organization_id, branch_id, status INTO emp
  FROM employee.employees WHERE id = NEW.employee_id;

  IF svc.organization_id IS NULL OR emp.organization_id IS NULL THEN
    RAISE EXCEPTION 'branch_service_specialists: invalid service or employee';
  END IF;
  IF svc.organization_id <> emp.organization_id THEN
    RAISE EXCEPTION 'branch_service_specialists: employee must belong to the same organization as the service';
  END IF;
  IF svc.branch_id <> emp.branch_id THEN
    RAISE EXCEPTION 'branch_service_specialists: employee must belong to the same branch as the service';
  END IF;
  IF emp.status <> 'ACTIVE' THEN
    RAISE EXCEPTION 'branch_service_specialists: employee must be ACTIVE';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_service_specialist_same_scope
  BEFORE INSERT OR UPDATE ON services.branch_service_specialists
  FOR EACH ROW EXECUTE FUNCTION services.enforce_service_specialist_same_scope();

GRANT SELECT, INSERT, UPDATE, DELETE ON services.branch_services TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON services.branch_service_specialists TO authenticated;

-- Seed sample branch services for a few branches
DO $$
DECLARE
  br RECORD;
  cat_hair UUID;
  sub_mens UUID;
  sub_womens UUID;
  cat_spa UUID;
  sub_spa UUID;
  svc1 UUID;
  emp_id UUID;
BEGIN
  SELECT id INTO cat_hair FROM services.service_categories
  WHERE name ILIKE '%Hair%' OR code ILIKE '%HAIR%'
  ORDER BY sort_order LIMIT 1;

  SELECT id INTO cat_spa FROM services.service_categories
  WHERE name ILIKE '%Spa%' OR is_single_level = TRUE
  ORDER BY sort_order LIMIT 1;

  IF cat_hair IS NULL THEN
    RAISE NOTICE 'No hair category — skip branch service seed';
    RETURN;
  END IF;

  SELECT id INTO sub_mens FROM services.service_subcategories
  WHERE category_id = cat_hair
  ORDER BY sort_order LIMIT 1;

  SELECT id INTO sub_womens FROM services.service_subcategories
  WHERE category_id = cat_hair
  ORDER BY sort_order OFFSET 1 LIMIT 1;

  IF sub_womens IS NULL THEN
    sub_womens := sub_mens;
  END IF;

  IF sub_mens IS NULL THEN
    RAISE NOTICE 'No subcategory under hair — skip seed';
    RETURN;
  END IF;

  IF cat_spa IS NOT NULL THEN
    SELECT id INTO sub_spa FROM services.service_subcategories
    WHERE category_id = cat_spa LIMIT 1;
  END IF;

  FOR br IN
    SELECT b.id AS branch_id, b.organization_id
    FROM public.branches b
    ORDER BY b.is_primary DESC, b.created_at
    LIMIT 4
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM services.branch_services
      WHERE branch_id = br.branch_id AND name = 'Classic Hair Cut'
    ) THEN
      INSERT INTO services.branch_services (
        organization_id, branch_id, category_id, subcategory_id,
        name, description, price, duration_minutes, offline_payment_allowed, status, sort_order
      ) VALUES (
        br.organization_id, br.branch_id, cat_hair, sub_mens,
        'Classic Hair Cut', 'Standard haircut by branch stylist', 399.00, 30, TRUE, 'ACTIVE', 10
      ) RETURNING id INTO svc1;
    ELSE
      SELECT id INTO svc1 FROM services.branch_services
      WHERE branch_id = br.branch_id AND name = 'Classic Hair Cut' LIMIT 1;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM services.branch_services
      WHERE branch_id = br.branch_id AND name = 'Women''s Hair Cut & Style'
    ) THEN
      INSERT INTO services.branch_services (
        organization_id, branch_id, category_id, subcategory_id,
        name, description, price, duration_minutes, offline_payment_allowed, status, sort_order
      ) VALUES (
        br.organization_id, br.branch_id, cat_hair, COALESCE(sub_womens, sub_mens),
        'Women''s Hair Cut & Style', 'Cut and blow dry', 799.00, 60, TRUE, 'ACTIVE', 20
      );
    END IF;

    IF sub_spa IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM services.branch_services
      WHERE branch_id = br.branch_id AND name = 'Relaxation Spa'
    ) THEN
      INSERT INTO services.branch_services (
        organization_id, branch_id, category_id, subcategory_id,
        name, description, price, duration_minutes, offline_payment_allowed, status, sort_order
      ) VALUES (
        br.organization_id, br.branch_id, cat_spa, sub_spa,
        'Relaxation Spa', 'Full body spa session', 1499.00, 90, FALSE, 'ACTIVE', 30
      );
    END IF;

    SELECT id INTO emp_id FROM employee.employees
    WHERE branch_id = br.branch_id AND status = 'ACTIVE'
    ORDER BY created_at LIMIT 1;

    IF emp_id IS NOT NULL AND svc1 IS NOT NULL THEN
      INSERT INTO services.branch_service_specialists (branch_service_id, employee_id, is_primary)
      VALUES (svc1, emp_id, TRUE)
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;

ANALYZE services.branch_services;
ANALYZE services.branch_service_specialists;
