-- Schema review — ratings, images, replies + moderation
-- FKs → public.organizations / public.branches / public.super_admin_users

CREATE TABLE review.review_moderation_settings (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  max_image_size_mb           DECIMAL(6, 2) NOT NULL DEFAULT 5.00,
  max_images_per_review       INT NOT NULL DEFAULT 3,
  allowed_mime_types          TEXT[] NOT NULL DEFAULT ARRAY['image/jpeg', 'image/png', 'image/webp'],
  edit_window_days            INT NOT NULL DEFAULT 7,
  auto_publish_high_rating    BOOLEAN NOT NULL DEFAULT TRUE,
  auto_publish_min_rating     INT NOT NULL DEFAULT 4,
  auto_publish_requires_no_text   BOOLEAN NOT NULL DEFAULT TRUE,
  auto_publish_requires_no_image  BOOLEAN NOT NULL DEFAULT TRUE,
  queue_if_has_image          BOOLEAN NOT NULL DEFAULT TRUE,
  queue_if_has_url_or_phone   BOOLEAN NOT NULL DEFAULT TRUE,
  max_reviews_per_user_per_day INT NOT NULL DEFAULT 10,
  is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by                  UUID REFERENCES public.super_admin_users(id),
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review.review_abuse_rules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(50) NOT NULL UNIQUE,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  condition       JSONB NOT NULL DEFAULT '{}'::jsonb,
  action          VARCHAR(20) NOT NULL DEFAULT 'QUEUE',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES public.super_admin_users(id),
  updated_by      UUID REFERENCES public.super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review.reviews (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  branch_id             UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  booking_ref           VARCHAR(50) NOT NULL UNIQUE,
  end_user_ref          VARCHAR(50) NOT NULL,
  specialist_ref        VARCHAR(50),
  overall_rating        INT NOT NULL,
  rating_service        INT,
  rating_specialist     INT,
  rating_cleanliness    INT,
  rating_value          INT,
  body                  TEXT,
  status                VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  matched_rule_codes    TEXT[] NOT NULL DEFAULT '{}',
  submitted_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  edited_at             TIMESTAMPTZ,
  edit_deadline_at      TIMESTAMPTZ,
  published_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review.review_images (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL REFERENCES review.reviews(id) ON DELETE CASCADE,
  storage_url       TEXT NOT NULL,
  file_name         VARCHAR(255),
  mime_type         VARCHAR(100) NOT NULL,
  file_size_bytes   BIGINT NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  sort_order        INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review.review_replies (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL UNIQUE REFERENCES review.reviews(id) ON DELETE CASCADE,
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  body              TEXT NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
  replied_by_ref    VARCHAR(100),
  replied_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review.review_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL REFERENCES review.reviews(id) ON DELETE CASCADE,
  reply_id          UUID REFERENCES review.review_replies(id) ON DELETE SET NULL,
  reporter_type     VARCHAR(20) NOT NULL,
  reporter_ref      VARCHAR(100),
  reason_code       VARCHAR(40) NOT NULL,
  notes             TEXT,
  status            VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  resolved_by       UUID REFERENCES public.super_admin_users(id),
  resolved_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE review.review_moderation_actions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL REFERENCES review.reviews(id) ON DELETE CASCADE,
  reply_id          UUID REFERENCES review.review_replies(id) ON DELETE SET NULL,
  image_id          UUID REFERENCES review.review_images(id) ON DELETE SET NULL,
  action            VARCHAR(30) NOT NULL,
  reason            TEXT,
  metadata          JSONB,
  performed_by      UUID REFERENCES public.super_admin_users(id),
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
