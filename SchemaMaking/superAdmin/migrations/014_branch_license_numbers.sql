-- Branch license numbers (paired with license document URLs)

ALTER TABLE branches
  ADD COLUMN IF NOT EXISTS shop_establishment_license_number VARCHAR(50),
  ADD COLUMN IF NOT EXISTS trade_license_number VARCHAR(50);

-- Dummy license numbers for seeded branches
UPDATE branches b SET
  shop_establishment_license_number = 'SE/' || REPLACE(o.slug, '-', '') || '/' || REPLACE(b.slug, '-', '') || '/2024',
  trade_license_number = 'TL/' || REPLACE(o.slug, '-', '') || '/' || REPLACE(b.slug, '-', '') || '/2024'
FROM organizations o
WHERE o.id = b.organization_id
  AND b.status IN ('ACTIVE', 'PENDING');
