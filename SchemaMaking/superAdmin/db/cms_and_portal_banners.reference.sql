-- §4.9 CMS & Banner Management (reference)

CREATE TABLE cms_media (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name       VARCHAR(255) NOT NULL,
  storage_url     TEXT NOT NULL,
  mime_type       VARCHAR(100) NOT NULL,
  media_type      VARCHAR(20) NOT NULL DEFAULT 'IMAGE',
  file_size_bytes BIGINT,
  alt_text        VARCHAR(255),
  width_px        INT,
  height_px       INT,
  duration_sec    INT,
  uploaded_by     UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cms_pages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug              VARCHAR(100) NOT NULL UNIQUE,
  title             VARCHAR(255) NOT NULL,
  page_type         VARCHAR(30) NOT NULL DEFAULT 'CUSTOM',
  body              JSONB NOT NULL DEFAULT '{}'::jsonb,
  seo_title         VARCHAR(255),
  seo_description   TEXT,
  og_image_media_id UUID REFERENCES cms_media(id) ON DELETE SET NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  publish_at        TIMESTAMPTZ,
  published_at      TIMESTAMPTZ,
  preview_token     VARCHAR(64),
  sort_order        INT NOT NULL DEFAULT 0,
  created_by        UUID REFERENCES super_admin_users(id),
  updated_by        UUID REFERENCES super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
  status              VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  publish_at          TIMESTAMPTZ,
  published_at        TIMESTAMPTZ,
  preview_token       VARCHAR(64),
  author_id           UUID REFERENCES super_admin_users(id),
  created_by          UUID REFERENCES super_admin_users(id),
  updated_by          UUID REFERENCES super_admin_users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
