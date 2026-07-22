-- Discount rules by plan and/or billing cycle (post migration 021)

CREATE TABLE billing_discount_configs (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                    VARCHAR(100) NOT NULL,
  subscription_plan_id    UUID REFERENCES subscription_plans(id) ON DELETE CASCADE,
  billing_cycle_id        UUID REFERENCES billing_cycles(id) ON DELETE CASCADE,
  discount_type           VARCHAR(20) NOT NULL,
  discount_value          DECIMAL(12, 2) NOT NULL,
  priority                INT NOT NULL DEFAULT 100,
  is_stackable            BOOLEAN NOT NULL DEFAULT FALSE,
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  effective_from          DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_to            DATE,
  notes                   TEXT,
  created_by              UUID REFERENCES super_admin_users(id),
  updated_by              UUID REFERENCES super_admin_users(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- UNIQUE NULLS NOT DISTINCT (subscription_plan_id, billing_cycle_id)
-- one config per plan+cycle combination (including NULL = all plans / all cycles)
