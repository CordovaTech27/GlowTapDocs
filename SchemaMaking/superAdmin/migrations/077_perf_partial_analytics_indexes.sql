-- Partial covering indexes for PERF analytics (status histogram + branch GMV)
-- Smaller than full-table INCLUDE indexes; ideal for platform rollups.

CREATE INDEX IF NOT EXISTS idx_appointments_perf_status_gross
  ON appointments.appointments (status)
  INCLUDE (gross_amount, branch_id, organization_id)
  WHERE booking_number >= 'PERF-APT-' AND booking_number < 'PERF-APT.';

CREATE INDEX IF NOT EXISTS idx_appointments_perf_completed_branch_gmv
  ON appointments.appointments (branch_id)
  INCLUDE (gross_amount)
  WHERE status = 'COMPLETED'
    AND booking_number >= 'PERF-APT-'
    AND booking_number < 'PERF-APT.';

ANALYZE appointments.appointments;
