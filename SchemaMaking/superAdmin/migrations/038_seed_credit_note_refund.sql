-- Demo credit note + refund against Looks Salon paid invoice/payment

INSERT INTO credit_notes (
  id,
  invoice_id,
  credit_note_number,
  status,
  reason,
  subtotal_amount,
  tax_amount,
  total_amount,
  issued_at,
  created_by
)
SELECT
  'e2000000-0000-4000-8000-000000000051',
  'e2000000-0000-4000-8000-000000000001',
  'GT-CN-2026-00001',
  'ISSUED',
  'Goodwill credit — 5 days downtime during platform incident.',
  423.73,
  76.27,
  500.00,
  TIMESTAMPTZ '2026-06-10 14:30:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
WHERE NOT EXISTS (
  SELECT 1 FROM credit_notes WHERE id = 'e2000000-0000-4000-8000-000000000051'
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
  'e2000000-0000-4000-8000-000000000052',
  'e2000000-0000-4000-8000-000000000051',
  'e2000000-0000-4000-8000-000000000011',
  'Goodwill credit against Growth monthly fee',
  423.73,
  76.27,
  10
WHERE EXISTS (
  SELECT 1 FROM credit_notes WHERE id = 'e2000000-0000-4000-8000-000000000051'
)
AND NOT EXISTS (
  SELECT 1 FROM credit_note_line_items WHERE id = 'e2000000-0000-4000-8000-000000000052'
);

INSERT INTO refunds (
  id,
  payment_id,
  credit_note_id,
  amount,
  status,
  gateway_refund_id,
  reason,
  refunded_at,
  created_by
)
SELECT
  'e2000000-0000-4000-8000-000000000061',
  'e2000000-0000-4000-8000-000000000031',
  'e2000000-0000-4000-8000-000000000051',
  500.00,
  'SUCCEEDED',
  'rfnd_looks_growth_20260610',
  'Gateway refund for GT-CN-2026-00001 goodwill credit.',
  TIMESTAMPTZ '2026-06-10 14:32:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
WHERE NOT EXISTS (
  SELECT 1 FROM refunds WHERE id = 'e2000000-0000-4000-8000-000000000061'
);

UPDATE payments
SET
  status = 'PARTIALLY_REFUNDED',
  updated_at = NOW()
WHERE id = 'e2000000-0000-4000-8000-000000000031'
  AND status IN ('SUCCEEDED', 'PARTIALLY_REFUNDED');
