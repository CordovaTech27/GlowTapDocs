-- Neon-safe subset: smaller indexes only (512 MB project cap).
-- Full Round-3 set already applied on local GlowTap via 076_performance_indexes_round3.sql

CREATE INDEX IF NOT EXISTS idx_appointments_org_starts
  ON appointments.appointments (organization_id, starts_at DESC);

CREATE INDEX IF NOT EXISTS idx_appointments_status_incl
  ON appointments.appointments (status)
  INCLUDE (gross_amount, branch_id, organization_id);

CREATE INDEX IF NOT EXISTS idx_appointments_branch_status_incl
  ON appointments.appointments (branch_id, status)
  INCLUDE (gross_amount);

ANALYZE appointments.appointments;
ANALYZE rms.end_user_transactions;
ANALYZE public.organizations;
