-- §4.9 CMS & Banner Management
-- 4.9.1 Public website CMS (pages, blog, media, SEO, publish workflow)
-- 4.9.2 Salon Admin portal promotional banners (targeting_rules JSONB)

-- ---------------------------------------------------------------------------
-- Media library (shared by CMS + banners)
-- ---------------------------------------------------------------------------
CREATE TABLE cms_media (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name       VARCHAR(255) NOT NULL,
  storage_url     TEXT NOT NULL,
  mime_type       VARCHAR(100) NOT NULL,
  media_type      VARCHAR(20) NOT NULL DEFAULT 'IMAGE'
    CHECK (media_type IN ('IMAGE', 'VIDEO', 'DOCUMENT', 'OTHER')),
  file_size_bytes BIGINT,
  alt_text        VARCHAR(255),
  width_px        INT,
  height_px       INT,
  duration_sec    INT,
  uploaded_by     UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cms_media_type ON cms_media(media_type, created_at DESC);

-- ---------------------------------------------------------------------------
-- Static / marketing pages (About, Pricing, Features, FAQ, Terms, Privacy)
-- ---------------------------------------------------------------------------
CREATE TABLE cms_pages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug              VARCHAR(100) NOT NULL UNIQUE,
  title             VARCHAR(255) NOT NULL,
  page_type         VARCHAR(30) NOT NULL DEFAULT 'CUSTOM'
    CHECK (page_type IN (
      'ABOUT', 'PRICING', 'FEATURES', 'FAQ', 'TERMS', 'PRIVACY', 'CUSTOM'
    )),
  body              JSONB NOT NULL DEFAULT '{}'::jsonb,
  seo_title         VARCHAR(255),
  seo_description   TEXT,
  og_image_media_id UUID REFERENCES cms_media(id) ON DELETE SET NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'ARCHIVED')),
  publish_at        TIMESTAMPTZ,
  published_at      TIMESTAMPTZ,
  preview_token     VARCHAR(64),
  sort_order        INT NOT NULL DEFAULT 0,
  created_by        UUID REFERENCES super_admin_users(id),
  updated_by        UUID REFERENCES super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cms_pages_status ON cms_pages(status, publish_at);
CREATE INDEX idx_cms_pages_type ON cms_pages(page_type);

-- ---------------------------------------------------------------------------
-- Blog / news posts
-- ---------------------------------------------------------------------------
CREATE TABLE cms_posts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug                VARCHAR(150) NOT NULL UNIQUE,
  title               VARCHAR(255) NOT NULL,
  excerpt             TEXT,
  body                JSONB NOT NULL DEFAULT '{}'::jsonb,
  cover_media_id      UUID REFERENCES cms_media(id) ON DELETE SET NULL,
  seo_title           VARCHAR(255),
  seo_description     TEXT,
  tags                TEXT[] NOT NULL DEFAULT '{}',
  status              VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'ARCHIVED')),
  publish_at          TIMESTAMPTZ,
  published_at        TIMESTAMPTZ,
  preview_token       VARCHAR(64),
  author_id           UUID REFERENCES super_admin_users(id),
  created_by          UUID REFERENCES super_admin_users(id),
  updated_by          UUID REFERENCES super_admin_users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cms_posts_status ON cms_posts(status, publish_at);
CREATE INDEX idx_cms_posts_published ON cms_posts(published_at DESC)
  WHERE status = 'PUBLISHED';

