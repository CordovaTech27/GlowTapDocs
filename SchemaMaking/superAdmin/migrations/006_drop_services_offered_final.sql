-- Remove services_offered permanently. Services use branch_services junction table later.

ALTER TABLE branches DROP COLUMN IF EXISTS services_offered;
