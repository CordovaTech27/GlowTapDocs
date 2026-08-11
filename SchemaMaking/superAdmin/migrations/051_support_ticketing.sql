-- §4.11 Support & Ticketing (SaaS-standard)
-- Personas: SALON (admin portal) + END_USER (customer app) + SUPER_ADMIN / SYSTEM
-- CTS = Category → Type → Subtype (configurable masters)

-- ---------------------------------------------------------------------------
-- CTS masters
-- ---------------------------------------------------------------------------
CREATE TABLE support_ticket_categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(50) NOT NULL UNIQUE,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  -- Who can select this category when raising a ticket
  audience        VARCHAR(20) NOT NULL DEFAULT 'BOTH'
    CHECK (audience IN ('SALON', 'END_USER', 'BOTH')),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE support_ticket_types (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID NOT NULL REFERENCES support_ticket_categories(id) ON DELETE CASCADE,
  code            VARCHAR(50) NOT NULL,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category_id, code)
);

CREATE TABLE support_ticket_subtypes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_id         UUID NOT NULL REFERENCES support_ticket_types(id) ON DELETE CASCADE,
  code            VARCHAR(50) NOT NULL,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  default_priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM'
    CHECK (default_priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (type_id, code)
);

CREATE INDEX idx_support_ticket_types_category
  ON support_ticket_types(category_id, is_active, sort_order);
CREATE INDEX idx_support_ticket_subtypes_type
  ON support_ticket_subtypes(type_id, is_active, sort_order);

