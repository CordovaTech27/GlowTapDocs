-- Appointments schema (Admin Spec §4.11–4.12)
-- Time slots are auto-calculated at runtime; we store slot CONFIG + bookings only.
-- Soft refs: end_user_ref until End-User module lands as first-class tables.

CREATE SCHEMA IF NOT EXISTS appointments;

COMMENT ON SCHEMA appointments IS
  'Bookings / appointments — slot config, holds, appointments, status & reschedule audit';

-- ---------------------------------------------------------------------------
-- 1. Branch slot granularity config (not materialised free slots)
-- ---------------------------------------------------------------------------
CREATE TABLE appointments.branch_slot_configs (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id           UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  -- Allowed slot step sizes in minutes (e.g. 30, 45, 60)
  slot_minutes        INT NOT NULL CHECK (slot_minutes > 0),
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order          INT NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (branch_id, slot_minutes)
);

COMMENT ON TABLE appointments.branch_slot_configs IS
  'Allowed slot granularities per branch. Availability windows are computed, not stored.';

CREATE INDEX idx_branch_slot_configs_org
  ON appointments.branch_slot_configs(organization_id);

-- ---------------------------------------------------------------------------
-- 2. Short-lived slot holds during checkout (optional TTL)
-- ---------------------------------------------------------------------------
CREATE TABLE appointments.appointment_holds (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id           UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  branch_service_id   UUID NOT NULL REFERENCES services.branch_services(id) ON DELETE CASCADE,
  specialist_id       UUID REFERENCES employee.employees(id) ON DELETE SET NULL,
  end_user_ref        VARCHAR(50),
  starts_at           TIMESTAMPTZ NOT NULL,
  ends_at             TIMESTAMPTZ NOT NULL,
  expires_at          TIMESTAMPTZ NOT NULL,
  status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'CONSUMED', 'EXPIRED', 'RELEASED')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ends_at > starts_at),
  CHECK (expires_at > created_at)
);

CREATE INDEX idx_appointment_holds_branch_time
  ON appointments.appointment_holds(branch_id, starts_at, ends_at)
  WHERE status = 'ACTIVE';

COMMENT ON TABLE appointments.appointment_holds IS
  'Temporary hold while end user pays (e.g. 10 min TTL). Not a full slot calendar.';

-- ---------------------------------------------------------------------------
-- 3. Appointments / bookings
-- ---------------------------------------------------------------------------
CREATE TABLE appointments.appointments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_number        VARCHAR(40) NOT NULL UNIQUE,
  organization_id       UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id             UUID NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  branch_service_id     UUID NOT NULL REFERENCES services.branch_services(id) ON DELETE RESTRICT,
  specialist_id         UUID REFERENCES employee.employees(id) ON DELETE SET NULL,
  -- Soft refs until End-User module
  end_user_ref          VARCHAR(50) NOT NULL,
  end_user_name         VARCHAR(255),
  end_user_phone        VARCHAR(20),
  end_user_email        VARCHAR(255),
  -- Snapshot at booking time (service may change later)
  service_name          VARCHAR(255) NOT NULL,
  service_duration_min  INT NOT NULL CHECK (service_duration_min > 0),
  starts_at             TIMESTAMPTZ NOT NULL,
  ends_at               TIMESTAMPTZ NOT NULL,
  status                VARCHAR(30) NOT NULL DEFAULT 'BOOKED'
    CHECK (status IN (
      'BOOKED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    )),
  source                VARCHAR(30) NOT NULL DEFAULT 'CONSUMER_APP'
    CHECK (source IN ('CONSUMER_APP', 'WALK_IN', 'ADMIN', 'SYSTEM')),
  customer_note         TEXT,
  -- Money (B2C)
  currency              VARCHAR(3) NOT NULL DEFAULT 'INR',
  list_price            NUMERIC(12, 2) NOT NULL DEFAULT 0,
  discount_amount       NUMERIC(12, 2) NOT NULL DEFAULT 0,
  gross_amount          NUMERIC(12, 2) NOT NULL DEFAULT 0,
  payment_method        VARCHAR(20) NOT NULL DEFAULT 'ONLINE'
    CHECK (payment_method IN ('ONLINE', 'OFFLINE')),
  payment_status        VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (payment_status IN (
      'PENDING', 'PAID', 'FAILED', 'REFUNDED', 'PARTIAL_REFUND', 'NOT_REQUIRED'
    )),
  eut_transaction_id    UUID REFERENCES rms.end_user_transactions(id) ON DELETE SET NULL,
  hold_id               UUID REFERENCES appointments.appointment_holds(id) ON DELETE SET NULL,
  cancel_reason         TEXT,
  cancelled_at          TIMESTAMPTZ,
  confirmed_at          TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  no_show_at            TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ends_at > starts_at)
);

