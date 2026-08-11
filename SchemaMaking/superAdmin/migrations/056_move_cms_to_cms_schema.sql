-- Move CMS + portal banners into schema `cms`
-- FKs to public.super_admin_users preserved.

CREATE SCHEMA IF NOT EXISTS cms;

COMMENT ON SCHEMA cms IS
  'CMS & portal banners — media, pages, posts, salon portal promos';

ALTER TABLE IF EXISTS public.cms_media SET SCHEMA cms;
ALTER TABLE IF EXISTS public.cms_pages SET SCHEMA cms;
ALTER TABLE IF EXISTS public.cms_posts SET SCHEMA cms;
ALTER TABLE IF EXISTS public.portal_banners SET SCHEMA cms;

GRANT USAGE ON SCHEMA cms TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cms TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA cms
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA cms TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA cms
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