-- ---------------------------------------------------------------------------
-- SLA by priority (Freshdesk / Zendesk style)
-- ---------------------------------------------------------------------------
CREATE TABLE support_sla_policies (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  priority                  VARCHAR(20) NOT NULL UNIQUE
    CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  first_response_minutes    INT NOT NULL CHECK (first_response_minutes > 0),
  resolve_minutes           INT NOT NULL CHECK (resolve_minutes > 0),
  business_hours_only       BOOLEAN NOT NULL DEFAULT FALSE,
  is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by                UUID REFERENCES super_admin_users(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Tickets
-- ---------------------------------------------------------------------------
CREATE TABLE support_tickets (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number         VARCHAR(30) NOT NULL UNIQUE,
  -- Who raised it
  source                VARCHAR(20) NOT NULL
    CHECK (source IN ('SALON', 'END_USER', 'SUPER_ADMIN', 'SYSTEM')),
  organization_id       UUID REFERENCES organizations(id) ON DELETE SET NULL,
  branch_id             UUID REFERENCES branches(id) ON DELETE SET NULL,
  end_user_ref          VARCHAR(50),
  booking_ref           VARCHAR(50),
  requester_name        VARCHAR(255),
  requester_email       VARCHAR(255),
  requester_phone       VARCHAR(20),
  -- CTS
  category_id           UUID NOT NULL REFERENCES support_ticket_categories(id),
  type_id               UUID NOT NULL REFERENCES support_ticket_types(id),
  subtype_id            UUID REFERENCES support_ticket_subtypes(id),
  -- Content
  subject               VARCHAR(255) NOT NULL,
  description           TEXT NOT NULL,
  priority              VARCHAR(20) NOT NULL DEFAULT 'MEDIUM'
    CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  status                VARCHAR(30) NOT NULL DEFAULT 'CREATED'
    CHECK (status IN (
      'CREATED', 'IN_PROGRESS', 'ON_HOLD',
      'AWAITING_USER', 'RESOLVED', 'CLOSED', 'REOPENED'
    )),
  assigned_to           UUID REFERENCES super_admin_users(id),
  -- SLA clocks
  sla_policy_id         UUID REFERENCES support_sla_policies(id),
  first_response_due_at TIMESTAMPTZ,
  resolve_due_at        TIMESTAMPTZ,
  first_responded_at    TIMESTAMPTZ,
  resolved_at           TIMESTAMPTZ,
  closed_at             TIMESTAMPTZ,
  resolution_notes      TEXT,
  csat_score            INT CHECK (csat_score IS NULL OR csat_score BETWEEN 1 AND 5),
  csat_comment          TEXT,
  created_by_super_admin_id UUID REFERENCES super_admin_users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_tickets_status
  ON support_tickets(status, priority, created_at DESC);
CREATE INDEX idx_support_tickets_org
  ON support_tickets(organization_id, created_at DESC)
  WHERE organization_id IS NOT NULL;
CREATE INDEX idx_support_tickets_end_user
  ON support_tickets(end_user_ref, created_at DESC)
  WHERE end_user_ref IS NOT NULL;
CREATE INDEX idx_support_tickets_assignee
  ON support_tickets(assigned_to, status)
  WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_support_tickets_sla_overdue
  ON support_tickets(resolve_due_at)
  WHERE status NOT IN ('RESOLVED', 'CLOSED') AND resolve_due_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Public conversation thread (visible to requester)
-- ---------------------------------------------------------------------------
CREATE TABLE support_ticket_messages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  author_type       VARCHAR(20) NOT NULL
    CHECK (author_type IN ('SALON', 'END_USER', 'AGENT', 'SYSTEM')),
  author_ref        VARCHAR(100),
  author_super_admin_id UUID REFERENCES super_admin_users(id),
  body              TEXT NOT NULL,
  is_first_response BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_ticket_messages_ticket
  ON support_ticket_messages(ticket_id, created_at);

-- ---------------------------------------------------------------------------
-- Internal notes (Super Admin / Ops only — not visible to salon/customer)
-- ---------------------------------------------------------------------------
CREATE TABLE support_ticket_internal_notes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  body              TEXT NOT NULL,
  created_by        UUID REFERENCES super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_ticket_notes_ticket
  ON support_ticket_internal_notes(ticket_id, created_at);

-- ---------------------------------------------------------------------------
-- Attachments (ticket or message level)
-- ---------------------------------------------------------------------------
CREATE TABLE support_ticket_attachments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  message_id        UUID REFERENCES support_ticket_messages(id) ON DELETE SET NULL,
  file_name         VARCHAR(255) NOT NULL,
  storage_url       TEXT NOT NULL,
  mime_type         VARCHAR(100),
  file_size_bytes   BIGINT,
  uploaded_by_type  VARCHAR(20) NOT NULL
    CHECK (uploaded_by_type IN ('SALON', 'END_USER', 'AGENT')),
  uploaded_by_ref   VARCHAR(100),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_ticket_attachments_ticket
  ON support_ticket_attachments(ticket_id);

-- ---------------------------------------------------------------------------
-- Status / assignment audit
-- ---------------------------------------------------------------------------
CREATE TABLE support_ticket_events (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  event_type        VARCHAR(30) NOT NULL
    CHECK (event_type IN (
      'CREATED', 'STATUS_CHANGE', 'ASSIGNED', 'PRIORITY_CHANGE',
      'REOPENED', 'SLA_BREACH', 'CSAT_SUBMITTED', 'NOTE_ADDED'
    )),
  from_value        VARCHAR(100),
  to_value          VARCHAR(100),
  note              TEXT,
  performed_by      UUID REFERENCES super_admin_users(id),
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_ticket_events_ticket
  ON support_ticket_events(ticket_id, performed_at DESC);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE support_ticket_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_categories
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_categories TO authenticated;

ALTER TABLE support_ticket_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_types
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_types TO authenticated;

ALTER TABLE support_ticket_subtypes ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_subtypes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_subtypes TO authenticated;

ALTER TABLE support_sla_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_sla_policies
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_sla_policies TO authenticated;

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_tickets
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_tickets TO authenticated;

ALTER TABLE support_ticket_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_messages
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_messages TO authenticated;

ALTER TABLE support_ticket_internal_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_internal_notes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_internal_notes TO authenticated;

ALTER TABLE support_ticket_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_attachments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_attachments TO authenticated;

ALTER TABLE support_ticket_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON support_ticket_events
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON support_ticket_events TO authenticated;

-- ---------------------------------------------------------------------------
-- Seed — SLA (typical SaaS defaults)
-- ---------------------------------------------------------------------------
INSERT INTO support_sla_policies (
  id, priority, first_response_minutes, resolve_minutes, business_hours_only
) VALUES
('f9000000-0000-4000-8000-000000000001', 'LOW',      480,  2880, FALSE),  -- 8h / 48h
('f9000000-0000-4000-8000-000000000002', 'MEDIUM',   240,  1440, FALSE),  -- 4h / 24h
('f9000000-0000-4000-8000-000000000003', 'HIGH',      60,   480, FALSE),  -- 1h / 8h
('f9000000-0000-4000-8000-000000000004', 'CRITICAL',  15,   120, FALSE); -- 15m / 2h

-- ---------------------------------------------------------------------------
-- Seed — CTS for SALON
-- ---------------------------------------------------------------------------
INSERT INTO support_ticket_categories (id, code, label, audience, sort_order) VALUES
('f9000000-0000-4000-8000-000000000101', 'SALON_BILLING', 'Billing & Subscription', 'SALON', 10),
('f9000000-0000-4000-8000-000000000102', 'SALON_TECH', 'Technical / Portal', 'SALON', 20),
('f9000000-0000-4000-8000-000000000103', 'SALON_ACCOUNT', 'Account & Access', 'SALON', 30);

INSERT INTO support_ticket_types (id, category_id, code, label, sort_order) VALUES
('f9000000-0000-4000-8000-000000000201', 'f9000000-0000-4000-8000-000000000101', 'INVOICE', 'Invoice / Payment', 10),
('f9000000-0000-4000-8000-000000000202', 'f9000000-0000-4000-8000-000000000101', 'PLAN', 'Plan change / upgrade', 20),
('f9000000-0000-4000-8000-000000000203', 'f9000000-0000-4000-8000-000000000102', 'BOOKINGS', 'Appointments module', 10),
('f9000000-0000-4000-8000-000000000204', 'f9000000-0000-4000-8000-000000000102', 'PAYOUTS', 'Marketplace payouts', 20),
('f9000000-0000-4000-8000-000000000205', 'f9000000-0000-4000-8000-000000000103', 'LOGIN', 'Login / password', 10),
('f9000000-0000-4000-8000-000000000206', 'f9000000-0000-4000-8000-000000000103', 'SUB_ADMIN', 'Sub-admin access', 20);

INSERT INTO support_ticket_subtypes (id, type_id, code, label, default_priority, sort_order) VALUES
('f9000000-0000-4000-8000-000000000301', 'f9000000-0000-4000-8000-000000000201', 'NOT_RECEIVED', 'Invoice not received', 'MEDIUM', 10),
('f9000000-0000-4000-8000-000000000302', 'f9000000-0000-4000-8000-000000000201', 'PAYMENT_FAILED', 'Payment failed', 'HIGH', 20),
('f9000000-0000-4000-8000-000000000303', 'f9000000-0000-4000-8000-000000000204', 'MISSING_PAYOUT', 'Payout not received', 'HIGH', 10),
('f9000000-0000-4000-8000-000000000304', 'f9000000-0000-4000-8000-000000000205', 'RESET_PWD', 'Cannot reset password', 'MEDIUM', 10);

-- ---------------------------------------------------------------------------
-- Seed — CTS for END_USER (customer app)
-- ---------------------------------------------------------------------------
INSERT INTO support_ticket_categories (id, code, label, audience, sort_order) VALUES
('f9000000-0000-4000-8000-000000000111', 'CUST_BOOKING', 'Booking issues', 'END_USER', 10),
('f9000000-0000-4000-8000-000000000112', 'CUST_PAYMENT', 'Payments & refunds', 'END_USER', 20),
('f9000000-0000-4000-8000-000000000113', 'CUST_ACCOUNT', 'Account & app', 'END_USER', 30);

INSERT INTO support_ticket_types (id, category_id, code, label, sort_order) VALUES
('f9000000-0000-4000-8000-000000000211', 'f9000000-0000-4000-8000-000000000111', 'CANCEL', 'Cancel / reschedule', 10),
('f9000000-0000-4000-8000-000000000212', 'f9000000-0000-4000-8000-000000000111', 'SERVICE', 'Service quality', 20),
('f9000000-0000-4000-8000-000000000213', 'f9000000-0000-4000-8000-000000000112', 'REFUND', 'Refund request', 10),
('f9000000-0000-4000-8000-000000000214', 'f9000000-0000-4000-8000-000000000112', 'CHARGE', 'Wrong charge', 20),
('f9000000-0000-4000-8000-000000000215', 'f9000000-0000-4000-8000-000000000113', 'LOGIN_APP', 'App login', 10);

INSERT INTO support_ticket_subtypes (id, type_id, code, label, default_priority, sort_order) VALUES
('f9000000-0000-4000-8000-000000000311', 'f9000000-0000-4000-8000-000000000213', 'FULL_REFUND', 'Full refund', 'HIGH', 10),
('f9000000-0000-4000-8000-000000000312', 'f9000000-0000-4000-8000-000000000213', 'PARTIAL_REFUND', 'Partial refund', 'MEDIUM', 20),
('f9000000-0000-4000-8000-000000000313', 'f9000000-0000-4000-8000-000000000212', 'NO_SHOW_SALON', 'Salon no-show / delayed', 'HIGH', 10),
('f9000000-0000-4000-8000-000000000314', 'f9000000-0000-4000-8000-000000000215', 'OTP_FAIL', 'OTP not received', 'MEDIUM', 10);

-- BOTH audience example
INSERT INTO support_ticket_categories (id, code, label, audience, sort_order) VALUES
('f9000000-0000-4000-8000-000000000121', 'GENERAL', 'General enquiry', 'BOTH', 90);

INSERT INTO support_ticket_types (id, category_id, code, label, sort_order) VALUES
('f9000000-0000-4000-8000-000000000221', 'f9000000-0000-4000-8000-000000000121', 'OTHER', 'Other', 10);

INSERT INTO support_ticket_subtypes (id, type_id, code, label, default_priority, sort_order) VALUES
('f9000000-0000-4000-8000-000000000321', 'f9000000-0000-4000-8000-000000000221', 'MISC', 'Miscellaneous', 'LOW', 10);

-- ---------------------------------------------------------------------------
-- Seed — sample tickets (1 salon + 1 customer)
-- ---------------------------------------------------------------------------
INSERT INTO support_tickets (
  id, ticket_number, source, organization_id, branch_id,
  requester_name, requester_email,
  category_id, type_id, subtype_id,
  subject, description, priority, status, assigned_to, sla_policy_id,
  first_response_due_at, resolve_due_at, created_at
) VALUES (
  'f9000000-0000-4000-8000-000000000401',
  'GT-TKT-2026-00001',
  'SALON',
  'b1000000-0000-4000-8000-000000000001',
  'c1000000-0000-4000-8000-000000000001',
  'Priya Kapoor', 'priya@lookssalon.in',
  'f9000000-0000-4000-8000-000000000101',
  'f9000000-0000-4000-8000-000000000201',
  'f9000000-0000-4000-8000-000000000302',
  'Subscription payment failed',
  'Tried renewing Professional plan; Razorpay declined. Need invoice + retry help.',
  'HIGH', 'IN_PROGRESS',
  'a1000000-0000-4000-8000-000000000001',
  'f9000000-0000-4000-8000-000000000003',
  TIMESTAMPTZ '2026-07-22 12:00:00+05:30',
  TIMESTAMPTZ '2026-07-22 19:00:00+05:30',
  TIMESTAMPTZ '2026-07-22 11:00:00+05:30'
);

INSERT INTO support_ticket_messages (
  id, ticket_id, author_type, author_ref, body, is_first_response, created_at
) VALUES (
  'f9000000-0000-4000-8000-000000000501',
  'f9000000-0000-4000-8000-000000000401',
  'SALON', 'priya@lookssalon.in',
  'Tried renewing Professional plan; Razorpay declined. Need invoice + retry help.',
  FALSE,
  TIMESTAMPTZ '2026-07-22 11:00:00+05:30'
),
(
  'f9000000-0000-4000-8000-000000000502',
  'f9000000-0000-4000-8000-000000000401',
  'AGENT', NULL,
  'Thanks Priya — checking the payment attempt. We will share a retry link shortly.',
  TRUE,
  TIMESTAMPTZ '2026-07-22 11:25:00+05:30'
);

UPDATE support_tickets
SET first_responded_at = TIMESTAMPTZ '2026-07-22 11:25:00+05:30'
WHERE id = 'f9000000-0000-4000-8000-000000000401';

INSERT INTO support_ticket_internal_notes (
  id, ticket_id, body, created_by, created_at
) VALUES (
  'f9000000-0000-4000-8000-000000000601',
  'f9000000-0000-4000-8000-000000000401',
  'Gateway log: insufficient_funds on last attempt. Salon card may need update.',
  'a1000000-0000-4000-8000-000000000001',
  TIMESTAMPTZ '2026-07-22 11:26:00+05:30'
);

INSERT INTO support_ticket_events (
  id, ticket_id, event_type, from_value, to_value, performed_by, performed_at
) VALUES
(
  'f9000000-0000-4000-8000-000000000701',
  'f9000000-0000-4000-8000-000000000401',
  'CREATED', NULL, 'CREATED',
  NULL, TIMESTAMPTZ '2026-07-22 11:00:00+05:30'
),
(
  'f9000000-0000-4000-8000-000000000702',
  'f9000000-0000-4000-8000-000000000401',
  'ASSIGNED', NULL, 'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000001', TIMESTAMPTZ '2026-07-22 11:10:00+05:30'
),
(
  'f9000000-0000-4000-8000-000000000703',
  'f9000000-0000-4000-8000-000000000401',
  'STATUS_CHANGE', 'CREATED', 'IN_PROGRESS',
  'a1000000-0000-4000-8000-000000000001', TIMESTAMPTZ '2026-07-22 11:10:00+05:30'
);

-- Customer ticket (booking-linked)
INSERT INTO support_tickets (
  id, ticket_number, source, organization_id, branch_id,
  end_user_ref, booking_ref,
  requester_name, requester_email, requester_phone,
  category_id, type_id, subtype_id,
  subject, description, priority, status, sla_policy_id,
  first_response_due_at, resolve_due_at, created_at
) VALUES (
  'f9000000-0000-4000-8000-000000000402',
  'GT-TKT-2026-00002',
  'END_USER',
  'b1000000-0000-4000-8000-000000000003',
  'c1000000-0000-4000-8000-000000000006',
  'EU-5003', 'BK-ENR-9003',
  'Aisha Khan', 'aisha.k@example.com', '+91 98111 22334',
  'f9000000-0000-4000-8000-000000000112',
  'f9000000-0000-4000-8000-000000000213',
  'f9000000-0000-4000-8000-000000000311',
  'Refund for cancelled booking',
  'Booking was cancelled by salon; amount still showing as paid. Please refund.',
  'HIGH', 'CREATED',
  'f9000000-0000-4000-8000-000000000003',
  TIMESTAMPTZ '2026-07-23 17:10:00+05:30',
  TIMESTAMPTZ '2026-07-24 00:10:00+05:30',
  TIMESTAMPTZ '2026-07-23 16:10:00+05:30'
);

INSERT INTO support_ticket_messages (
  id, ticket_id, author_type, author_ref, body, created_at
) VALUES (
  'f9000000-0000-4000-8000-000000000503',
  'f9000000-0000-4000-8000-000000000402',
  'END_USER', 'EU-5003',
  'Booking was cancelled by salon; amount still showing as paid. Please refund.',
  TIMESTAMPTZ '2026-07-23 16:10:00+05:30'
);

INSERT INTO support_ticket_attachments (
  id, ticket_id, message_id, file_name, storage_url, mime_type, file_size_bytes,
  uploaded_by_type, uploaded_by_ref, created_at
) VALUES (
  'f9000000-0000-4000-8000-000000000801',
  'f9000000-0000-4000-8000-000000000402',
  'f9000000-0000-4000-8000-000000000503',
  'payment-screenshot.png',
  'https://cdn.glowtap.example/tickets/gt-tkt-00002-pay.png',
  'image/png', 245000,
  'END_USER', 'EU-5003',
  TIMESTAMPTZ '2026-07-23 16:10:00+05:30'
);

INSERT INTO support_ticket_events (
  id, ticket_id, event_type, to_value, performed_at
) VALUES (
  'f9000000-0000-4000-8000-000000000704',
  'f9000000-0000-4000-8000-000000000402',
  'CREATED', 'CREATED',
  TIMESTAMPTZ '2026-07-23 16:10:00+05:30'
);

ANALYZE support_ticket_categories;
ANALYZE support_ticket_types;
ANALYZE support_ticket_subtypes;
ANALYZE support_sla_policies;
ANALYZE support_tickets;
ANALYZE support_ticket_messages;
ANALYZE support_ticket_internal_notes;
ANALYZE support_ticket_attachments;
ANALYZE support_ticket_events;
