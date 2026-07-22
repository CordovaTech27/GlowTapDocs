-- Disable reason lives only on user_access_actions.reason (audit source of truth)

ALTER TABLE organizations
  DROP COLUMN IF EXISTS owner_disabled_reason;

ALTER TABLE sub_admins
  DROP COLUMN IF EXISTS disabled_reason;
