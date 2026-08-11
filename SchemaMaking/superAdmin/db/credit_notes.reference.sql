CREATE TABLE rms.credit_notes (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id           UUID NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
  credit_note_number   VARCHAR(50) NOT NULL UNIQUE,
  status               VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  reason               TEXT,
  subtotal_amount      DECIMAL(12, 2) NOT NULL DEFAULT 0,
  tax_amount           DECIMAL(12, 2) NOT NULL DEFAULT 0,
  total_amount         DECIMAL(12, 2) NOT NULL DEFAULT 0,
  settlement_method    VARCHAR(30) NOT NULL
    CHECK (settlement_method IN ('REFUND', 'APPLY_NEXT_INVOICE', 'MANUAL')),
  applied_to_invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
  settled_at           TIMESTAMPTZ,
  pdf_url              TEXT,
  issued_at            TIMESTAMPTZ,
  created_by           UUID REFERENCES super_admin_users(id),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
