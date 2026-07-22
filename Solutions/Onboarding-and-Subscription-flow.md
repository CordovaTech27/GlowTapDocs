# GlowTap — Salon Onboarding & Subscription Flow

**Version:** 1.1  
**Date:** July 14, 2026  
**Audience:** Product, engineering, operations, Super Admin  
**Purpose:** Define how a salon registers, completes KYC, gets approved, receives optional free usage, and purchases a subscription (with discounts and GST).  
**Related:** `SchemaMaking/superAdmin/Solution docs/Organization-structure.md`

---

## 1. Overview

Salon owners (Salon Admins) join GlowTap either from the marketing landing page or via an advertisement deep-link into the registration form. They submit **organization** details, **primary branch** details, KYC documents, and images. Super Admin reviews and approves (optionally granting free usage). After that, the admin either uses the free period or must select a subscription and pay (with plan × cycle discounts and GST) before continued full access.

```
Landing / Ad → Register form
  → Org + Primary branch + KYC docs + images
  → PENDING review
  → Super Admin Approve / Reject
       ├─ Free usage enabled → renewal postponed; use until renewal + grace
       └─ No free usage → 1st login forces subscription + payment
  → Subscription picker (best-value ranked) + discounts + GST
  → Active paid org
```

---

## 2. Entry points

| Source | Behaviour |
|--------|-----------|
| Landing page → **Register** | Opens full registration form |
| Advertisement / campaign link | Deep-links **directly** to the same form (UTM stored in `campaign_attribution`) |

Both paths use the same form and same submission rules.

---

## 3. Registration form — data captured

### 3.1 Organization

Mapped to `organizations` (and later `org_bill_structure` at approval / purchase).

| Form area | DB fields (primary) |
|-----------|---------------------|
| Brand / legal | `name`, `slug`, `legal_name` |
| Owner contact | `owner_name`, `owner_email`, `owner_phone` |
| Tax identity | `gst_number`, `pan_number`, `gst_registration_type`, `business_type`, `cin`, `udyam_msme_number` |
| Address | `registered_address` (JSONB: city, pincode, country, …), `state_id` → `states` |
| Campaign | `campaign_attribution` (JSONB UTM / ad params from landing or ad link) |
| Documents / media | `kyc_document_url`, `gst_certificate_url`, `photo_url`, `logo_url` |
| Status at submit | `status = PENDING`, `kyc_status = PENDING` |

Display state name via join `states`. **Billing GST state** may also be set on `org_bill_structure.state_id` (often copied from org `state_id` at approval).

### 3.2 Primary branch

Mapped to `branches` with `is_primary = TRUE`.

| Form area | DB fields (primary) |
|-----------|---------------------|
| Identity | `name`, `slug`, `organization_id` |
| Location | `address` (JSONB), `state_id` → `states`, lat/long |
| Contact / ops | `contact_phone`, `contact_email`, `operating_hours` |
| GST at outlet | `branch_gst_number` (if separate) |
| Licenses | `shop_establishment_license_number` / `_url`, `trade_license_number` / `_url` |
| Docs / media | `kyc_document_url`, `gst_certificate_url`, `photo_url` |
| Status at submit | `status = PENDING`, `kyc_status = PENDING`, `is_primary = TRUE` |

### 3.3 Documents checklist (aligned with DB)

| Document | Typical field |
|----------|----------------|
| Owner / business KYC ID | `organizations.kyc_document_url` |
| GST certificate (org) | `organizations.gst_certificate_url` |
| Org photo / cover | `organizations.photo_url` |
| Logo | `organizations.logo_url` |
| Branch storefront photo | `branches.photo_url` |
| Branch KYC / shop papers | `branches.kyc_document_url` |
| Branch GST certificate | `branches.gst_certificate_url` |
| Shop & Establishment (number + PDF) | `shop_establishment_license_number`, `shop_establishment_license_url` |
| Trade license (number + PDF) | `trade_license_number`, `trade_license_url` |

Files are stored in **S3**; DB holds URLs only.

### 3.4 Salon Admin account

On submit (or on approve — product choice):

- Create / invite Salon Admin login (email = `owner_email` or dedicated auth user).
- Link auth user to `organization_id`.
- Credentials / magic link delivered after successful registration or after approval (confirm in implementation).

---

## 4. Post-submit states

| Entity | After submit |
|--------|----------------|
| Organization | `PENDING` |
| Primary branch | `PENDING`, `is_primary = TRUE` |
| KYC (org & branch) | `PENDING` |
| Platform access | Restricted / wait screen (“Under review”) — no full Salon Admin |

**Reject path (required):** Super Admin rejects with reason → notify owner → allow resubmit / edit docs → status back to `PENDING`.

---

## 5. Super Admin approval

### 5.1 Review

Super Admin verifies:

- Org identity (PAN, GST, MSME, CIN as applicable)
- Primary branch licenses and photos
- KYC documents and consistency with addresses / state

Actions:

