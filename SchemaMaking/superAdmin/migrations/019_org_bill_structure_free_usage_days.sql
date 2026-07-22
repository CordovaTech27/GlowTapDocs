-- Total free-usage days granted to the organization (trial / complimentary)

ALTER TABLE org_bill_structure
  ADD COLUMN IF NOT EXISTS free_usage_days INT NOT NULL DEFAULT 0
    CHECK (free_usage_days >= 0);
