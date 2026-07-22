-- Remove columns duplicated via foreign keys on invoice/payment tables

-- invoices.billing_state_id → org_bill_structure.state_id
ALTER TABLE invoices
  DROP COLUMN IF EXISTS billing_state_id;

-- invoice_line_items.hsn_sac_code → state_tax_configs.hsn_sac_code via invoice_tax_lines
ALTER TABLE invoice_line_items
  DROP COLUMN IF EXISTS hsn_sac_code;

-- invoice_tax_lines.invoice_id → invoice_line_items.invoice_id (require line item)
UPDATE invoice_tax_lines itl
SET invoice_line_item_id = ili.id
FROM invoice_line_items ili
WHERE itl.invoice_line_item_id IS NULL
  AND ili.invoice_id = itl.invoice_id
  AND ili.sort_order = (
    SELECT MIN(ili2.sort_order)
    FROM invoice_line_items ili2
    WHERE ili2.invoice_id = itl.invoice_id
  );

ALTER TABLE invoice_tax_lines
  ALTER COLUMN invoice_line_item_id SET NOT NULL;

ALTER TABLE invoice_tax_lines
  DROP COLUMN IF EXISTS invoice_id;

CREATE INDEX IF NOT EXISTS idx_invoice_tax_lines_line
  ON invoice_tax_lines(invoice_line_item_id);

-- credit_notes.organization_id / currency → invoices
ALTER TABLE credit_notes
  DROP COLUMN IF EXISTS organization_id,
  DROP COLUMN IF EXISTS currency;

-- refunds.organization_id / currency → payments
ALTER TABLE refunds
  DROP COLUMN IF EXISTS organization_id,
  DROP COLUMN IF EXISTS currency;

CREATE INDEX IF NOT EXISTS idx_credit_notes_invoice
  ON credit_notes(invoice_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_refunds_payment
  ON refunds(payment_id);