| Action | Effect |
|--------|--------|
| **Approve KYC** | `kyc_status = VERIFIED`, audit `kyc_verified_at` / `kyc_verified_by` |
| **Approve org / branch** | `status = ACTIVE` (or org ACTIVE with billing gate — see below) |
| **Reject** | `REJECTED` / KYC `REJECTED` + reason |

### 5.2 Optional free usage

At approval, Super Admin may **enable free usage** (e.g. 1 free month).

| Field | Update |
|-------|--------|
| `org_bill_structure.free_usage_days` | Add days granted (e.g. `+= 30` or `+= months × 30`) |
| `org_bill_structure.start_date` | Approval / onboarding date |
| `org_bill_structure.renewal_date` | Postponed by free period |
| `org_bill_structure.status` | `ACTIVE` (trial) |

**Rule (recommended):** Free period is counted in **days** via `free_usage_days` (default grant = 30 for “one free month”). Product may later support N months → `free_usage_days += N * 30`.

```
renewal_date = start_date + free_usage_days
```

Until `renewal_date`, Salon Admin can use the platform **without** selecting a paid subscription (if free was granted).

### 5.3 No free usage

- Create `org_bill_structure` shell or leave incomplete until payment.
- On **first Salon Admin login**, force **subscription selection + payment** before full access (billing gate).

---

## 6. Renewal, grace, and restriction

```
… usage …
    → renewal_date
    → grace_period_days (default 7)
    → if not renewed / unpaid → restrict platform
```

| Period | Access |
|--------|--------|
| Before `renewal_date` | Full (if ACTIVE / paid or in free period) |
| Between `renewal_date` and `renewal_date + grace_period_days` | Still allowed; show paywall / reminders |
| After grace ends without payment | Restricted (`org_bill_structure.status = SUSPENDED` or org gated) |

Restriction behaviour (product default):

- Block new bookings / POS / admin mutating actions
- Optional read-only history
- Clear CTA: renew subscription

`auto_renew` on `org_bill_structure` drives reminder / NACH retry flows (payment objects in a later doc).

---

## 7. Subscription purchase (first paid or renew)

### 7.1 Catalog

- Plans: `subscription_plans` (`name`, `max_branches`, **`amount`** list price)
- Cycles: `billing_cycles` (`MONTHLY`, `QUARTERLY`, `HALF_YEARLY`, `YEARLY`, `interval_months`)

### 7.2 Discount configuration

Table: `billing_discount_configs`

| Rule | Detail |
|------|--------|
| Unique | `(subscription_plan_id, billing_cycle_id)` unique (`NULLS NOT DISTINCT`) |
| Types | `PERCENTAGE` or `FIXED_AMOUNT` |
| Scope | Specific plan and/or cycle; `NULL` plan = all plans for that cycle |
| Stack | Only if **both** matching rows have `is_stackable = TRUE` |
| Priority | Used when overlapping matches (e.g. Growth+Yearly vs all-plans+Yearly); lower number wins |

### 7.3 UI: showcase benefits & best suggestion

1. Build all **plan × cycle** options (active plans × active cycles).
2. For each option, resolve discount(s) from `billing_discount_configs`.
3. Compute:

```
list_price     = subscription_plans.amount   (or multiplied by cycle policy if list is monthly — confirm catalog convention)
discount_amt   = from PERCENTAGE and/or FIXED_AMOUNT
net_before_tax = list_price - discount_amt
effective_monthly = net_before_tax / billing_cycles.interval_months
```

4. Sort by **lowest `effective_monthly`** (best value) → show **Best value** badge on top.
5. On selection, show explicit copy, e.g.:

> Based on **Growth + Yearly**, you get **₹500 off** (Growth Yearly offer).  
> List ₹2,499 → after discount ₹1,999.

Always explain **which** discount config(s) applied.

### 7.4 GST on platform fee (GlowTap → salon)

This is GST on the **SaaS / platform subscription**, not on salon beauty services to end customers.

| Input | Source |
|-------|--------|
| Taxable value | `net_before_tax` (after discounts) |
| Billing state | `org_bill_structure.state_id` → `states` |
| Rates | `state_tax_configs` for that `state_id` |

```
if GlowTap GST state == org billing state:
  apply CGST + SGST components
else:
  apply IGST component
invoice_total = taxable + GST
```

Checkout must show line-level GST (CGST/SGST or IGST).

Persist after successful payment on `org_bill_structure`:

- `subscription_plan_id`, `billing_cycle_id`, `state_id`
- `platform_fee_amount` = net before tax (or gross — pick one convention and stick to it)
- `start_date` / `renewal_date` (next period from cycle `interval_months`)
- `payment_method`, `last_payment_at`, `payment_reference`
- `status = ACTIVE`
- `commission_pct` (default or Super Admin override at approve)

### 7.5 Example checkout summary

```
Plan: Growth | Billing: Yearly
List price:           ₹2,499.00
Discount (₹500 off): −₹500.00
Taxable:              ₹1,999.00
CGST 9%:              ₹179.91
SGST 9%:              ₹179.91
Payable:              ₹2,358.82
```

