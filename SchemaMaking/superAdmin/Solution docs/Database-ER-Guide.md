# GlowTap Super Admin — Database ER Guide

**Version:** 1.0  
**Date:** 29 Jul 2026  
**Audience:** Engineering / Product  
**Confidential**

---

## 1. Purpose

This document describes the **Neon Postgres** schema used by the GlowTap **Super Admin** platform: entities, relationships (ER), and how each domain works in practice.

The schema is organized into **domains**. Each section has:

1. A short explanation  
2. An **ER diagram** (Mermaid)  
3. Table roles  

> Soft references such as `booking_ref` / `end_user_ref` are intentional until Booking and End-User modules exist as first-class tables.

---

## 2. Domain map (high level)

```mermaid
flowchart LR
  CORE[Org & Branch]
  BILL[Billing & Invoices]
  MKT[Marketplace / Commission]
  ACCESS[User Access]
  CMS[CMS & Banners]
  REV[Reviews]
  TKT[Support Tickets]
  CAT[Service Catalog]

  CORE --> BILL
  CORE --> MKT
  CORE --> ACCESS
  CORE --> REV
  CORE --> TKT
  BILL --> MKT
  CAT -.->|later: salon products| CORE
  CMS -.->|portal banners use org context| BILL
```

| Domain | Tables (approx.) | Purpose |
|--------|------------------|---------|
| Core | organizations, branches, states, super_admin_users | Hierarchy & platform operators |
| Billing | plans, cycles, org_bill_structure, invoices, payments… | SaaS subscription money |
| Marketplace | end_user_transactions, ledger, payouts… | B2C GMV, commission, salon payout |
| Access | sub_admins, modules, branches access | Salon Admin / Sub Admin |
| CMS | cms_*, portal_banners | Website + salon portal promos |
| Reviews | reviews, moderation_* | Ratings moderation |
| Support | support_* | Tickets from salon + customer |
| Catalog | service_categories / subcategories | Platform taxonomy |

**53 tables · 132 foreign keys · 261 indexes** (as of migration 053).

---

## 3. Core — Organization & Branch

### Explanation

GlowTap is **Organization → Branch**.  
An **organization** is the salon business; a **branch** is a physical outlet. Super Admin users approve orgs/branches and manage platform config.

`organizations.owner_*` doubles as the **Salon Admin** profile (no separate main-admin table). Portal login gate uses `owner_portal_status`.

### ER diagram

```mermaid
erDiagram
  super_admin_users ||--o{ organizations : "approves / disables"
  states ||--o{ organizations : "HQ state"
  states ||--o{ branches : "branch state"
  organizations ||--|{ branches : "has"
  reason_codes ||--o{ organizations : "status reason"

  super_admin_users {
    uuid id PK
    varchar email
    varchar role
  }
  states {
    uuid id PK
    varchar code
    varchar name
  }
  organizations {
    uuid id PK
    varchar name
    varchar owner_email
    varchar status
    varchar owner_portal_status
    uuid state_id FK
  }
  branches {
    uuid id PK
    uuid organization_id FK
    varchar name
    varchar status
    boolean is_primary
  }
  reason_codes {
    uuid id PK
    varchar category
    varchar code
  }
```

### Table notes

| Table | Explanation |
|-------|-------------|
| `super_admin_users` | GlowTap ops accounts (SUPER_ADMIN, READ_ONLY, OPS_AGENT) |
| `states` | India state master for GST / tax |
| `organizations` | Salon business entity + owner (Salon Admin) fields |
| `branches` | Outlets; one primary per org; PENDING until approved |
| `reason_codes` | Suspend / Resume / Terminate reasons (org lifecycle) |

---

## 4. Billing & subscriptions

### Explanation

Catalog masters define **plans** and **billing cycles**. Each org has an **`org_bill_structure`** row (current commercial terms).  
**Invoices / payments / credit notes / refunds** are the money ledger for SaaS fees (and `COMMISSION` invoices for marketplace cash settlement).

### ER diagram

