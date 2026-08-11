-- Seed sample review_moderation_actions (audit log examples)

-- Auto-published Looks review: system AUTO_APPROVE
INSERT INTO review_moderation_actions (
  id, review_id, action, reason, performed_by, performed_at
) VALUES (
  'f8000000-0000-4000-8000-000000000501',
  'f8000000-0000-4000-8000-000000000101',
  'AUTO_APPROVE',
  'Auto-publish (5★, no text, no image) — system rule',
  'a1000000-0000-4000-8000-000000000001',
  TIMESTAMPTZ '2026-07-20 18:00:05+05:30'
)
ON CONFLICT (id) DO NOTHING;

-- Pending spam review: Super Admin HIDE after salon report
INSERT INTO review_moderation_actions (
  id, review_id, action, reason, metadata, performed_by, performed_at
) VALUES (
  'f8000000-0000-4000-8000-000000000502',
  'f8000000-0000-4000-8000-000000000102',
  'HIDE',
  'WhatsApp / phone solicitation — policy violation',
  '{"report_id":"f8000000-0000-4000-8000-000000000401","matched_rules":["URL_OR_CONTACT"]}'::jsonb,
  'a1000000-0000-4000-8000-000000000001',
  TIMESTAMPTZ '2026-07-22 14:05:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

UPDATE reviews
SET status = 'HIDDEN', updated_at = NOW()
WHERE id = 'f8000000-0000-4000-8000-000000000102'
  AND status = 'PENDING';

UPDATE review_reports
SET status = 'REVIEWED',
    resolved_by = 'a1000000-0000-4000-8000-000000000001',
    resolved_at = TIMESTAMPTZ '2026-07-22 14:05:00+05:30'
WHERE id = 'f8000000-0000-4000-8000-000000000401'
  AND status = 'OPEN';

-- Enrich image review still PENDING — no action yet (still in queue)