(Inter-state: single IGST line instead of CGST+SGST.)

---

## 8. End-to-end flow

<div class="onboard-flow" aria-label="Onboarding flowchart">

<div class="of-phase of-entry">
  <div class="of-label">1 · Entry</div>
  <div class="of-row">
    <div class="of-box">Landing → Register</div>
    <div class="of-or">or</div>
    <div class="of-box">Ad / campaign link</div>
  </div>
  <div class="of-arrow">▼</div>
  <div class="of-box of-wide">Registration form</div>
</div>

<div class="of-connector">▼</div>

<div class="of-phase of-register">
  <div class="of-label">2 · Registration</div>
  <div class="of-steps">
    <span class="of-pill">Org details + docs</span>
    <span class="of-pipe">→</span>
    <span class="of-pill">Primary branch + licenses</span>
    <span class="of-pipe">→</span>
    <span class="of-pill">KYC + images</span>
    <span class="of-pipe">→</span>
    <span class="of-pill">Submit</span>
  </div>
  <div class="of-arrow">▼</div>
  <div class="of-box of-wide of-pending">Status: PENDING — Under review</div>
</div>

<div class="of-connector">▼</div>

<div class="of-phase of-review">
  <div class="of-label">3 · Super Admin review</div>
  <div class="of-decision">Approve or reject?</div>
  <div class="of-branches">
    <div class="of-branch">
      <div class="of-tag of-tag-no">Reject + reason</div>
      <div class="of-box">Notify owner → resubmit form</div>
    </div>
    <div class="of-branch">
      <div class="of-tag of-tag-yes">Approve</div>
      <div class="of-decision">Grant free usage?</div>
    </div>
  </div>
</div>

<div class="of-connector">▼</div>

<div class="of-phase of-access">
  <div class="of-label">4 · Access path</div>
  <div class="of-branches">
    <div class="of-branch">
      <div class="of-tag of-tag-yes">Free = Yes</div>
      <div class="of-box">Set free_usage_days<br/>Postpone renewal_date</div>
      <div class="of-arrow">▼</div>
      <div class="of-box of-ok">Full platform access</div>
    </div>
    <div class="of-branch">
      <div class="of-tag of-tag-no">Free = No</div>
      <div class="of-box">Billing gate<br/>First login</div>
      <div class="of-arrow">▼</div>
      <div class="of-box">Go to subscription picker →</div>
    </div>
  </div>
  <div class="of-note">During access: if past <strong>renewal + grace</strong> unpaid → Restricted → must renew</div>
</div>

<div class="of-connector">▼</div>

<div class="of-phase of-billing">
  <div class="of-label">5 · Subscription &amp; payment</div>
  <div class="of-steps of-wrap">
    <span class="of-pill">Plan × cycle<br/><em>Best value on top</em></span>
    <span class="of-pipe">→</span>
    <span class="of-pill">Show discounts</span>
    <span class="of-pipe">→</span>
    <span class="of-pill">GST (billing state)</span>
    <span class="of-pipe">→</span>
    <span class="of-pill">Payment</span>
    <span class="of-pipe">→</span>
    <span class="of-pill of-ok">Paid ACTIVE<br/>Next renewal_date</span>
  </div>
</div>

</div>

### Flow summary (phases)

| Phase | What happens |
|-------|----------------|
| **1 · Entry** | Landing Register **or** ad deep-link → same form |
| **2 · Registration** | Org + primary branch + KYC → `PENDING` |
| **3 · Review** | Super Admin approve (optional free days) or reject → resubmit |
| **4 · Access** | Free trial access **or** billing gate on first login |
| **5 · Billing** | Pick plan/cycle → discounts → GST → pay → renew / grace / lock |
---

## 9. Roles

| Role | Responsibility |
|------|----------------|
| Prospect / Salon Admin | Submit onboarding form; pick plan; pay |
| Super Admin | KYC review; approve/reject; grant free usage; set commission |
| System | Apply discounts, GST, renewals, grace lock |

---

## 10. Open / future items

| Item | Notes |
|------|--------|
| Salon Admin auth schema | User ↔ org mapping |
| Payment / invoice tables | Gateway refs, GST invoice number, PDF URL |
| GlowTap GSTIN home state | Required for CGST+SGST vs IGST |
| Email / SMS templates | Submitted, rejected, approved, renewal, grace |

---

## 11. Schema references

| Concern | Tables |
|---------|--------|
| Org / branch / KYC docs | `organizations`, `branches` |
| Billing terms | `org_bill_structure` (`free_usage_days`, `grace_period_days`, `renewal_date`, `state_id`, …) |
| Plans & price | `subscription_plans.amount` |
| Cycles | `billing_cycles` |
| Discounts | `billing_discount_configs` |
| States & tax | `states`, `state_tax_configs` |

Full column detail: **Organization Structure** solution doc under `SchemaMaking/superAdmin/Solution docs/`.

---

*Confidential — GlowTap Internal*