```mermaid
erDiagram
  subscription_plans ||--o{ org_bill_structure : "current plan"
  billing_cycles ||--o{ org_bill_structure : "current cycle"
  organizations ||--|| org_bill_structure : "has terms"
  organizations ||--o{ invoices : "billed"
  invoices ||--o{ invoice_line_items : "lines"
  invoices ||--o{ invoice_tax_lines : "GST lines"
  state_tax_configs ||--o{ invoice_tax_lines : "rate"
  invoices ||--o{ invoice_payments : "allocated"
  payments ||--o{ invoice_payments : "pays"
  invoices ||--o{ credit_notes : "adjusted"
  credit_notes ||--o{ credit_note_line_items : "lines"
  payments ||--o{ refunds : "refunded"
  credit_notes ||--o{ refunds : "optional link"
  org_bill_structure ||--o{ org_subscription_changes : "history"
  subscription_plans ||--o{ billing_discount_configs : "discounts"

  subscription_plans {
    uuid id PK
    varchar name
    int max_branches
    numeric amount
  }
  billing_cycles {
    uuid id PK
    varchar code
    int interval_months
  }
  org_bill_structure {
    uuid id PK
    uuid organization_id FK
    uuid subscription_plan_id FK
    uuid billing_cycle_id FK
    date renewal_date
  }
  invoices {
    uuid id PK
    uuid organization_id FK
    varchar invoice_type
    varchar status
    numeric total_amount
  }
  payments {
    uuid id PK
    numeric amount
    varchar status
  }
```

### Table notes

| Table | Explanation |
|-------|-------------|
| `subscription_plans` | Starter / Growth / Professional / Enterprise |
| `billing_cycles` | Monthly, Quarterly, Half-yearly, Yearly |
| `org_bill_structure` | Live commercial terms per org |
| `billing_discount_configs` | Plan × cycle discount rules |
| `org_subscription_changes` | Upgrade / downgrade audit |
| `state_tax_configs` | GST rates by state |
| `invoices` + lines + tax lines | Invoice documents |
| `payments` + `invoice_payments` | Cash in + allocation |
| `credit_notes` + lines + `refunds` | Adjustments / refunds |

---

## 5. Marketplace — B2C commission & payouts

### Explanation

Tracks **customer → salon** money flows:

- **Cash / pay-at-salon** → commission accrues to **outstanding**  
- **Online marketplace** → GlowTap collects; deducts commission, gateway fee, recovers outstanding; nets to salon via **payout**

Snapshot balances live on `org_merchant_balances`; history on `merchant_ledger_entries` (`OUTSTANDING` / `PAYABLE` buckets).

### ER diagram

```mermaid
erDiagram
  organizations ||--|| org_merchant_balances : "snapshot"
  organizations ||--o{ end_user_transactions : "GMV"
  branches ||--o{ end_user_transactions : "at branch"
  organizations ||--o{ salon_payouts : "EOD payouts"
  salon_payouts ||--o{ salon_payout_items : "breakdown"
  end_user_transactions ||--o{ salon_payout_items : "included"
  salon_payouts ||--o{ end_user_transactions : "paid_out_batch"
  organizations ||--o{ merchant_ledger_entries : "wallet log"
  end_user_transactions ||--o{ merchant_ledger_entries : "from txn"
  salon_payouts ||--o{ merchant_ledger_entries : "from payout"
  invoices ||--o{ merchant_ledger_entries : "commission invoice"
  platform_commission_config ||--o{ organizations : "defaults"
  organizations ||--o{ commission_rate_history : "rate audit"

  end_user_transactions {
    uuid id PK
    uuid organization_id FK
    varchar payment_channel
    numeric commission_amount
    numeric outstanding_recovered
    uuid salon_payout_id FK
  }
  org_merchant_balances {
    uuid organization_id PK
    numeric outstanding_amount
    numeric pending_payout_amount
  }
  merchant_ledger_entries {
    uuid id PK
    varchar balance_bucket
    varchar entry_type
    numeric balance_after
  }
  salon_payouts {
    uuid id PK
    varchar payout_number
    numeric net_payout_amount
    varchar status
  }
```

### Table notes

| Table | Explanation |
|-------|-------------|
| `platform_commission_config` | Default %, invoice day, ₹5k threshold |
| `commission_rate_history` | Per-org rate changes |
| `end_user_transactions` | Each B2C booking payment |
| `org_merchant_balances` | Current outstanding + pending payout |
| `merchant_ledger_entries` | Append-only movements |
| `salon_payouts` / `salon_payout_items` | EOD transfer batch + lines |

**Outstanding** = salon owes GlowTap (cash commission).  
**Payable** = GlowTap owes salon (online net after recoveries).