CREATE INDEX idx_appointments_branch_starts
  ON appointments.appointments(branch_id, starts_at);
CREATE INDEX idx_appointments_org_status
  ON appointments.appointments(organization_id, status);
CREATE INDEX idx_appointments_specialist_starts
  ON appointments.appointments(specialist_id, starts_at)
  WHERE specialist_id IS NOT NULL;
CREATE INDEX idx_appointments_end_user
  ON appointments.appointments(end_user_ref);
CREATE INDEX idx_appointments_service
  ON appointments.appointments(branch_service_id);

COMMENT ON TABLE appointments.appointments IS
  'End-user bookings. Free slots are computed; this table stores confirmed/held bookings only.';

-- Same-org / branch integrity
CREATE OR REPLACE FUNCTION appointments.enforce_appointment_scope()
RETURNS TRIGGER AS $$
DECLARE
  branch_org UUID;
  svc RECORD;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'appointments: branch must belong to the same organization';
  END IF;

  SELECT organization_id, branch_id INTO svc
  FROM services.branch_services WHERE id = NEW.branch_service_id;
  IF svc.organization_id IS NULL OR svc.organization_id <> NEW.organization_id
     OR svc.branch_id <> NEW.branch_id THEN
    RAISE EXCEPTION 'appointments: service must belong to the same org and branch';
  END IF;

  IF NEW.specialist_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM employee.employees e
      WHERE e.id = NEW.specialist_id
        AND e.organization_id = NEW.organization_id
        AND e.branch_id = NEW.branch_id
    ) THEN
      RAISE EXCEPTION 'appointments: specialist must belong to the same org and branch';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_appointment_scope
  BEFORE INSERT OR UPDATE OF organization_id, branch_id, branch_service_id, specialist_id
  ON appointments.appointments
  FOR EACH ROW EXECUTE FUNCTION appointments.enforce_appointment_scope();

