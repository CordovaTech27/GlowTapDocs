-- Reason codes for org suspend / resume / terminate + org status tracking

CREATE TABLE reason_codes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category        VARCHAR(20) NOT NULL
    CHECK (category IN ('SUSPEND', 'RESUME', 'TERMINATE')),
  code            VARCHAR(50) NOT NULL,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  pricing_impact  JSONB,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category, code)
);

CREATE INDEX idx_reason_codes_category_active
  ON reason_codes(category, is_active, sort_order)
  WHERE is_active = TRUE;

-- Current / last lifecycle action fields on organization
ALTER TABLE organizations
  ADD COLUMN status_reason_id UUID REFERENCES reason_codes(id),
  ADD COLUMN status_notes TEXT,
  ADD COLUMN status_changed_at TIMESTAMPTZ,
  ADD COLUMN status_changed_by UUID REFERENCES super_admin_users(id),
  ADD COLUMN suspended_at TIMESTAMPTZ,
  ADD COLUMN resumed_at TIMESTAMPTZ,
  ADD COLUMN terminated_at TIMESTAMPTZ;

CREATE INDEX idx_organizations_status_reason
  ON organizations(status_reason_id)
  WHERE status_reason_id IS NOT NULL;

-- Audit history of each suspend / resume / terminate action
CREATE TABLE org_status_actions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  action           VARCHAR(20) NOT NULL
    CHECK (action IN ('SUSPEND', 'RESUME', 'TERMINATE')),
  from_status      VARCHAR(20) NOT NULL,
  to_status        VARCHAR(20) NOT NULL,
  reason_code_id   UUID REFERENCES reason_codes(id),
  notes            TEXT,
  performed_by     UUID REFERENCES super_admin_users(id),
  performed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_org_status_actions_org
  ON org_status_actions(organization_id, performed_at DESC);
CREATE INDEX idx_org_status_actions_action
  ON org_status_actions(action, performed_at DESC);

-- Seed configured reason codes
INSERT INTO reason_codes (
  id, category, code, label, description, pricing_impact, sort_order, created_by
) VALUES
-- Suspend
(
  'b1000000-0000-4000-8000-000000000001',
  'SUSPEND',
  'NON_PAYMENT',
  'Non-payment / overdue',
  'Salon billing is overdue beyond grace; access suspended until payment.',
  '{"type":"NONE","description":"No immediate fee; access restored after payment"}'::jsonb,
  10,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000002',
  'SUSPEND',
  'POLICY_VIOLATION',
  'Policy violation',
  'Temporary hold for platform policy or content violation under review.',
  '{"type":"NONE"}'::jsonb,
  20,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000003',
  'SUSPEND',
  'OWNER_REQUEST',
  'Owner requested pause',
  'Salon owner requested a temporary suspension of platform access.',
  '{"type":"NONE"}'::jsonb,
  30,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000004',
  'SUSPEND',
  'COMPLIANCE_HOLD',
  'Compliance / KYC hold',
  'Suspended pending document update or compliance verification.',
  '{"type":"NONE"}'::jsonb,
  40,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000005',
  'SUSPEND',
  'OPERATIONAL_HOLD',
  'Operational review',
  'Temporary hold while Super Admin completes an operational review.',
  '{"type":"NONE"}'::jsonb,
  50,
  'a1000000-0000-4000-8000-000000000001'
),
-- Resume
(
  'b1000000-0000-4000-8000-000000000011',
  'RESUME',
  'PAYMENT_RECEIVED',
  'Payment received',
  'Outstanding dues cleared; salon restored to active.',
  NULL,
  10,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000012',
  'RESUME',
  'ISSUE_RESOLVED',
  'Issue resolved',
  'Policy / compliance / operational issue resolved.',
  NULL,
  20,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000013',
  'RESUME',
  'OWNER_REQUEST',
  'Owner requested resume',
  'Salon owner asked to reinstate access after a voluntary pause.',
  NULL,
  30,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000014',
  'RESUME',
  'ADMIN_CLEARANCE',
  'Cleared after admin review',
  'Super Admin cleared the hold after internal review.',
  NULL,
  40,
  'a1000000-0000-4000-8000-000000000001'
),
-- Terminate
(
  'b1000000-0000-4000-8000-000000000021',
  'TERMINATE',
  'EARLY_TERMINATION',
  'Early termination by owner',
  'Owner ends contract before billing term completes.',
  '{"type":"FIXED_FEE","amount":5000,"currency":"INR","description":"Early termination fee"}'::jsonb,
  10,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000022',
  'TERMINATE',
  'NON_PAYMENT_FINAL',
  'Persistent non-payment',
  'Account terminated after repeated non-payment past suspension.',
  '{"type":"FORFEIT_DISCOUNT","description":"Outstanding discounts forfeited; outstanding dues remain payable"}'::jsonb,
  20,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000023',
  'TERMINATE',
  'POLICY_BREACH',
  'Severe policy breach',
  'Permanent closure due to severe or repeated platform policy breach.',
  '{"type":"FIXED_FEE","amount":10000,"currency":"INR","description":"Policy breach penalty"}'::jsonb,
  30,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000024',
  'TERMINATE',
  'BUSINESS_CLOSED',
  'Business permanently closed',
  'Salon business has shut down; no reactivation without re-onboarding.',
  '{"type":"NONE"}'::jsonb,
  40,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000025',
  'TERMINATE',
  'CONTRACT_END',
  'Contract ended / not renewed',
  'Subscription term ended and was not renewed.',
  '{"type":"NONE"}'::jsonb,
  50,
  'a1000000-0000-4000-8000-000000000001'
);

ALTER TABLE reason_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON reason_codes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON reason_codes TO authenticated;

ALTER TABLE org_status_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON org_status_actions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON org_status_actions TO authenticated;
