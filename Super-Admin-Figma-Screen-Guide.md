# GlowTap Super Admin Portal
## Figma Screen Inventory & Step-by-Step Design Guide

**Version:** 1.4  
**Date:** June 27, 2026  
**Purpose:** Screens to design in Figma for Super Admin — **only what is defined in the Functional Specification v1.1**.

**Source:** Super-Admin-Functional-Spec.md v1.1

---

## 1. Screen Count Summary

**Counting rules:**
- **Page** = navigable screen defined in the functional spec
- **Modal** = overlay for an action defined in the functional spec (not a page)
- **Layout** = app shell (design once, **not a page**)
- **Component** = reusable pattern (empty state, confirm dialog) — not counted as pages

| Category | Pages | Modals | Layout | Figma Frames | Complexity |
|----------|------:|-------:|-------:|-------------:|------------|
| Auth | 1 | 0 | 0 | 1 | Low |
| App Shell | — | — | 1 | 1 | Low |
| Dashboard | 1 | 0 | 0 | 1 | Medium |
| Salon Approvals | 2 | 3 | 0 | 5 | Medium |
| Branch Approvals | 2 | 2 | 0 | 4 | Medium |
| All Salons | 2 | 6 | 0 | 8 | High |
| Transactions | 2 | 1 | 0 | 3 | Low |
| Subscription Management | 5 | 0 | 0 | 5 | Medium |
| Reports | 3 | 2 | 0 | 5 | Medium |
| User Access Control | 6 | 2 | 0 | 8 | Medium |
| **CMS & Banners** | **7** | **0** | **0** | **7** | **High** |
| Platform Analytics | 1 | 0 | 0 | 1 | High |
| Support & Ticketing | 2 | 1 | 0 | 3 | Medium |
| **Master Configuration** | **7** | **0** | **0** | **7** | **High** |
| Audit Log | 1 | 0 | 0 | 1 | Low |
| **TOTAL (in scope)** | **42** | **17** | **1** | **~60** | |

**Summary:**
- **42 pages** (functional spec only)
- **17 modals**
- **1 app shell** (layout — not a page)
- **~60 Figma frames**

---

## 2. Excluded — Not in Functional Spec v1.1

Do **not** design these unless added to a future functional spec version:

| Removed ID | Was | Why excluded |
|------------|-----|--------------|
| AUTH-02 | MFA Verification page | Spec only says "optional MFA" — no TOTP/backup flow defined |
| AUTH-03 | Forgot Password | Not mentioned in functional spec |
| AUTH-04 | Reset Password | Not mentioned in functional spec |
| BNR-03 | Banner Preview (separate page) | No separate banner preview screen; use preview on BNR-02 edit |
| GLB-02 | Error / 404 page | Not in functional spec |
| GLB-M01 | Generic Confirm Dialog | Reusable component only — not a separate deliverable |

---

## 3. Complexity Legend

| Level | Meaning |
|-------|---------|
| **Low** | List or simple form |
| **Medium** | Filters, tabs, tables, multi-step actions |
| **High** | Rich editors, rule builders, matrices, many conditional states |

---

## 4. Complete Screen Inventory (Functional Spec Only)

### 4.1 Auth (1 page) + App Shell (1 layout)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| AUTH-01 | Login | Page | §2 — email/password login |
| SHELL-01 | App Shell | Layout | §3 — 13 menu items + header |

> MFA, forgot password, and reset password are **not** in scope until added to functional spec.

---

### 4.2 Dashboard (1 page)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| DASH-01 | Dashboard Home | Page | §4.1 — pending actions, KPIs, alerts, quick actions |

---

### 4.3 Salon Approvals (2 pages + 3 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| SAL-01 | Salon Lead List | Page | §4.2 — filters, status |
| SAL-02 | Salon Lead Review | Page | §4.2 — review details, commission %, KYC docs |
| SAL-M01 | Approve Lead Modal | Modal | §4.2 — Approve + commission |
| SAL-M02 | Reject Lead Modal | Modal | §4.2 — Reject + reason |
| SAL-M03 | Request More Info Modal | Modal | §4.2 — Awaiting Documents |

---

### 4.4 Branch Approvals (2 pages + 2 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| BRN-01 | Branch Request List | Page | §4.3 |
| BRN-02 | Branch Request Review | Page | §4.3 — upgrade required state |
| BRN-M01 | Approve Branch Modal | Modal | §4.3 — Approve |
| BRN-M02 | Reject Branch Modal | Modal | §4.3 — Reject + reason |

---

### 4.5 All Salons (2 pages + 6 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| ORG-01 | All Salons List | Page | §4.4 — list view |
| ORG-02 | Salon Detail | Page | §4.4 — Profile + Earnings tabs on one screen |
| ORG-M01 | Suspend Salon Modal | Modal | §4.4 — Suspend + reason |
| ORG-M02 | Resume Salon Modal | Modal | §4.4 — Resume |
| ORG-M03 | Terminate Salon Modal | Modal | §4.4 — Terminate + reason |
| ORG-M04 | Edit Commission Modal | Modal | §4.4 — commission edit + confirmation |
| ORG-M05 | Change Plan Modal | Modal | §4.4 — manual subscription plan change |
| ORG-M06 | Apply Discount Modal | Modal | §4.4 — RC / NRC discount |

