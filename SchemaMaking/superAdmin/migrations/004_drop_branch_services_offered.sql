-- Services will be linked to branches via a separate junction table (future migration).

ALTER TABLE branches DROP COLUMN IF EXISTS services_offered;
