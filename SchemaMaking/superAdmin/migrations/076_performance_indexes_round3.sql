-- Round 3 performance indexes for 10M-row analytics / join hot paths
-- Targets: org appointment lists, status rollups, branch GMV, EUT org scans

-- Org timeline / recent bookings (ORDER BY starts_at)
CREATE INDEX IF NOT EXISTS idx_appointments_org_starts
  ON appointments.appointments (organization_id, starts_at DESC);

-- Covering index for status histograms + completed GMV rollups
CREATE INDEX IF NOT EXISTS idx_appointments_status_incl
  ON appointments.appointments (status)
  INCLUDE (gross_amount, branch_id, organization_id, booking_number);

-- Branch × status for top-branch GMV
CREATE INDEX IF NOT EXISTS idx_appointments_branch_status_incl
  ON appointments.appointments (branch_id, status)
  INCLUDE (gross_amount);

-- Org × status covering join to service/specialist (LIMIT lists)
CREATE INDEX IF NOT EXISTS idx_appointments_org_status_starts_incl
  ON appointments.appointments (organization_id, status, starts_at DESC)
  INCLUDE (branch_service_id, specialist_id, gross_amount, booking_number, service_name, service_duration_min);

-- Prefix filters: slug / booking_number / transaction_ref (LIKE 'PERF-%')
CREATE INDEX IF NOT EXISTS idx_organizations_slug_pattern
  ON public.organizations (slug varchar_pattern_ops);

CREATE INDEX IF NOT EXISTS idx_appointments_booking_pattern
  ON appointments.appointments (booking_number varchar_pattern_ops);

CREATE INDEX IF NOT EXISTS idx_eut_org_txn_pattern
  ON rms.end_user_transactions (organization_id, transaction_ref varchar_pattern_ops);

ANALYZE appointments.appointments;
ANALYZE rms.end_user_transactions;
ANALYZE public.organizations;
ANALYZE public.branches;
ANALYZE services.branch_services;
ANALYZE employee.employees;
