-- Schema tickets — support CTS + SLA + ticket thread
-- FKs → public.organizations / public.branches / public.super_admin_users

CREATE TABLE tickets.support_ticket_categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(50) NOT NULL UNIQUE,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  audience        VARCHAR(20) NOT NULL DEFAULT 'BOTH',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES public.super_admin_users(id),
  updated_by      UUID REFERENCES public.super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tickets.support_ticket_types (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID NOT NULL REFERENCES tickets.support_ticket_categories(id) ON DELETE CASCADE,
  code            VARCHAR(50) NOT NULL,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category_id, code)
);

CREATE TABLE tickets.support_ticket_subtypes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_id         UUID NOT NULL REFERENCES tickets.support_ticket_types(id) ON DELETE CASCADE,
  code            VARCHAR(50) NOT NULL,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  default_priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (type_id, code)
);

CREATE TABLE tickets.support_sla_policies (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  priority                  VARCHAR(20) NOT NULL UNIQUE,
  first_response_minutes    INT NOT NULL,
  resolve_minutes           INT NOT NULL,
  business_hours_only       BOOLEAN NOT NULL DEFAULT FALSE,
  is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by                UUID REFERENCES public.super_admin_users(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tickets.support_tickets (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number         VARCHAR(30) NOT NULL UNIQUE,
  source                VARCHAR(20) NOT NULL,
  organization_id       UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  branch_id             UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  end_user_ref          VARCHAR(50),
  booking_ref           VARCHAR(50),
  requester_name        VARCHAR(255),
  requester_email       VARCHAR(255),
  requester_phone       VARCHAR(20),
  category_id           UUID NOT NULL REFERENCES tickets.support_ticket_categories(id),
  type_id               UUID NOT NULL REFERENCES tickets.support_ticket_types(id),
  subtype_id            UUID REFERENCES tickets.support_ticket_subtypes(id),
  subject               VARCHAR(255) NOT NULL,
  description           TEXT NOT NULL,
  priority              VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
  status                VARCHAR(30) NOT NULL DEFAULT 'CREATED',
  assigned_to           UUID REFERENCES public.super_admin_users(id),
  sla_policy_id         UUID REFERENCES tickets.support_sla_policies(id),
  first_response_due_at TIMESTAMPTZ,
  resolve_due_at        TIMESTAMPTZ,
  first_responded_at    TIMESTAMPTZ,
  resolved_at           TIMESTAMPTZ,
  closed_at             TIMESTAMPTZ,
  resolution_notes      TEXT,
  csat_score            INT,
  csat_comment          TEXT,
  created_by_super_admin_id UUID REFERENCES public.super_admin_users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tickets.support_ticket_messages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES tickets.support_tickets(id) ON DELETE CASCADE,
  author_type       VARCHAR(20) NOT NULL,
  author_ref        VARCHAR(100),
  author_super_admin_id UUID REFERENCES public.super_admin_users(id),
  body              TEXT NOT NULL,
  is_first_response BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tickets.support_ticket_internal_notes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES tickets.support_tickets(id) ON DELETE CASCADE,
  body              TEXT NOT NULL,
  created_by        UUID REFERENCES public.super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tickets.support_ticket_attachments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES tickets.support_tickets(id) ON DELETE CASCADE,
  message_id        UUID REFERENCES tickets.support_ticket_messages(id) ON DELETE SET NULL,
  file_name         VARCHAR(255) NOT NULL,
  storage_url       TEXT NOT NULL,
  mime_type         VARCHAR(100),
  file_size_bytes   BIGINT,
  uploaded_by_type  VARCHAR(20) NOT NULL,
  uploaded_by_ref   VARCHAR(100),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tickets.support_ticket_events (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id         UUID NOT NULL REFERENCES tickets.support_tickets(id) ON DELETE CASCADE,
  event_type        VARCHAR(30) NOT NULL,
  from_value        VARCHAR(100),
  to_value          VARCHAR(100),
  note              TEXT,
  performed_by      UUID REFERENCES public.super_admin_users(id),
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
