-- Move reviews domain into schema `review`
-- Core: reviews, review_images, review_replies
-- Also moderation companions (FK to reviews)

CREATE SCHEMA IF NOT EXISTS review;

COMMENT ON SCHEMA review IS
  'Reviews & ratings — reviews, images, replies, reports, moderation';

ALTER TABLE IF EXISTS public.reviews SET SCHEMA review;
ALTER TABLE IF EXISTS public.review_images SET SCHEMA review;
ALTER TABLE IF EXISTS public.review_replies SET SCHEMA review;
ALTER TABLE IF EXISTS public.review_reports SET SCHEMA review;
ALTER TABLE IF EXISTS public.review_moderation_actions SET SCHEMA review;
ALTER TABLE IF EXISTS public.review_moderation_settings SET SCHEMA review;
ALTER TABLE IF EXISTS public.review_abuse_rules SET SCHEMA review;

GRANT USAGE ON SCHEMA review TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA review TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA review
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA review TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA review
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
