-- Idempotent demo appointments seed (no slot config — duration on branch_services).

DO $$
DECLARE
  svc RECORD;
  emp_id UUID;
  appt1 UUID;
  starts TIMESTAMPTZ;
BEGIN
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
    appt1 := NULL;

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
  END LOOP;
END $$;
