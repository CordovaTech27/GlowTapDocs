-- Move support ticketing into schema `tickets`
-- User-listed: support_tickets, messages, internal_notes, attachments, events
-- Also CTS + SLA (tickets FK to categories/types/subtypes/sla)

CREATE SCHEMA IF NOT EXISTS tickets;

COMMENT ON SCHEMA tickets IS
  'Support ticketing — CTS, SLA, tickets, messages, notes, attachments, events';

ALTER TABLE IF EXISTS public.support_ticket_categories SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_ticket_types SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_ticket_subtypes SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_sla_policies SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_tickets SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_ticket_messages SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_ticket_internal_notes SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_ticket_attachments SET SCHEMA tickets;
ALTER TABLE IF EXISTS public.support_ticket_events SET SCHEMA tickets;

GRANT USAGE ON SCHEMA tickets TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA tickets TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA tickets
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tickets TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA tickets
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
