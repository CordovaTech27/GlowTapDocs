-- §4.12 Reviews & Ratings Moderation (Super Admin)
-- Rule-based only (no ML). Image standards: max size / count / mime — no width/height.
-- booking / end_user soft refs until those modules exist.

-- ---------------------------------------------------------------------------
-- Platform moderation settings (single active row expected)
-- ---------------------------------------------------------------------------
CREATE TABLE review_moderation_settings (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  max_image_size_mb           DECIMAL(6, 2) NOT NULL DEFAULT 5.00
    CHECK (max_image_size_mb > 0),
  max_images_per_review       INT NOT NULL DEFAULT 3
    CHECK (max_images_per_review >= 0 AND max_images_per_review <= 10),
  allowed_mime_types          TEXT[] NOT NULL DEFAULT ARRAY['image/jpeg', 'image/png', 'image/webp'],
  edit_window_days            INT NOT NULL DEFAULT 7
    CHECK (edit_window_days >= 0),
  -- Deterministic publish policy (no ML)
  auto_publish_high_rating    BOOLEAN NOT NULL DEFAULT TRUE,
  auto_publish_min_rating     INT NOT NULL DEFAULT 4
    CHECK (auto_publish_min_rating BETWEEN 1 AND 5),
  auto_publish_requires_no_text   BOOLEAN NOT NULL DEFAULT TRUE,
  auto_publish_requires_no_image  BOOLEAN NOT NULL DEFAULT TRUE,
  queue_if_has_image          BOOLEAN NOT NULL DEFAULT TRUE,
  queue_if_has_url_or_phone   BOOLEAN NOT NULL DEFAULT TRUE,
  max_reviews_per_user_per_day INT NOT NULL DEFAULT 10
    CHECK (max_reviews_per_user_per_day > 0),
  is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by                  UUID REFERENCES super_admin_users(id),
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE review_moderation_settings IS
  'Super Admin platform defaults for review moderation (image size, auto-publish, queue rules).';

-- ---------------------------------------------------------------------------
-- Configurable abuse / spam rules (web regex / thresholds — no ML)
-- ---------------------------------------------------------------------------
CREATE TABLE review_abuse_rules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(50) NOT NULL UNIQUE,
  label           VARCHAR(255) NOT NULL,
  description     TEXT,
  -- CONDITION examples in condition JSONB:
  -- {"type":"REGEX","field":"body","pattern":"(https?://|wa\\.me|whatsapp)"}
  -- {"type":"CONTAINS_PHONE","field":"body"}
  -- {"type":"MAX_PER_DAY","field":"end_user_ref","value":10}
  condition       JSONB NOT NULL DEFAULT '{}'::jsonb,
  action          VARCHAR(20) NOT NULL DEFAULT 'QUEUE'
    CHECK (action IN ('QUEUE', 'AUTO_HIDE', 'REJECT_UPLOAD')),
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      INT NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_abuse_rules_active
  ON review_abuse_rules(is_active, sort_order);

-- ---------------------------------------------------------------------------
-- Reviews (consumer-submitted; Super Admin moderates)
-- ---------------------------------------------------------------------------
CREATE TABLE reviews (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  branch_id             UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  booking_ref           VARCHAR(50) NOT NULL,
  end_user_ref          VARCHAR(50) NOT NULL,
  specialist_ref        VARCHAR(50),
  overall_rating        INT NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
  rating_service        INT CHECK (rating_service IS NULL OR rating_service BETWEEN 1 AND 5),
  rating_specialist     INT CHECK (rating_specialist IS NULL OR rating_specialist BETWEEN 1 AND 5),
  rating_cleanliness    INT CHECK (rating_cleanliness IS NULL OR rating_cleanliness BETWEEN 1 AND 5),
  rating_value          INT CHECK (rating_value IS NULL OR rating_value BETWEEN 1 AND 5),
  body                  TEXT,
  status                VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'PUBLISHED', 'HIDDEN', 'REJECTED')),
  -- Rule hits at submit time (deterministic flags, not ML scores)
  matched_rule_codes    TEXT[] NOT NULL DEFAULT '{}',
  submitted_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  edited_at             TIMESTAMPTZ,
  edit_deadline_at      TIMESTAMPTZ,
  published_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (booking_ref)
);

CREATE INDEX idx_reviews_moderation_queue
  ON reviews(status, submitted_at DESC);
CREATE INDEX idx_reviews_org_branch
  ON reviews(organization_id, branch_id, status);
CREATE INDEX idx_reviews_end_user
  ON reviews(end_user_ref, submitted_at DESC);