---

## 6. User Access Control

### Explanation

- **Salon Admin** = org owner fields (`owner_*` + portal status)  
- **Sub Admins** = delegated users under an org with **branch** + **module** grants  
- Super Admin can disable; reasons go to `user_access_actions`

### ER diagram

```mermaid
erDiagram
  organizations ||--o{ sub_admins : "employs"
  sub_admins ||--o{ sub_admin_branches : "access"
  branches ||--o{ sub_admin_branches : "granted"
  sub_admins ||--o{ sub_admin_modules : "modules"
  organizations ||--o{ user_access_actions : "audit"
  sub_admins ||--o{ user_access_actions : "target"
  super_admin_users ||--o{ user_access_actions : "performed"

  sub_admins {
    uuid id PK
    uuid organization_id FK
    varchar email
    varchar status
  }
  sub_admin_branches {
    uuid sub_admin_id FK
    uuid branch_id FK
  }
  sub_admin_modules {
    uuid sub_admin_id FK
    varchar module
  }
  user_access_actions {
    uuid id PK
    varchar target_type
    varchar action
    text reason
  }
```

### Modules (examples)

`BRANCH_PROFILE`, `EMPLOYEES`, `LEAVE_HOLIDAYS`, `ATTENDANCE`, `SERVICES`, `APPOINTMENTS`, `TRANSACTIONS`, `REPORTS`

---

## 7. CMS & Salon portal banners

### Explanation

**CMS** powers the public website (pages, blog, media).  
**Portal banners** are promotional cards inside the **Salon Admin** app. Targeting is JSONB evaluated at runtime against org plan / expiry / branch limits (not stored per org).

### ER diagram

```mermaid
erDiagram
  cms_media ||--o{ cms_pages : "og image"
  cms_media ||--o{ cms_posts : "cover"
  cms_media ||--o{ portal_banners : "creative"
  super_admin_users ||--o{ cms_media : "uploads"
  super_admin_users ||--o{ cms_pages : "edits"
  super_admin_users ||--o{ portal_banners : "configures"

  cms_media {
    uuid id PK
    text storage_url
    varchar media_type
  }
  cms_pages {
    uuid id PK
    varchar slug
    varchar status
    varchar preview_token
  }
  cms_posts {
    uuid id PK
    varchar slug
    varchar status
  }
  portal_banners {
    uuid id PK
    jsonb targeting_rules
    int display_priority
    boolean is_active
  }
```

### Notes

- Publish workflow: `DRAFT` → `SCHEDULED` → `PUBLISHED`  
- `preview_token` unlocks unpublished preview URLs  
- Banner rules example: `{ "all": [ { "field": "days_to_expiry", "op": "lte", "value": 30 } ] }`

---

## 8. Reviews & ratings moderation

### Explanation

Consumers submit reviews after completed bookings (soft `booking_ref`).  
Super Admin configures **settings** + **abuse rules** (no ML), then moderates via queue / reports. Audit actions include `AUTO_APPROVE` vs human `APPROVE`.

### ER diagram

```mermaid
erDiagram
  organizations ||--o{ reviews : "about org"
  branches ||--o{ reviews : "about branch"
  reviews ||--o{ review_images : "photos"
  reviews ||--o| review_replies : "salon reply"
  reviews ||--o{ review_reports : "flags"
  reviews ||--o{ review_moderation_actions : "audit"
  review_moderation_settings ||--o{ reviews : "policy"
  review_abuse_rules ||--o{ reviews : "matched codes"

  reviews {
    uuid id PK
    int overall_rating
    varchar status
    varchar booking_ref
  }
  review_images {
    uuid id PK
    bigint file_size_bytes
    varchar status
  }
  review_replies {
    uuid id PK
    text body
    varchar status
  }
  review_reports {
    uuid id PK
    varchar reason_code
    varchar status
  }
  review_moderation_actions {
    uuid id PK
    varchar action
    text reason
  }
```

### Status flow

`PENDING` (queued) → `PUBLISHED` | `HIDDEN` | `REJECTED`  
Public apps show only `PUBLISHED` (+ `ACTIVE` images).

---

## 9. Support & ticketing

### Explanation

SaaS helpdesk (Freshdesk-style). Tickets from **SALON** or **END_USER** (also SUPER_ADMIN / SYSTEM).  
**CTS** = Category → Type → Subtype (audience-filtered).  
**SLA** policies set first-response / resolve timers by priority.

