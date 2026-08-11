-- Branch services offered by Salon Admin (reference)

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
  discount_amount           NUMERIC(12, 2),
  discount_percent          NUMERIC(5, 2),
  discount_description      TEXT,
  offline_payment_allowed   BOOLEAN NOT NULL DEFAULT TRUE,
  status                    VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  sort_order                INT NOT NULL DEFAULT 0,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE services.branch_service_specialists (
  branch_service_id   UUID NOT NULL REFERENCES services.branch_services(id) ON DELETE CASCADE,
  employee_id         UUID NOT NULL REFERENCES employee.employees(id) ON DELETE CASCADE,
  is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (branch_service_id, employee_id)
);
