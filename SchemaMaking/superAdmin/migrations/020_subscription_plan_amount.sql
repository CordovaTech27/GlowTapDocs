-- Catalog price for each subscription plan (base list price in INR)

ALTER TABLE subscription_plans
  ADD COLUMN IF NOT EXISTS amount DECIMAL(12, 2) NOT NULL DEFAULT 0
    CHECK (amount >= 0);

UPDATE subscription_plans SET amount = 999.00  WHERE name = 'Starter';
UPDATE subscription_plans SET amount = 2499.00 WHERE name = 'Growth';
UPDATE subscription_plans SET amount = 4999.00 WHERE name = 'Professional';
UPDATE subscription_plans SET amount = 9999.00 WHERE name = 'Enterprise';