-- ---------------------------------------------------------------------------
-- Salon Admin portal banners (NOT end-customer app)
-- targeting_rules evaluated server-side against org context
-- ---------------------------------------------------------------------------
CREATE TABLE portal_banners (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             VARCHAR(255) NOT NULL,
  body_text         TEXT,
  image_media_id    UUID REFERENCES cms_media(id) ON DELETE SET NULL,
  image_url         TEXT,
  cta_text          VARCHAR(100),
  cta_link          TEXT,
  targeting_rules   JSONB NOT NULL DEFAULT '{}'::jsonb,
  display_priority  INT NOT NULL DEFAULT 100,
  active_from       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  active_until      TIMESTAMPTZ,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  ab_variant        VARCHAR(20),
  created_by        UUID REFERENCES super_admin_users(id),
  updated_by        UUID REFERENCES super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_portal_banners_active
  ON portal_banners(is_active, display_priority, active_from)
  WHERE is_active = TRUE;
CREATE INDEX idx_portal_banners_rules
  ON portal_banners USING GIN (targeting_rules);

COMMENT ON COLUMN portal_banners.targeting_rules IS
  'JSON rule tree evaluated vs org context. Example:
   {"all":[{"field":"plan_id","op":"eq","value":"<uuid>"},{"field":"days_to_expiry","op":"lte","value":30}]}
   Supported fields: plan_id, billing_cycle_id, tenure_months, days_to_expiry,
   branch_limit_reached, active_branch_count, org_status, always.';

-- ---------------------------------------------------------------------------
-- RLS / Data API
-- ---------------------------------------------------------------------------
ALTER TABLE cms_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON cms_media
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON cms_media TO authenticated;

ALTER TABLE cms_pages ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON cms_pages
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON cms_pages TO authenticated;

ALTER TABLE cms_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON cms_posts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON cms_posts TO authenticated;

ALTER TABLE portal_banners ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON portal_banners
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON portal_banners TO authenticated;

-- ---------------------------------------------------------------------------
-- MOCK — media
-- ---------------------------------------------------------------------------
INSERT INTO cms_media (
  id, file_name, storage_url, mime_type, media_type, file_size_bytes, alt_text, uploaded_by
) VALUES
(
  'f7000000-0000-4000-8000-000000000001',
  'hero-pricing.png',
  'https://cdn.glowtap.example/cms/hero-pricing.png',
  'image/png', 'IMAGE', 245760, 'GlowTap pricing hero',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000002',
  'banner-upgrade-12m.png',
  'https://cdn.glowtap.example/banners/upgrade-12m.png',
  'image/png', 'IMAGE', 128000, 'Upgrade to 12M plan',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000003',
  'banner-renewal.png',
  'https://cdn.glowtap.example/banners/renewal.png',
  'image/png', 'IMAGE', 118000, 'Renewal offer',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000004',
  'banner-branch-limit.png',
  'https://cdn.glowtap.example/banners/branch-limit.png',
  'image/png', 'IMAGE', 98000, 'Branch limit upgrade',
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- MOCK — CMS pages
-- ---------------------------------------------------------------------------
INSERT INTO cms_pages (
  id, slug, title, page_type, body, seo_title, seo_description,
  status, publish_at, published_at, sort_order, created_by, updated_by
) VALUES
(
  'f7000000-0000-4000-8000-000000000101',
  'about', 'About GlowTap', 'ABOUT',
  '{"blocks":[{"type":"heading","text":"Tap. Book. Glow."},{"type":"paragraph","text":"GlowTap connects salons and customers across India."}]}'::jsonb,
  'About GlowTap | Salon marketplace',
  'Learn how GlowTap helps salons grow with bookings, billing, and multi-branch tools.',
  'PUBLISHED', TIMESTAMPTZ '2026-01-01 00:00:00+05:30', TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  10, 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000102',
  'pricing', 'Pricing', 'PRICING',
  '{"blocks":[{"type":"heading","text":"Plans for every salon"},{"type":"plans","ref":"subscription_plans"}]}'::jsonb,
  'GlowTap Pricing',
  'Starter, Growth, Professional, and Enterprise plans with branch limits.',
  'PUBLISHED', TIMESTAMPTZ '2026-01-01 00:00:00+05:30', TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  20, 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000103',
  'features', 'Features', 'FEATURES',
  '{"blocks":[{"type":"heading","text":"Everything your salon needs"}]}'::jsonb,
  'GlowTap Features',
  'Appointments, staff, services, multi-branch, and marketplace payments.',
  'PUBLISHED', TIMESTAMPTZ '2026-01-01 00:00:00+05:30', TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  30, 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000104',
  'faq', 'FAQ', 'FAQ',
  '{"blocks":[{"type":"faq","items":[{"q":"How do commissions work?","a":"Cash bookings accrue outstanding; online recovers from payouts."}]}]}'::jsonb,
  'GlowTap FAQ',
  'Frequently asked questions about GlowTap for salons.',
  'PUBLISHED', TIMESTAMPTZ '2026-01-01 00:00:00+05:30', TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  40, 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000105',
  'terms', 'Terms of Service', 'TERMS',
  '{"blocks":[{"type":"paragraph","text":"Terms draft content..."}]}'::jsonb,
  'GlowTap Terms of Service',
  'Legal terms for using GlowTap.',
  'DRAFT', NULL, NULL,
  50, 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000106',
  'privacy', 'Privacy Policy', 'PRIVACY',
  '{"blocks":[{"type":"paragraph","text":"Privacy draft content..."}]}'::jsonb,
  'GlowTap Privacy Policy',
  'How GlowTap handles personal data (DPDP).',
  'SCHEDULED', TIMESTAMPTZ '2026-08-01 00:00:00+05:30', NULL,
  60, 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- MOCK — blog post
-- ---------------------------------------------------------------------------
INSERT INTO cms_posts (
  id, slug, title, excerpt, body, cover_media_id, seo_title, seo_description, tags,
  status, publish_at, published_at, author_id, created_by, updated_by
) VALUES (
  'f7000000-0000-4000-8000-000000000201',
  'why-multi-branch-salons-choose-glowtap',
  'Why multi-branch salons choose GlowTap',
  'Central dashboard, per-branch ops, and marketplace settlement in one place.',
  '{"blocks":[{"type":"paragraph","text":"Growing salon chains need unified booking and billing..."}]}'::jsonb,
  'f7000000-0000-4000-8000-000000000001',
  'Why multi-branch salons choose GlowTap',
  'How GlowTap helps salon chains manage branches, staff, and payments.',
  ARRAY['product', 'multi-branch'],
  'PUBLISHED',
  TIMESTAMPTZ '2026-06-15 10:00:00+05:30',
  TIMESTAMPTZ '2026-06-15 10:00:00+05:30',
  'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- MOCK — portal banners (spec example rules)
-- Plan IDs: Starter d..001, Growth d..002, Professional d..003, Enterprise d..004
-- Cycle IDs: 1M f..001, 6M f..002, 12M f..003, 24M f..004 (from 015)
-- ---------------------------------------------------------------------------
INSERT INTO portal_banners (
  id, title, body_text, image_media_id, cta_text, cta_link,
  targeting_rules, display_priority, active_from, active_until, is_active, created_by
) VALUES
(
  'f7000000-0000-4000-8000-000000000301',
  'Upgrade to 12M and save 20%',
  'You''ve been on a monthly plan for a while — switch to Professional 12M and save.',
  'f7000000-0000-4000-8000-000000000002',
  'Upgrade now',
  '/salon/subscription/upgrade?to=PRO_12M',
  '{
    "all": [
      {"field": "billing_cycle_id", "op": "eq", "value": "f1000000-0000-4000-8000-000000000001"},
      {"field": "tenure_months", "op": "gt", "value": 3}
    ]
  }'::jsonb,
  10,
  TIMESTAMPTZ '2026-07-01 00:00:00+05:30',
  TIMESTAMPTZ '2026-12-31 23:59:59+05:30',
  TRUE,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000302',
  'Renew 12M now and get 1 month free',
  'Your Professional plan renews soon. Renew early and get 1 extra month free.',
  'f7000000-0000-4000-8000-000000000003',
  'Renew with bonus',
  '/salon/subscription/renew?bonus=1m',
  '{
    "all": [
      {"field": "plan_id", "op": "eq", "value": "d1000000-0000-4000-8000-000000000003"},
      {"field": "days_to_expiry", "op": "lte", "value": 30}
    ]
  }'::jsonb,
  20,
  TIMESTAMPTZ '2026-07-01 00:00:00+05:30',
  NULL,
  TRUE,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000303',
  'Switch to 24M renewal and get 2 months free',
  'Lock in Enterprise for 24 months and get 2 months free on renewal.',
  'f7000000-0000-4000-8000-000000000003',
  'Switch to 24M',
  '/salon/subscription/upgrade?to=ENTERPRISE_24M&bonus=2m',
  '{
    "all": [
      {"field": "plan_id", "op": "eq", "value": "d1000000-0000-4000-8000-000000000003"},
      {"field": "days_to_expiry", "op": "lte", "value": 30}
    ]
  }'::jsonb,
  30,
  TIMESTAMPTZ '2026-07-01 00:00:00+05:30',
  NULL,
  TRUE,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000304',
  'Add more locations — upgrade your plan',
  'You''ve reached your branch limit. Upgrade to add more outlets.',
  'f7000000-0000-4000-8000-000000000004',
  'Upgrade plan',
  '/salon/subscription/upgrade',
  '{
    "all": [
      {"field": "branch_limit_reached", "op": "eq", "value": true}
    ]
  }'::jsonb,
  5,
  TIMESTAMPTZ '2026-01-01 00:00:00+05:30',
  NULL,
  TRUE,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f7000000-0000-4000-8000-000000000305',
  'New: Marketplace commission wallet',
  'Track cash outstanding and online payouts in one place.',
  NULL,
  'Learn more',
  '/salon/help/marketplace-wallet',
  '{"all":[{"field":"always","op":"eq","value":true}]}'::jsonb,
  100,
  TIMESTAMPTZ '2026-07-01 00:00:00+05:30',
  TIMESTAMPTZ '2026-09-30 23:59:59+05:30',
  TRUE,
  'a1000000-0000-4000-8000-000000000001'
);

ANALYZE cms_media;
ANALYZE cms_pages;
ANALYZE cms_posts;
ANALYZE portal_banners;