-- ---------------------------------------------------------------------------
-- 4. Status change audit
-- ---------------------------------------------------------------------------
CREATE TABLE appointments.appointment_status_events (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id      UUID NOT NULL REFERENCES appointments.appointments(id) ON DELETE CASCADE,
  from_status         VARCHAR(30),
  to_status           VARCHAR(30) NOT NULL,
  reason              TEXT,
  performed_by_type   VARCHAR(20) NOT NULL DEFAULT 'SYSTEM'
    CHECK (performed_by_type IN ('END_USER', 'SALON_ADMIN', 'SUB_ADMIN', 'SUPER_ADMIN', 'SYSTEM')),
  performed_by_ref    VARCHAR(100),
  metadata            JSONB,
  performed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_appointment_status_events_appt
  ON appointments.appointment_status_events(appointment_id, performed_at DESC);

-- ---------------------------------------------------------------------------
-- 5. Reschedule history
-- ---------------------------------------------------------------------------
CREATE TABLE appointments.appointment_reschedules (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id      UUID NOT NULL REFERENCES appointments.appointments(id) ON DELETE CASCADE,
  previous_starts_at  TIMESTAMPTZ NOT NULL,
  previous_ends_at    TIMESTAMPTZ NOT NULL,
  previous_specialist_id UUID REFERENCES employee.employees(id) ON DELETE SET NULL,
  new_starts_at       TIMESTAMPTZ NOT NULL,
  new_ends_at         TIMESTAMPTZ NOT NULL,
  new_specialist_id   UUID REFERENCES employee.employees(id) ON DELETE SET NULL,
  reason              TEXT,
  performed_by_type   VARCHAR(20) NOT NULL DEFAULT 'END_USER'
    CHECK (performed_by_type IN ('END_USER', 'SALON_ADMIN', 'SUB_ADMIN', 'SUPER_ADMIN', 'SYSTEM')),
  performed_by_ref    VARCHAR(100),
  performed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (previous_ends_at > previous_starts_at),
  CHECK (new_ends_at > new_starts_at)
);

CREATE INDEX idx_appointment_reschedules_appt
  ON appointments.appointment_reschedules(appointment_id, performed_at DESC);

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA appointments TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA appointments TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA appointments
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- ---------------------------------------------------------------------------
-- Seed: slot configs + sample appointments
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  br RECORD;
  svc RECORD;
  emp_id UUID;
  appt1 UUID;
  starts TIMESTAMPTZ;
BEGIN
  -- 30 and 60 min slots for every branch
  FOR br IN SELECT id AS branch_id, organization_id FROM public.branches LOOP
    INSERT INTO appointments.branch_slot_configs (organization_id, branch_id, slot_minutes, sort_order)
    VALUES
      (br.organization_id, br.branch_id, 30, 10),
      (br.organization_id, br.branch_id, 60, 20)
    ON CONFLICT (branch_id, slot_minutes) DO NOTHING;
  END LOOP;

  -- Sample bookings on branches that have services
  FOR svc IN
    SELECT s.id AS service_id, s.organization_id, s.branch_id, s.name, s.duration_minutes,
           s.price, s.discount_amount, s.discount_percent
    FROM services.branch_services s
    WHERE s.status = 'ACTIVE' AND s.name = 'Classic Hair Cut'
    ORDER BY s.created_at
    LIMIT 3
  LOOP
    SELECT id INTO emp_id FROM employee.employees
    WHERE branch_id = svc.branch_id AND status = 'ACTIVE'
    ORDER BY created_at LIMIT 1;

    starts := date_trunc('day', NOW() + INTERVAL '1 day') + TIME '11:00';

    -- Unique per service (branch_id prefix alone collided when multiple services shared a branch)
    INSERT INTO appointments.appointments (
      booking_number, organization_id, branch_id, branch_service_id, specialist_id,
      end_user_ref, end_user_name, end_user_phone,
      service_name, service_duration_min, starts_at, ends_at,
      status, source, list_price, discount_amount, gross_amount,
      payment_method, payment_status, confirmed_at
    ) VALUES (
      'APT-DEMO-' || UPPER(LEFT(REPLACE(svc.service_id::text, '-', ''), 12)),
      svc.organization_id, svc.branch_id, svc.service_id, emp_id,
      'EU-DEMO-001', 'Ananya Rao', '9876512345',
      svc.name, svc.duration_minutes,
      starts, starts + make_interval(mins => svc.duration_minutes),
      'CONFIRMED', 'CONSUMER_APP',
      svc.price,
      COALESCE(
        svc.discount_amount,
        CASE WHEN svc.discount_percent IS NOT NULL
          THEN ROUND(svc.price * svc.discount_percent / 100, 2) ELSE 0 END
      ),
      svc.price - COALESCE(
        svc.discount_amount,
        CASE WHEN svc.discount_percent IS NOT NULL
          THEN ROUND(svc.price * svc.discount_percent / 100, 2) ELSE 0 END
      ),
      'ONLINE', 'PAID', NOW()
    )
    ON CONFLICT (booking_number) DO NOTHING
    RETURNING id INTO appt1;

    IF appt1 IS NOT NULL THEN
      INSERT INTO appointments.appointment_status_events (
        appointment_id, from_status, to_status, performed_by_type, performed_by_ref
      ) VALUES
        (appt1, NULL, 'BOOKED', 'END_USER', 'EU-DEMO-001'),
        (appt1, 'BOOKED', 'CONFIRMED', 'SALON_ADMIN', 'salon_admin');
    END IF;

    appt1 := NULL;
  END LOOP;
END $$;

ANALYZE appointments.branch_slot_configs;
ANALYZE appointments.appointment_holds;
ANALYZE appointments.appointments;
ANALYZE appointments.appointment_status_events;
ANALYZE appointments.appointment_reschedules;
