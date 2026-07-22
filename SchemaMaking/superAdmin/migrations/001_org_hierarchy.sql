-- GlowTap core hierarchy: Super Admin → Organization → Branch
-- Phase 1: foundation tables only

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE super_admin_users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name       VARCHAR(255) NOT NULL,
  email           VARCHAR(255) UNIQUE NOT NULL,
  phone           VARCHAR(20),
  role            VARCHAR(30) NOT NULL DEFAULT 'SUPER_ADMIN'
                  CHECK (role IN ('SUPER_ADMIN', 'READ_ONLY', 'OPS_AGENT')),
  status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                  CHECK (status IN ('ACTIVE', 'INACTIVE')),
  mfa_enabled     BOOLEAN NOT NULL DEFAULT FALSE,
  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscription_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(100) NOT NULL,
  description     TEXT,
  max_branches    INT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE organizations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                VARCHAR(255) NOT NULL,
  slug                VARCHAR(100) UNIQUE NOT NULL,
  legal_name          VARCHAR(255),
  owner_name          VARCHAR(255) NOT NULL,
  owner_email         VARCHAR(255) NOT NULL,
  owner_phone         VARCHAR(20),
  gst_number          VARCHAR(50),
  pan_number          VARCHAR(20),
  logo_url            TEXT,
  kyc_document_url    TEXT,
  gst_certificate_url TEXT,
  photo_url           TEXT,
  registered_address  JSONB NOT NULL,
  city                VARCHAR(100) NOT NULL,
  state               VARCHAR(100) NOT NULL,
  state_code          VARCHAR(2),
  pincode             VARCHAR(10),
  country             VARCHAR(50) NOT NULL DEFAULT 'India',
  business_type       VARCHAR(30)
                      CHECK (business_type IN ('SOLE_PROPRIETOR', 'PARTNERSHIP', 'LLP', 'PRIVATE_LIMITED', 'PUBLIC_LIMITED', 'OTHER')),
  cin                 VARCHAR(21),
  udyam_msme_number   VARCHAR(20),
  gst_registration_type VARCHAR(20)
                      CHECK (gst_registration_type IN ('REGULAR', 'COMPOSITION', 'UNREGISTERED')),
  kyc_status          VARCHAR(20) NOT NULL DEFAULT 'NOT_SUBMITTED'
                      CHECK (kyc_status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED')),
  kyc_verified_at     TIMESTAMPTZ,
  kyc_verified_by     UUID REFERENCES super_admin_users(id),
  signed_agreement_url TEXT,
  is_agreement_signed BOOLEAN NOT NULL DEFAULT FALSE,
  status              VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'TERMINATED')),
  subscription_plan_id UUID REFERENCES subscription_plans(id),
  commission_pct      DECIMAL(5,2) NOT NULL DEFAULT 5.00,
  onboarded_at        TIMESTAMPTZ,
  approved_at         TIMESTAMPTZ,
  approved_by         UUID REFERENCES super_admin_users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE branches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name              VARCHAR(255) NOT NULL,
  slug              VARCHAR(100) NOT NULL,
  address           JSONB NOT NULL,
  contact_phone     VARCHAR(20),
  contact_email     VARCHAR(255),
  operating_hours   JSONB,
  latitude          DECIMAL(10,7),
  longitude         DECIMAL(10,7),
  status            VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING', 'ACTIVE', 'INACTIVE', 'REJECTED')),
  is_primary        BOOLEAN NOT NULL DEFAULT FALSE,
  kyc_document_url  TEXT,
  gst_certificate_url TEXT,
  photo_url         TEXT,
  branch_state_code VARCHAR(2),
  shop_establishment_license_url TEXT,
  trade_license_url TEXT,
  branch_gst_number VARCHAR(50),
  kyc_status        VARCHAR(20) NOT NULL DEFAULT 'NOT_SUBMITTED'
                    CHECK (kyc_status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED')),
  kyc_verified_at   TIMESTAMPTZ,
  kyc_verified_by   UUID REFERENCES super_admin_users(id),
  signed_agreement_url TEXT,
  is_agreement_signed BOOLEAN NOT NULL DEFAULT FALSE,
  approved_at       TIMESTAMPTZ,
  approved_by       UUID REFERENCES super_admin_users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, slug)
);

CREATE INDEX idx_organizations_status ON organizations(status);
CREATE INDEX idx_organizations_city ON organizations(city);
CREATE INDEX idx_organizations_subscription_plan ON organizations(subscription_plan_id);
CREATE INDEX idx_organizations_kyc_status ON organizations(kyc_status);
CREATE INDEX idx_branches_org ON branches(organization_id);
CREATE INDEX idx_branches_status ON branches(status);
CREATE INDEX idx_branches_kyc_status ON branches(kyc_status);
CREATE INDEX idx_branches_city ON branches((address->>'city'));
