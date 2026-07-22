-- Indian GST states master, per-state tax configuration, and state_id FKs on org/branch

CREATE TABLE states (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                VARCHAR(2) NOT NULL UNIQUE,
  name                VARCHAR(100) NOT NULL,
  iso_code            VARCHAR(3),
  is_union_territory  BOOLEAN NOT NULL DEFAULT FALSE,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE state_tax_configs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state_id        UUID NOT NULL REFERENCES states(id) ON DELETE CASCADE,
  tax_code        VARCHAR(30) NOT NULL,
  tax_name        VARCHAR(100) NOT NULL,
  rate_pct        NUMERIC(5, 2) NOT NULL CHECK (rate_pct >= 0 AND rate_pct <= 100),
  hsn_sac_code    VARCHAR(10),
  component_type  VARCHAR(20) NOT NULL
    CHECK (component_type IN ('CGST', 'SGST', 'IGST', 'CESS', 'COMPOSITE')),
  applies_to      VARCHAR(20) NOT NULL DEFAULT 'SERVICE'
    CHECK (applies_to IN ('SERVICE', 'PRODUCT', 'BOTH')),
  effective_from  DATE NOT NULL DEFAULT CURRENT_DATE,
  effective_to    DATE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  notes           TEXT,
  created_by      UUID REFERENCES super_admin_users(id),
  updated_by      UUID REFERENCES super_admin_users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (state_id, tax_code, effective_from),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX idx_state_tax_configs_state_id ON state_tax_configs(state_id);
CREATE INDEX idx_state_tax_configs_active ON state_tax_configs(state_id, is_active)
  WHERE is_active = TRUE;

-- Indian GST state / UT codes (CBIC)
INSERT INTO states (id, code, name, iso_code, is_union_territory) VALUES
('e1000000-0000-4000-8000-000000000001', '01', 'Jammu and Kashmir', 'JK', FALSE),
('e1000000-0000-4000-8000-000000000002', '02', 'Himachal Pradesh', 'HP', FALSE),
('e1000000-0000-4000-8000-000000000003', '03', 'Punjab', 'PB', FALSE),
('e1000000-0000-4000-8000-000000000004', '04', 'Chandigarh', 'CH', TRUE),
('e1000000-0000-4000-8000-000000000005', '05', 'Uttarakhand', 'UT', FALSE),
('e1000000-0000-4000-8000-000000000006', '06', 'Haryana', 'HR', FALSE),
('e1000000-0000-4000-8000-000000000007', '07', 'Delhi', 'DL', TRUE),
('e1000000-0000-4000-8000-000000000008', '08', 'Rajasthan', 'RJ', FALSE),
('e1000000-0000-4000-8000-000000000009', '09', 'Uttar Pradesh', 'UP', FALSE),
('e1000000-0000-4000-8000-000000000010', '10', 'Bihar', 'BR', FALSE),
('e1000000-0000-4000-8000-000000000011', '11', 'Sikkim', 'SK', FALSE),
('e1000000-0000-4000-8000-000000000012', '12', 'Arunachal Pradesh', 'AR', FALSE),
('e1000000-0000-4000-8000-000000000013', '13', 'Nagaland', 'NL', FALSE),
('e1000000-0000-4000-8000-000000000014', '14', 'Manipur', 'MN', FALSE),
('e1000000-0000-4000-8000-000000000015', '15', 'Mizoram', 'MZ', FALSE),
('e1000000-0000-4000-8000-000000000016', '16', 'Tripura', 'TR', FALSE),
('e1000000-0000-4000-8000-000000000017', '17', 'Meghalaya', 'ML', FALSE),
('e1000000-0000-4000-8000-000000000018', '18', 'Assam', 'AS', FALSE),
('e1000000-0000-4000-8000-000000000019', '19', 'West Bengal', 'WB', FALSE),
('e1000000-0000-4000-8000-000000000020', '20', 'Jharkhand', 'JH', FALSE),
('e1000000-0000-4000-8000-000000000021', '21', 'Odisha', 'OR', FALSE),
('e1000000-0000-4000-8000-000000000022', '22', 'Chhattisgarh', 'CG', FALSE),
('e1000000-0000-4000-8000-000000000023', '23', 'Madhya Pradesh', 'MP', FALSE),
('e1000000-0000-4000-8000-000000000024', '24', 'Gujarat', 'GJ', FALSE),
('e1000000-0000-4000-8000-000000000026', '26', 'Dadra and Nagar Haveli and Daman and Diu', 'DD', TRUE),
('e1000000-0000-4000-8000-000000000027', '27', 'Maharashtra', 'MH', FALSE),
('e1000000-0000-4000-8000-000000000029', '29', 'Karnataka', 'KA', FALSE),
('e1000000-0000-4000-8000-000000000030', '30', 'Goa', 'GA', FALSE),
('e1000000-0000-4000-8000-000000000031', '31', 'Lakshadweep', 'LD', TRUE),
('e1000000-0000-4000-8000-000000000032', '32', 'Kerala', 'KL', FALSE),
('e1000000-0000-4000-8000-000000000033', '33', 'Tamil Nadu', 'TN', FALSE),
('e1000000-0000-4000-8000-000000000034', '34', 'Puducherry', 'PY', TRUE),
('e1000000-0000-4000-8000-000000000035', '35', 'Andaman and Nicobar Islands', 'AN', TRUE),
('e1000000-0000-4000-8000-000000000036', '36', 'Telangana', 'TS', FALSE),
('e1000000-0000-4000-8000-000000000037', '37', 'Andhra Pradesh', 'AP', FALSE),
('e1000000-0000-4000-8000-000000000038', '38', 'Ladakh', 'LA', TRUE);

-- Replace state_code / branch_state_code with state_id FKs
ALTER TABLE organizations ADD COLUMN state_id UUID REFERENCES states(id);
ALTER TABLE branches ADD COLUMN state_id UUID REFERENCES states(id);

UPDATE organizations o
SET state_id = s.id
FROM states s
WHERE o.state_code = s.code;

UPDATE branches b
SET state_id = s.id
FROM states s
WHERE b.branch_state_code = s.code;

ALTER TABLE organizations DROP COLUMN IF EXISTS state_code;
ALTER TABLE branches DROP COLUMN IF EXISTS branch_state_code;

CREATE INDEX idx_organizations_state_id ON organizations(state_id);
CREATE INDEX idx_branches_state_id ON branches(state_id);

-- Salon/beauty services: 18% GST (9% CGST + 9% SGST intra-state; 18% IGST inter-state)
-- HSN 999714 — beauty and physical well-being services
INSERT INTO state_tax_configs (
  id, state_id, tax_code, tax_name, rate_pct, hsn_sac_code,
  component_type, applies_to, notes, created_by
)
SELECT
  gen_random_uuid(),
  s.id,
  v.tax_code,
  v.tax_name,
  v.rate_pct,
  '999714',
  v.component_type,
  'SERVICE',
  v.notes,
  'a1000000-0000-4000-8000-000000000001'
FROM states s
CROSS JOIN (
  VALUES
    ('CGST_SALON', 'CGST on salon services', 9.00, 'CGST', 'Intra-state central component'),
    ('SGST_SALON', 'SGST on salon services', 9.00, 'SGST', 'Intra-state state component'),
    ('IGST_SALON', 'IGST on salon services', 18.00, 'IGST', 'Inter-state supply')
) AS v(tax_code, tax_name, rate_pct, component_type, notes)
WHERE s.code IN ('07', '27', '29', '33')
ON CONFLICT (state_id, tax_code, effective_from) DO NOTHING;

-- Data API RLS for new tables
ALTER TABLE states ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON states
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE state_tax_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY data_api_authenticated_all ON state_tax_configs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON states TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON state_tax_configs TO authenticated;
