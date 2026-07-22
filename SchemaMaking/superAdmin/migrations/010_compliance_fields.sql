-- Compliance: agreements, KYC workflow, business identity, branch licenses, GST state codes

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS signed_agreement_url TEXT,
  ADD COLUMN IF NOT EXISTS is_agreement_signed BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS business_type VARCHAR(30)
    CHECK (business_type IN ('SOLE_PROPRIETOR', 'PARTNERSHIP', 'LLP', 'PRIVATE_LIMITED', 'PUBLIC_LIMITED', 'OTHER')),
  ADD COLUMN IF NOT EXISTS cin VARCHAR(21),
  ADD COLUMN IF NOT EXISTS udyam_msme_number VARCHAR(20),
  ADD COLUMN IF NOT EXISTS gst_registration_type VARCHAR(20)
    CHECK (gst_registration_type IN ('REGULAR', 'COMPOSITION', 'UNREGISTERED')),
  ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(20) NOT NULL DEFAULT 'NOT_SUBMITTED'
    CHECK (kyc_status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED')),
  ADD COLUMN IF NOT EXISTS kyc_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS kyc_verified_by UUID REFERENCES super_admin_users(id),
  ADD COLUMN IF NOT EXISTS state_code VARCHAR(2);

ALTER TABLE branches
  ADD COLUMN IF NOT EXISTS signed_agreement_url TEXT,
  ADD COLUMN IF NOT EXISTS is_agreement_signed BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS shop_establishment_license_url TEXT,
  ADD COLUMN IF NOT EXISTS trade_license_url TEXT,
  ADD COLUMN IF NOT EXISTS branch_gst_number VARCHAR(50),
  ADD COLUMN IF NOT EXISTS kyc_status VARCHAR(20) NOT NULL DEFAULT 'NOT_SUBMITTED'
    CHECK (kyc_status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED')),
  ADD COLUMN IF NOT EXISTS kyc_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS kyc_verified_by UUID REFERENCES super_admin_users(id),
  ADD COLUMN IF NOT EXISTS branch_state_code VARCHAR(2);

-- Organizations: compliance seed
UPDATE organizations SET
  business_type = 'PRIVATE_LIMITED',
  cin = 'U74999MH2015PTC123456',
  udyam_msme_number = 'UDYAM-MH-12-0012345',
  gst_registration_type = 'REGULAR',
  state_code = '27',
  kyc_status = 'VERIFIED',
  kyc_verified_at = '2025-11-16 10:00:00+05:30',
  kyc_verified_by = 'a1000000-0000-4000-8000-000000000001',
  is_agreement_signed = TRUE,
  signed_agreement_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/looks-salon-spa/agreements/signed-agreement.pdf'
WHERE slug = 'looks-salon-spa';

UPDATE organizations SET
  business_type = 'LLP',
  cin = NULL,
  udyam_msme_number = 'UDYAM-DL-07-0023456',
  gst_registration_type = 'REGULAR',
  state_code = '07',
  kyc_status = 'VERIFIED',
  kyc_verified_at = '2026-01-09 09:15:00+05:30',
  kyc_verified_by = 'a1000000-0000-4000-8000-000000000001',
  is_agreement_signed = TRUE,
  signed_agreement_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/glamour-zone/agreements/signed-agreement.pdf'
WHERE slug = 'glamour-zone';

UPDATE organizations SET
  business_type = 'SOLE_PROPRIETOR',
  cin = NULL,
  udyam_msme_number = 'UDYAM-KA-29-0034567',
  gst_registration_type = 'REGULAR',
  state_code = '29',
  kyc_status = 'VERIFIED',
  kyc_verified_at = '2026-03-21 08:30:00+05:30',
  kyc_verified_by = 'a1000000-0000-4000-8000-000000000001',
  is_agreement_signed = TRUE,
  signed_agreement_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/enrich-salon/agreements/signed-agreement.pdf'
WHERE slug = 'enrich-salon';

UPDATE organizations SET
  business_type = 'PRIVATE_LIMITED',
  cin = 'U93090TN2010PTC789012',
  udyam_msme_number = 'UDYAM-TN-33-0045678',
  gst_registration_type = 'REGULAR',
  state_code = '33',
  kyc_status = 'VERIFIED',
  kyc_verified_at = '2025-06-02 11:00:00+05:30',
  kyc_verified_by = 'a1000000-0000-4000-8000-000000000001',
  is_agreement_signed = TRUE,
  signed_agreement_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/naturals-salon-partners/agreements/signed-agreement.pdf'
WHERE slug = 'naturals-salon-partners';

UPDATE organizations SET
  business_type = 'SOLE_PROPRIETOR',
  cin = NULL,
  udyam_msme_number = NULL,
  gst_registration_type = 'UNREGISTERED',
  state_code = '27',
  kyc_status = 'PENDING',
  kyc_verified_at = NULL,
  kyc_verified_by = NULL,
  is_agreement_signed = FALSE,
  signed_agreement_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/blush-and-bloom/agreements/signed-agreement.pdf'
WHERE slug = 'blush-and-bloom';

-- Branches: licenses, agreements, KYC, state codes
UPDATE branches b SET
  branch_state_code = CASE o.slug
    WHEN 'looks-salon-spa' THEN '27'
    WHEN 'glamour-zone' THEN '07'
    WHEN 'enrich-salon' THEN '29'
    WHEN 'naturals-salon-partners' THEN '33'
    WHEN 'blush-and-bloom' THEN '27'
  END,
  shop_establishment_license_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || o.slug || '/branches/' || b.slug || '/licenses/shop-establishment.pdf',
  trade_license_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || o.slug || '/branches/' || b.slug || '/licenses/trade-license.pdf',
  signed_agreement_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || o.slug || '/branches/' || b.slug || '/agreements/signed-agreement.pdf',
  is_agreement_signed = CASE WHEN b.status = 'ACTIVE' THEN TRUE ELSE FALSE END,
  kyc_status = CASE
    WHEN b.status = 'ACTIVE' THEN 'VERIFIED'
    WHEN b.status = 'PENDING' THEN 'PENDING'
    ELSE 'NOT_SUBMITTED'
  END,
  kyc_verified_at = CASE WHEN b.status = 'ACTIVE' THEN b.approved_at ELSE NULL END,
  kyc_verified_by = CASE WHEN b.status = 'ACTIVE' THEN b.approved_by ELSE NULL END,
  branch_gst_number = CASE WHEN o.slug = 'naturals-salon-partners' AND b.slug = 'omr-sholinganallur' THEN '33AABCN3456J1Z2' ELSE NULL END
FROM organizations o
WHERE o.id = b.organization_id;

CREATE INDEX IF NOT EXISTS idx_organizations_kyc_status ON organizations(kyc_status);
CREATE INDEX IF NOT EXISTS idx_branches_kyc_status ON branches(kyc_status);
