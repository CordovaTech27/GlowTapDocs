CREATE TABLE rms.invoice_tax_lines (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_line_item_id UUID NOT NULL REFERENCES invoice_line_items(id) ON DELETE CASCADE,
  state_tax_config_id  UUID NOT NULL REFERENCES state_tax_configs(id),
  taxable_amount       DECIMAL(12, 2) NOT NULL,
  tax_amount           DECIMAL(12, 2) NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
