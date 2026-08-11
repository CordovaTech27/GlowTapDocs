-- Move platform service catalog into schema `services`

CREATE SCHEMA IF NOT EXISTS services;

COMMENT ON SCHEMA services IS
  'Platform service catalog — categories and subcategories';

ALTER TABLE IF EXISTS public.service_categories SET SCHEMA services;
ALTER TABLE IF EXISTS public.service_subcategories SET SCHEMA services;

GRANT USAGE ON SCHEMA services TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA services TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA services
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA services TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA services
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
