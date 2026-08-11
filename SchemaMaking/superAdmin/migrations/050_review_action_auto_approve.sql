-- Distinguish system auto-publish from human APPROVE

ALTER TABLE review_moderation_actions
  DROP CONSTRAINT IF EXISTS review_moderation_actions_action_check;

ALTER TABLE review_moderation_actions
  ADD CONSTRAINT review_moderation_actions_action_check
  CHECK (action IN (
    'AUTO_APPROVE', 'APPROVE', 'REJECT', 'HIDE', 'RESTORE',
    'HIDE_IMAGE', 'RESTORE_IMAGE',
    'HIDE_REPLY', 'RESTORE_REPLY'
  ));

UPDATE review_moderation_actions
SET action = 'AUTO_APPROVE',
    reason = 'Auto-publish (5★, no text, no image) — system rule'
WHERE id = 'f8000000-0000-4000-8000-000000000501'
  AND action = 'APPROVE';