**ORG-02 tabs (one page, two tab panels):**
- **Profile** — business profile, owner, subscription, branches, status, manual subscription actions
- **Earnings** — subscription + commission revenue, breakdown, date filter, export

---

### 4.6 Transactions (2 pages + 1 modal)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| TXN-01 | End-User Transaction List | Page | §4.5 |
| TXN-02 | Transaction Detail | Page | §4.5 — view detail |
| TXN-M01 | Flag for Dispute Modal | Modal | §4.5 — flag + link to ticketing |

---

### 4.7 Subscription Management (5 pages)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| SUB-01 | Plan Overview | Page | §4.6.1 |
| SUB-02 | Plans List | Page | §4.6.2 |
| SUB-03 | Create / Edit Plan | Page | §4.6.2 — incl. contract discounts |
| SUB-04 | Subscription Transactions List | Page | §4.6.3 |
| SUB-05 | Subscription Transaction Detail | Page | §4.6.3 — invoice / payment detail |

---

### 4.8 Reports (3 pages + 2 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| RPT-01 | Reports Index | Page | §4.7 — entry to all reports |
| RPT-02 | Report View (Template) | Page | §4.7.2 — shared layout for 10 reports |
| RPT-03 | Daily Defaulter Report | Page | §4.7.1 — extended layout + follow-up actions |
| RPT-M01 | Log Call Outcome Modal | Modal | §4.7.1 — log call outcome |
| RPT-M02 | Extend Grace Period Modal | Modal | §4.7.1 — extend grace period |

**10 reports on RPT-02 template:** Revenue Summary, Commission, Salon Growth, Branch Activity, Transaction Volume, Churn & Retention, Support SLA, Discount Utilization, Plan Distribution, Geographic Performance.

---

### 4.9 User Access Control (6 pages + 2 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| USR-01 | Salon Admins List | Page | §4.8.1 — tab 1 |
| USR-02 | Salon Admin Detail | Page | §4.8.1 — view/edit, reset password |
| USR-03 | Sub-Admins List | Page | §4.8.2 — tab 2, read-only |
| USR-04 | Sub-Admin Detail | Page | §4.8.2 — view-only, disable only |
| USR-05 | End Users List | Page | §4.8.3 — tab 3 |
| USR-06 | End User Detail | Page | §4.8.3 — view, disable only |
| USR-M01 | Disable User Modal | Modal | §4.8 — disable (all user types) |
| USR-M02 | Reset Password Modal | Modal | §4.8.1 — salon admin reset |

---

### 4.10 CMS & Banners (7 pages) — HIGH COMPLEXITY

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| CMS-01 | CMS Pages List | Page | §4.9.1 |
| CMS-02 | Page Editor | Page | §4.9.1 — content, SEO, publish/draft/schedule, preview |
| CMS-03 | Blog Posts List | Page | §4.9.1 |
| CMS-04 | Blog Post Editor | Page | §4.9.1 |
| CMS-05 | Media Library | Page | §4.9.1 |
| BNR-01 | In-App Banners List | Page | §4.9.2 |
| BNR-02 | Banner Create / Edit | Page | §4.9.2 — targeting rules, CTA, priority, dates |

> Preview for CMS pages: on **CMS-02**. Banner preview: inline on **BNR-02** — no separate screen.

---

### 4.11 Platform Analytics (1 page)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| ANL-01 | Analytics Dashboard | Page | §4.10 |

---

### 4.12 Support & Ticketing (2 pages + 1 modal)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| TKT-01 | Tickets List | Page | §4.11 |
| TKT-03 | Ticket Detail | Page | §4.11 — status, assign, notes, history |
| TKT-M01 | Create Ticket Modal | Modal | §4.11 — ticket creation fields |

---

### 4.13 Master Configuration (7 pages) — HIGH COMPLEXITY

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| CFG-01 | Settings Hub | Page | §4.12 — navigation to config sections |
| CFG-02 | Reason Codes | Page | §4.12 |
| CFG-03 | Pricing Rules | Page | §4.12 |
| CFG-04 | Notification Templates | Page | §4.12 |
| CFG-05 | Tax / GST Settings | Page | §4.12 |
| CFG-06 | Feature Entitlements Matrix | Page | §4.12 |
| CFG-07 | Payment Gateway & Platform Settings | Page | §4.12 + §4.6.4 commission defaults, grace period |

---

### 4.14 Audit Log (1 page)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| AUD-01 | Audit Log List | Page | §4.13 — actor, action, entity, before/after, timestamp, IP |

> Show before/after detail in **expandable row** on AUD-01 — no separate detail page.

---

*Aligned to Super-Admin-Functional-Spec.md v1.1 only. Add screens when functional spec is updated.*
