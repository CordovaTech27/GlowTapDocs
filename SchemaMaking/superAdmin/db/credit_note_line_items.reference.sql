CREATE TABLE credit_note_line_items (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  credit_note_id       UUID NOT NULL REFERENCES credit_notes(id) ON DELETE CASCADE,
  invoice_line_item_id UUID REFERENCES invoice_line_items(id) ON DELETE SET NULL,
  description          VARCHAR(255) NOT NULL,
  amount               DECIMAL(12, 2) NOT NULL DEFAULT 0,
  tax_amount           DECIMAL(12, 2) NOT NULL DEFAULT 0,
  sort_order           INT NOT NULL DEFAULT 0,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
