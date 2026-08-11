-- Add discount fields to branch services (name/description/price/duration/photo already exist)

ALTER TABLE services.branch_services
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(12, 2)
    CHECK (discount_amount IS NULL OR discount_amount >= 0),
  ADD COLUMN IF NOT EXISTS discount_percent NUMERIC(5, 2)
    CHECK (discount_percent IS NULL OR (discount_percent >= 0 AND discount_percent <= 100)),
  ADD COLUMN IF NOT EXISTS discount_description TEXT;

-- Prefer one of amount or percent; both null = no discount
ALTER TABLE services.branch_services
  DROP CONSTRAINT IF EXISTS branch_services_discount_one_mode;

ALTER TABLE services.branch_services
  ADD CONSTRAINT branch_services_discount_one_mode
  CHECK (
    discount_amount IS NULL
    OR discount_percent IS NULL
  );

COMMENT ON COLUMN services.branch_services.discount_amount IS
  'Fixed INR discount off price (mutually exclusive with discount_percent)';
COMMENT ON COLUMN services.branch_services.discount_percent IS
  'Percent discount off price (mutually exclusive with discount_amount)';
COMMENT ON COLUMN services.branch_services.discount_description IS
  'Shown to customers (e.g. Festival offer, New customer deal)';

-- Demo: set a small % discount on Classic Hair Cut samples
UPDATE services.branch_services
SET
  discount_percent = 10.00,
  discount_description = 'Introductory offer — 10% off',
  updated_at = NOW()
WHERE name = 'Classic Hair Cut'
  AND discount_percent IS NULL
  AND discount_amount IS NULL;

ANALYZE services.branch_services;
