-- Performance: covering indexes on hot FK / join / filter columns

-- Billing ledger
CREATE INDEX IF NOT EXISTS idx_refunds_credit_note
  ON refunds(credit_note_id)
  WHERE credit_note_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_invoice_tax_lines_tax_config
  ON invoice_tax_lines(state_tax_config_id);

CREATE INDEX IF NOT EXISTS idx_credit_note_line_items_invoice_line
  ON credit_note_line_items(invoice_line_item_id)
  WHERE invoice_line_item_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_invoice_line_items_plan
  ON invoice_line_items(subscription_plan_id)
  WHERE subscription_plan_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_invoice_line_items_cycle
  ON invoice_line_items(billing_cycle_id)
  WHERE billing_cycle_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_invoices_subscription_change
  ON invoices(org_subscription_change_id)
  WHERE org_subscription_change_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_invoices_issue_date
  ON invoices(issue_date DESC);

-- Org lifecycle / subscription history joins
CREATE INDEX IF NOT EXISTS idx_org_status_actions_reason
  ON org_status_actions(reason_code_id)
  WHERE reason_code_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_subscription_changes_from_plan
  ON org_subscription_changes(from_subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_org_subscription_changes_to_plan
  ON org_subscription_changes(to_subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_org_bill_structure_plan
  ON org_bill_structure(subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_org_bill_structure_cycle
  ON org_bill_structure(billing_cycle_id);

-- Org list filters (Super Admin "All Salons")
CREATE INDEX IF NOT EXISTS idx_organizations_status
  ON organizations(status);

CREATE INDEX IF NOT EXISTS idx_organizations_status_changed_at
  ON organizations(status_changed_at DESC NULLS LAST)
  WHERE status_changed_at IS NOT NULL;

-- Refresh planner stats after seed + schema churn
ANALYZE billing_cycles;
ANALYZE billing_discount_configs;
ANALYZE branches;
ANALYZE credit_note_line_items;
ANALYZE credit_notes;
ANALYZE invoice_line_items;
ANALYZE invoice_payments;
ANALYZE invoice_tax_lines;
ANALYZE invoices;
ANALYZE org_bill_structure;
ANALYZE org_status_actions;
ANALYZE org_subscription_changes;
ANALYZE organizations;
ANALYZE payments;
ANALYZE reason_codes;
ANALYZE refunds;
ANALYZE state_tax_configs;
ANALYZE states;
ANALYZE subscription_plans;
ANALYZE super_admin_users;
