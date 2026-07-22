-- KYC, GST certificate, and photo URLs (S3) at org and branch level

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS kyc_document_url TEXT,
  ADD COLUMN IF NOT EXISTS gst_certificate_url TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

ALTER TABLE branches
  ADD COLUMN IF NOT EXISTS kyc_document_url TEXT,
  ADD COLUMN IF NOT EXISTS gst_certificate_url TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

UPDATE organizations SET
  kyc_document_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || slug || '/kyc/owner-id.pdf',
  gst_certificate_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || slug || '/gst/gst-certificate.pdf',
  photo_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || slug || '/photos/org-cover.jpg';

UPDATE branches b SET
  kyc_document_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || o.slug || '/branches/' || b.slug || '/kyc/shop-license.pdf',
  gst_certificate_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || o.slug || '/branches/' || b.slug || '/gst/gst-certificate.pdf',
  photo_url = 'https://glowtap-assets.s3.ap-southeast-1.amazonaws.com/orgs/' || o.slug || '/branches/' || b.slug || '/photos/storefront.jpg'
FROM organizations o
WHERE o.id = b.organization_id;