### ER diagram

```mermaid
erDiagram
  support_ticket_categories ||--|{ support_ticket_types : "has"
  support_ticket_types ||--|{ support_ticket_subtypes : "has"
  support_sla_policies ||--o{ support_tickets : "timers"
  support_ticket_categories ||--o{ support_tickets : "C"
  support_ticket_types ||--o{ support_tickets : "T"
  support_ticket_subtypes ||--o{ support_tickets : "S"
  organizations ||--o{ support_tickets : "salon context"
  support_tickets ||--o{ support_ticket_messages : "public thread"
  support_tickets ||--o{ support_ticket_internal_notes : "ops only"
  support_tickets ||--o{ support_ticket_attachments : "files"
  support_tickets ||--o{ support_ticket_events : "workflow"
  super_admin_users ||--o{ support_tickets : "assignee"

  support_tickets {
    uuid id PK
    varchar ticket_number
    varchar source
    varchar priority
    varchar status
  }
  support_ticket_messages {
    uuid id PK
    varchar author_type
    text body
  }
  support_ticket_events {
    uuid id PK
    varchar event_type
    varchar from_value
    varchar to_value
  }
```

### Workflow

```
CREATED → IN_PROGRESS → ON_HOLD → AWAITING_USER → RESOLVED → CLOSED
                              ↑________________ REOPENED ______|
```

Messages support unlimited agent ↔ requester back-and-forth; events track status/assign history.

---

## 10. Service catalog taxonomy

### Explanation

Super Admin maintains a **2-level platform tree**: Category → Subcategory.  
Salon product names (e.g. “Baba Hair Cut”) come later under a subcategory.

**Single-level services:** category name = subcategory name, **different IDs** (`is_single_level` / `mirrors_category`).

### ER diagram

```mermaid
erDiagram
  service_categories ||--|{ service_subcategories : "contains"
  super_admin_users ||--o{ service_categories : "manages"

  service_categories {
    uuid id PK
    varchar code
    varchar name
    boolean is_single_level
  }
  service_subcategories {
    uuid id PK
    uuid category_id FK
    varchar code
    varchar name
    boolean mirrors_category
  }
```

### Examples

| Category | Subcategories |
|----------|----------------|
| Hair Cut | Men's, Women's |
| Spa | Spa *(mirrored single-level)* |

---

## 11. Org lifecycle helpers

```mermaid
erDiagram
  organizations ||--o{ org_status_actions : "suspend/resume/terminate"
  reason_codes ||--o{ org_status_actions : "reason"
  super_admin_users ||--o{ org_status_actions : "performed"

  org_status_actions {
    uuid id PK
    varchar action
    text notes
  }
```

---

## 12. Cross-cutting conventions

| Convention | Detail |
|------------|--------|
| PKs | UUID `gen_random_uuid()` |
| Timestamps | `timestamptz` (`created_at` / `updated_at`) |
| Money | `numeric(12,2)`, currency INR |
| Soft refs | `booking_ref`, `end_user_ref`, `specialist_ref` until modules land |
| Audit reasons | Prefer action/log tables (`user_access_actions`, `review_moderation_actions`) over denormalized reason columns |
| Indexes | All FKs indexed (migration 040 + 053) |
| RLS | Neon Data API policies on application tables |

---

## 13. How to read these diagrams

In Mermaid ER notation (Crow’s foot style):

- **One-to-many (often mandatory children)** — double bar to crow’s foot: `one ||--|{ many`
- **One-to-many optional** — double bar to open crow’s foot: `one ||--o{ many`
- **One-to-one** — double bar both sides: `a ||--|| b`
- **One-to-zero-or-one** — double bar to open single: `a ||--o| b`

`||` = exactly one · `|` / `{` = many · `o` = optional (zero allowed)

---

## 14. Related artifacts

| Artifact | Path |
|----------|------|
| Drizzle schema | `SchemaMaking/superAdmin/db/schema.ts` |
| Migrations | `SchemaMaking/superAdmin/migrations/` |
| Org structure notes | `SchemaMaking/superAdmin/Solution docs/Organization-structure.md` |
| DB health PDF | `SchemaMaking/superAdmin/reports/GlowTap-SuperAdmin-DB-Health-Report.pdf` |

---

*Confidential — GlowTap Internal*
