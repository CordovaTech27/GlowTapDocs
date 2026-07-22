-- Demo: one suspended organization with status action history

-- Suspend Glamour Zone (was ACTIVE) for non-payment
UPDATE organizations
SET
  status = 'SUSPENDED',
  status_reason_id = 'b1000000-0000-4000-8000-000000000001', -- SUSPEND / NON_PAYMENT
  status_notes = 'Invoice overdue past grace period; bookings and admin portal locked.',
  status_changed_at = NOW() - INTERVAL '2 days',
  status_changed_by = 'a1000000-0000-4000-8000-000000000001',
  suspended_at = NOW() - INTERVAL '2 days',
  updated_at = NOW()
WHERE id = 'b1000000-0000-4000-8000-000000000002'
  AND status = 'ACTIVE';

INSERT INTO org_status_actions (
  id,
  organization_id,
  action,
  from_status,
  to_status,
  reason_code_id,
  notes,
  performed_by,
  performed_at
)
SELECT
  'c2000000-0000-4000-8000-000000000001',
  'b1000000-0000-4000-8000-000000000002',
  'SUSPEND',
  'ACTIVE',
  'SUSPENDED',
  rc.id,
  'Invoice overdue past grace period; bookings and admin portal locked.',
  'a1000000-0000-4000-8000-000000000001',
  NOW() - INTERVAL '2 days'
FROM reason_codes rc
WHERE rc.id = 'b1000000-0000-4000-8000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM org_status_actions
    WHERE id = 'c2000000-0000-4000-8000-000000000001'
  );
