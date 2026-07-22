-- Make credit note settlement explicit (refund vs apply on next invoice)

ALTER TABLE credit_notes
  ADD COLUMN IF NOT EXISTS settlement_method VARCHAR(30)
    CHECK (settlement_method IN ('REFUND', 'APPLY_NEXT_INVOICE', 'MANUAL')),
  ADD COLUMN IF NOT EXISTS applied_to_invoice_id UUID
    REFERENCES invoices(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS settled_at TIMESTAMPTZ;

-- Existing seeded credit note was cash-refunded
UPDATE credit_notes
SET
  settlement_method = 'REFUND',
  settled_at = TIMESTAMPTZ '2026-06-10 14:32:00+05:30'
WHERE id = 'e2000000-0000-4000-8000-000000000051'
  AND settlement_method IS NULL;

ALTER TABLE credit_notes
  ALTER COLUMN settlement_method SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_credit_notes_settlement
  ON credit_notes(settlement_method, status);

CREATE INDEX IF NOT EXISTS idx_credit_notes_applied_invoice
  ON credit_notes(applied_to_invoice_id)
  WHERE applied_to_invoice_id IS NOT NULL;

-- Second demo: carry-forward credit (settle on next invoice — no refund row)
INSERT INTO credit_notes (
  id,
  invoice_id,
  credit_note_number,
  status,
  reason,
  subtotal_amount,
  tax_amount,
  total_amount,
  settlement_method,
  applied_to_invoice_id,
  settled_at,
  issued_at,
  created_by
)
SELECT
  'e2000000-0000-4000-8000-000000000071',
  'e2000000-0000-4000-8000-000000000001',
  'GT-CN-2026-00002',
  'ISSUED',
  'NRC discount credit — apply on next renewal invoice.',
  200.00,
  36.00,
  236.00,
  'APPLY_NEXT_INVOICE',
  NULL,
  NULL,
  TIMESTAMPTZ '2026-06-15 11:00:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
WHERE NOT EXISTS (
  SELECT 1 FROM credit_notes WHERE id = 'e2000000-0000-4000-8000-000000000071'
);

INSERT INTO credit_note_line_items (
  id,
  credit_note_id,
  invoice_line_item_id,
  description,
  amount,
  tax_amount,
  sort_order
)
SELECT
  'e2000000-0000-4000-8000-000000000072',
  'e2000000-0000-4000-8000-000000000071',
  'e2000000-0000-4000-8000-000000000011',
  'NRC discount to apply on next invoice',
  200.00,
  36.00,
  10
WHERE EXISTS (
  SELECT 1 FROM credit_notes WHERE id = 'e2000000-0000-4000-8000-000000000071'
)
AND NOT EXISTS (
  SELECT 1 FROM credit_note_line_items WHERE id = 'e2000000-0000-4000-8000-000000000072'
);
