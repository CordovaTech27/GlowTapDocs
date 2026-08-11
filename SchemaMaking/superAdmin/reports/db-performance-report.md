# GlowTap Super Admin — Database Health Report

**Generated:** 29 Jul 2026, 10:25 PM IST  
**Source:** Neon Postgres · public schema · after VACUUM ANALYZE + migration 053

---

## Executive summary

| Metric | Value | Status |
|--------|------:|--------|
| Tables | 53 | OK |
| Indexes | 261 | OK |
| Foreign keys | 132 | All indexed |
| Live rows | 269 | Seeded |
| Dead tuples | **0** | Cleared |

> Dead tuples on `branches` / `organizations` / `org_bill_structure` came from migration churn. `VACUUM ANALYZE` brought them to **0**.

---

## Previously flagged tables

| Table | Rows | Dead (before) | Dead (now) | Total size | Indexes |
|-------|-----:|-------------:|----------:|-----------:|--------:|
| branches | 11 | 43 | **0** | 296 kB | 11 |
| organizations | 5 | 11 | **0** | 240 kB | 12 |
| org_bill_structure | 5 | 6 | **0** | 208 kB | 10 |

---

## Full table inventory

| Table | Rows | Dead | Total size | Index size | Index % | Index count |
|-------|-----:|-----:|-----------:|-----------:|--------:|------------:|
| branches | 11 | 0 | 296 kB | 176 kB | 59.5% | 11 |
| support_tickets | 2 | 0 | 280 kB | 232 kB | 82.9% | 15 |
| organizations | 5 | 0 | 240 kB | 184 kB | 76.7% | 12 |
| org_bill_structure | 5 | 0 | 208 kB | 160 kB | 76.9% | 10 |
| end_user_transactions | 11 | 0 | 192 kB | 144 kB | 75% | 9 |
| org_subscription_changes | 1 | 0 | 192 kB | 144 kB | 75% | 9 |
| portal_banners | 5 | 0 | 184 kB | 136 kB | 73.9% | 7 |
| cms_posts | 1 | 0 | 176 kB | 128 kB | 72.7% | 8 |
| cms_pages | 6 | 0 | 168 kB | 120 kB | 71.4% | 8 |
| invoices | 2 | 0 | 168 kB | 120 kB | 71.4% | 8 |
| merchant_ledger_entries | 13 | 0 | 168 kB | 120 kB | 71.4% | 8 |
| reviews | 3 | 0 | 160 kB | 112 kB | 70% | 7 |
| billing_discount_configs | 4 | 0 | 152 kB | 104 kB | 68.4% | 7 |
| payments | 1 | 0 | 144 kB | 96 kB | 66.7% | 6 |
| credit_notes | 2 | 0 | 136 kB | 88 kB | 64.7% | 6 |
| state_tax_configs | 15 | 0 | 136 kB | 88 kB | 64.7% | 6 |
| org_status_actions | 1 | 0 | 128 kB | 80 kB | 62.5% | 5 |
| review_moderation_actions | 2 | 0 | 128 kB | 80 kB | 62.5% | 6 |
| salon_payouts | 3 | 0 | 128 kB | 80 kB | 62.5% | 5 |
| sub_admins | 4 | 0 | 128 kB | 80 kB | 62.5% | 5 |
| user_access_actions | 1 | 0 | 128 kB | 80 kB | 62.5% | 5 |
| reason_codes | 14 | 0 | 120 kB | 72 kB | 60% | 5 |
| review_abuse_rules | 3 | 0 | 120 kB | 72 kB | 60% | 5 |
| review_reports | 1 | 0 | 120 kB | 72 kB | 60% | 5 |
| service_categories | 4 | 0 | 120 kB | 72 kB | 60% | 5 |
| service_subcategories | 6 | 0 | 120 kB | 72 kB | 60% | 5 |
| refunds | 1 | 0 | 112 kB | 64 kB | 57.1% | 4 |
| review_replies | 1 | 0 | 112 kB | 64 kB | 57.1% | 4 |
| support_ticket_categories | 7 | 0 | 112 kB | 64 kB | 57.1% | 5 |
| invoice_line_items | 2 | 0 | 104 kB | 64 kB | 61.5% | 4 |
| cms_media | 4 | 0 | 96 kB | 48 kB | 50% | 3 |
| commission_rate_history | 3 | 0 | 96 kB | 48 kB | 50% | 3 |
| support_ticket_attachments | 1 | 0 | 96 kB | 48 kB | 50% | 3 |
| support_ticket_events | 4 | 0 | 96 kB | 48 kB | 50% | 3 |
| support_ticket_internal_notes | 1 | 0 | 96 kB | 48 kB | 50% | 3 |
| support_ticket_subtypes | 9 | 0 | 96 kB | 48 kB | 50% | 3 |
| support_ticket_types | 12 | 0 | 96 kB | 48 kB | 50% | 3 |
| credit_note_line_items | 2 | 0 | 88 kB | 48 kB | 54.5% | 3 |
| invoice_payments | 1 | 0 | 88 kB | 48 kB | 54.5% | 3 |
| invoice_tax_lines | 2 | 0 | 88 kB | 48 kB | 54.5% | 3 |
| salon_payout_items | 14 | 0 | 88 kB | 48 kB | 54.5% | 3 |
| support_ticket_messages | 3 | 0 | 88 kB | 40 kB | 45.5% | 3 |
| billing_cycles | 4 | 0 | 80 kB | 32 kB | 40% | 2 |
| platform_commission_config | 1 | 0 | 80 kB | 32 kB | 40% | 2 |
| review_images | 1 | 0 | 80 kB | 32 kB | 40% | 2 |
| review_moderation_settings | 1 | 0 | 80 kB | 32 kB | 40% | 2 |
| super_admin_users | 1 | 0 | 80 kB | 32 kB | 40% | 2 |
| support_sla_policies | 4 | 0 | 80 kB | 40 kB | 50% | 3 |
| states | 36 | 0 | 72 kB | 32 kB | 44.4% | 2 |
| sub_admin_branches | 5 | 0 | 72 kB | 32 kB | 44.4% | 2 |
| subscription_plans | 4 | 0 | 64 kB | 16 kB | 25% | 1 |
| org_merchant_balances | 4 | 0 | 56 kB | 16 kB | 28.6% | 1 |
| sub_admin_modules | 15 | 0 | 56 kB | 16 kB | 28.6% | 1 |

---

## Notes

- High index % on small tables is expected (many FK indexes, little seed data).
- Refresh JSON: `node SchemaMaking/superAdmin/scripts/gen-db-report.js`
- Interactive view: open the Cursor canvas **superadmin-db-health** beside chat.