-- ---------------------------------------------------------------------------
-- Review images (max size enforced via settings; no width/height columns)
-- ---------------------------------------------------------------------------
CREATE TABLE review_images (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  storage_url       TEXT NOT NULL,
  file_name         VARCHAR(255),
  mime_type         VARCHAR(100) NOT NULL,
  file_size_bytes   BIGINT NOT NULL CHECK (file_size_bytes > 0),
  status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'REMOVED')),
  sort_order        INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_images_review
  ON review_images(review_id, sort_order);

-- ---------------------------------------------------------------------------
-- Salon public reply (Super Admin can hide)
-- ---------------------------------------------------------------------------
CREATE TABLE review_replies (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL UNIQUE REFERENCES reviews(id) ON DELETE CASCADE,
  organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  body              TEXT NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED'
    CHECK (status IN ('PENDING', 'PUBLISHED', 'HIDDEN')),
  replied_by_ref    VARCHAR(100),
  replied_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_replies_status
  ON review_replies(status, replied_at DESC);

-- ---------------------------------------------------------------------------
-- Flags / reports (flagged-review management)
-- ---------------------------------------------------------------------------
CREATE TABLE review_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  reply_id          UUID REFERENCES review_replies(id) ON DELETE SET NULL,
  reporter_type     VARCHAR(20) NOT NULL
    CHECK (reporter_type IN ('END_USER', 'SALON', 'SYSTEM')),
  reporter_ref      VARCHAR(100),
  reason_code       VARCHAR(40) NOT NULL
    CHECK (reason_code IN (
      'SPAM', 'ABUSE', 'FAKE', 'INAPPROPRIATE_IMAGE', 'INAPPROPRIATE_TEXT', 'OTHER'
    )),
  notes             TEXT,
  status            VARCHAR(20) NOT NULL DEFAULT 'OPEN'
    CHECK (status IN ('OPEN', 'REVIEWED', 'DISMISSED')),
  resolved_by       UUID REFERENCES super_admin_users(id),
  resolved_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_reports_open
  ON review_reports(status, created_at DESC)
  WHERE status = 'OPEN';
CREATE INDEX idx_review_reports_review
  ON review_reports(review_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Moderation audit (reason lives here — not denormalized on reviews)
-- ---------------------------------------------------------------------------
CREATE TABLE review_moderation_actions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id         UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  reply_id          UUID REFERENCES review_replies(id) ON DELETE SET NULL,
  image_id          UUID REFERENCES review_images(id) ON DELETE SET NULL,
  action            VARCHAR(30) NOT NULL
    CHECK (action IN (
      'AUTO_APPROVE', 'APPROVE', 'REJECT', 'HIDE', 'RESTORE',
      'HIDE_IMAGE', 'RESTORE_IMAGE',
      'HIDE_REPLY', 'RESTORE_REPLY'
    )),
  reason            TEXT,
  metadata          JSONB,
  performed_by      UUID REFERENCES super_admin_users(id),
  performed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_moderation_actions_review
  ON review_moderation_actions(review_id, performed_at DESC);

-- ---------------------------------------------------------------------------
-- RLS / Data API
-- ---------------------------------------------------------------------------
ALTER TABLE review_moderation_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON review_moderation_settings
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON review_moderation_settings TO authenticated;

ALTER TABLE review_abuse_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON review_abuse_rules
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON review_abuse_rules TO authenticated;

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON reviews
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;

ALTER TABLE review_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON review_images
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON review_images TO authenticated;

ALTER TABLE review_replies ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON review_replies
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON review_replies TO authenticated;

ALTER TABLE review_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON review_reports
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON review_reports TO authenticated;

ALTER TABLE review_moderation_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON review_moderation_actions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON review_moderation_actions TO authenticated;

-- ---------------------------------------------------------------------------
-- Seed — settings + abuse rules
-- ---------------------------------------------------------------------------
INSERT INTO review_moderation_settings (
  id, max_image_size_mb, max_images_per_review, allowed_mime_types,
  edit_window_days, auto_publish_high_rating, auto_publish_min_rating,
  auto_publish_requires_no_text, auto_publish_requires_no_image,
  queue_if_has_image, queue_if_has_url_or_phone, max_reviews_per_user_per_day,
  updated_by
) VALUES (
  'f8000000-0000-4000-8000-000000000001',
  5.00, 3, ARRAY['image/jpeg', 'image/png', 'image/webp'],
  7, TRUE, 4,
  TRUE, TRUE,
  TRUE, TRUE, 10,
  'a1000000-0000-4000-8000-000000000001'
);

INSERT INTO review_abuse_rules (
  id, code, label, description, condition, action, is_active, sort_order, created_by
) VALUES
(
  'f8000000-0000-4000-8000-000000000011',
  'URL_OR_CONTACT',
  'URL / WhatsApp / phone in review text',
  'Queue reviews that look like spam contact outreach.',
  '{"type":"REGEX","field":"body","pattern":"(https?://|www\\\\.|wa\\\\.me|whatsapp|\\\\+?\\\\d[\\\\d\\\\s\\\\-]{8,})"}'::jsonb,
  'QUEUE', TRUE, 10,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f8000000-0000-4000-8000-000000000012',
  'HAS_IMAGE',
  'Review includes image',
  'Queue for human check when images are attached (no ML NSFW).',
  '{"type":"HAS_IMAGE"}'::jsonb,
  'QUEUE', TRUE, 20,
  'a1000000-0000-4000-8000-000000000001'
),
(
  'f8000000-0000-4000-8000-000000000013',
  'DAILY_CAP',
  'Max reviews per user per day',
  'Reject further submissions over daily cap from settings.',
  '{"type":"MAX_PER_DAY","field":"end_user_ref"}'::jsonb,
  'REJECT_UPLOAD', TRUE, 30,
  'a1000000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- Seed — sample moderation queue items (Looks / Enrich)
-- ---------------------------------------------------------------------------
INSERT INTO reviews (
  id, organization_id, branch_id, booking_ref, end_user_ref,
  overall_rating, rating_service, body, status, matched_rule_codes,
  submitted_at, edit_deadline_at, published_at
) VALUES
(
  'f8000000-0000-4000-8000-000000000101',
  'b1000000-0000-4000-8000-000000000001',
  'c1000000-0000-4000-8000-000000000001',
  'BK-LKS-9001', 'EU-5001',
  5, 5, NULL, 'PUBLISHED', '{}',
  TIMESTAMPTZ '2026-07-20 18:00:00+05:30',
  TIMESTAMPTZ '2026-07-27 18:00:00+05:30',
  TIMESTAMPTZ '2026-07-20 18:00:05+05:30'
),
(
  'f8000000-0000-4000-8000-000000000102',
  'b1000000-0000-4000-8000-000000000001',
  'c1000000-0000-4000-8000-000000000002',
  'BK-LKS-9002', 'EU-5002',
  2, 2,
  'Bad service. Call me on WhatsApp +91 98765 43210 for details.',
  'PENDING', ARRAY['URL_OR_CONTACT'],
  TIMESTAMPTZ '2026-07-22 11:30:00+05:30',
  TIMESTAMPTZ '2026-07-29 11:30:00+05:30',
  NULL
),
(
  'f8000000-0000-4000-8000-000000000103',
  'b1000000-0000-4000-8000-000000000003',
  'c1000000-0000-4000-8000-000000000006',
  'BK-ENR-9003', 'EU-5003',
  4, 4, 'Loved the keratin result!',
  'PENDING', ARRAY['HAS_IMAGE'],
  TIMESTAMPTZ '2026-07-23 16:10:00+05:30',
  TIMESTAMPTZ '2026-07-30 16:10:00+05:30',
  NULL
);

INSERT INTO review_images (
  id, review_id, storage_url, file_name, mime_type, file_size_bytes, status, sort_order
) VALUES (
  'f8000000-0000-4000-8000-000000000201',
  'f8000000-0000-4000-8000-000000000103',
  'https://cdn.glowtap.example/reviews/enr-9003-1.jpg',
  'keratin-result.jpg',
  'image/jpeg',
  1843200,
  'ACTIVE',
  0
);

INSERT INTO review_replies (
  id, review_id, organization_id, body, status, replied_by_ref, replied_at
) VALUES (
  'f8000000-0000-4000-8000-000000000301',
  'f8000000-0000-4000-8000-000000000101',
  'b1000000-0000-4000-8000-000000000001',
  'Thank you! We hope to see you again at Andheri.',
  'PUBLISHED',
  'salon_admin:priya@lookssalon.in',
  TIMESTAMPTZ '2026-07-21 09:00:00+05:30'
);

INSERT INTO review_reports (
  id, review_id, reporter_type, reporter_ref, reason_code, notes, status, created_at
) VALUES (
  'f8000000-0000-4000-8000-000000000401',
  'f8000000-0000-4000-8000-000000000102',
  'SALON',
  'org:b1000000-0000-4000-8000-000000000001',
  'SPAM',
  'Contains phone / WhatsApp solicitation',
  'OPEN',
  TIMESTAMPTZ '2026-07-22 12:00:00+05:30'
);

ANALYZE review_moderation_settings;
ANALYZE review_abuse_rules;
ANALYZE reviews;
ANALYZE review_images;
ANALYZE review_replies;
ANALYZE review_reports;
ANALYZE review_moderation_actions;
