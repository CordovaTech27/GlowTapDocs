# GlowTap Salon Admin Portal
## Figma Screen Inventory & Step-by-Step Design Guide

**Version:** 1.0  
**Date:** July 24, 2026  
**Purpose:** Screens to design in Figma for Salon Admin — **only what is defined in the Functional Specification v1.3**.

**Source:** Admin-Functional-Spec.md v1.3

---

## 1. Screen Count Summary

**Counting rules:**
- **Page** = navigable screen defined in the functional spec
- **Modal** = overlay for an action defined in the functional spec (not a page)
- **Layout** = app shell (design once, **not a page**)
- **Component** = reusable pattern (empty state, confirm dialog) — not counted as pages

| Category | Pages | Modals | Layout | Figma Frames | Complexity |
|----------|------:|-------:|-------:|-------------:|------------|
| Auth | 4 | 0 | 0 | 4 | Low |
| App Shell | — | — | 1 | 1 | Medium |
| Dashboard | 1 | 0 | 0 | 1 | Medium |
| Organization Profile & Subscription | 2 | 1 | 0 | 3 | Medium |
| Branches | 3 | 1 | 0 | 4 | Medium |
| Sub Admins | 2 | 2 | 0 | 4 | Medium |
| Employees | 3 | 2 | 0 | 5 | Medium |
| Leave & Holidays | 1 | 3 | 0 | 4 | Medium |
| Attendance | 1 | 2 | 0 | 3 | Low |
| Services & Availability | 4 | 0 | 0 | 4 | High |
| Appointments & Bookings | 3 | 3 | 0 | 6 | High |
| Transactions | 2 | 0 | 0 | 2 | Low |
| Reports | 2 | 0 | 0 | 2 | Medium |
| Support & Ticketing | 2 | 2 | 0 | 4 | Medium |
| **TOTAL (in scope)** | **30** | **16** | **1** | **~47** | |

**Summary:**
- **30 pages** (functional spec only)
- **16 modals**
- **1 app shell** (layout — not a page)
- **~47 Figma frames**

---

## 2. Excluded — Not in Functional Spec v1.3

Do **not** design these unless added to a future functional spec version:

| Removed ID | Was | Why excluded |
|------------|-----|--------------|
| AUTH-MFA | MFA Verification page | Spec: MFA may be added in a future release — not in v1.0 scope (§4.1) |
| APT-WALK | Walk-in booking create | Spec: future release (§4.12.6) |
| ATT-BIO | Biometric / geo check-in | Spec: optional future enhancement — not in v1.0 (§4.9) |
| CMS / BNR | CMS pages or banner editor | Admin only **consumes** platform banners on dashboard; create/edit is Super Admin (§4.16) |
| NTF-01 | Dedicated notifications center | Spec lists event channels only — no notifications list screen defined |
| GLB-02 | Error / 404 page | Not in functional spec |
| GLB-M01 | Generic Confirm Dialog | Reusable component only — not a separate deliverable |

**Role / state notes (not separate screens):**
- **Sub Admin dashboard** = same **DASH-01**, scoped to assigned branches (no org subscription / Sub Admin quick actions)
- **Account disabled** = state on **AUTH-01** (clear message)
- **Org Suspended / Terminated** = shell lock / read-only state on **SHELL-01** (§2, §5.6)
- **Confirm / Mark In Progress / Mark Completed** booking actions = primary buttons + reusable confirm — not separate modals

---

## 3. Complexity Legend

| Level | Meaning |
|-------|---------|
| **Low** | List or simple form |
| **Medium** | Filters, tabs, tables, multi-step actions |
| **High** | Calendars, availability logic, rich editors, many conditional states |

---

## 4. Complete Screen Inventory (Functional Spec Only)

### 4.1 Auth (4 pages) + App Shell (1 layout)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| AUTH-01 | Login | Page | §4.1 — email/password; account disabled message |
| AUTH-02 | Forgot Password | Page | §4.1 — enter registered email → send reset link |
| AUTH-03 | Reset Password | Page | §4.1 — set new password from email link |
| AUTH-04 | Change Password | Page | §4.1 — from profile/settings (logged-in) |
| SHELL-01 | App Shell | Layout | §3 — nav modules + **branch selector** + header |

**SHELL-01 nav (Main Admin):** Dashboard, Organization Profile, Branches, Sub Admins, Employees, Leave & Holidays, Attendance, Services, Appointments & Bookings, Transactions, Reports, Support & Ticketing.

**SHELL-01 notes:**
- Most operational modules require **active branch context** (branch switcher)
- Org-level modules (Organization Profile, Sub Admins, org-wide Reports, plan change) do **not** require branch context
- Sub Admin nav: hide Organization Profile + Sub Admins; show only assigned modules (§2.1)

---

### 4.2 Dashboard (1 page)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| DASH-01 | Dashboard Home | Page | §4.2 — branch cards, KPIs, alerts, quick actions, platform banners |

**DASH-01 must show:**
- Branch cards/list (name, city, status, today’s appointments, today’s revenue)
- Branch selector (persists until changed)
- Org KPIs (appointments, revenue, active employees, upcoming renewals)
- Alerts (pending branch requests, expiry, failed renewal, open tickets, staff on leave)
- Quick actions (switch branch, appointments, add employee, create service, raise ticket)
- **Promotional / platform in-app banners** (upgrade, renewal, branch limit — Super Admin configured) (§4.16)

---

### 4.3 Organization Profile & Subscription (2 pages + 1 modal) — Main Admin only

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| PROF-01 | Organization Profile | Page | §4.3.1–§4.3.4 — Details + Subscription + Invoices tabs |
| PROF-02 | Change Plan | Page | §4.3.3 — available plans, rules, proration preview |
| PROF-M01 | Confirm Plan Change Modal | Modal | §4.3.3 — confirm; payment if applicable; effective date |

**PROF-01 tabs (one page, three tab panels):**
- **Details** — business name, logo, address, GST/tax ID, owner, contact; account status (Active / Suspended / Terminated — read-only)
- **Subscription** — current plan, entitlements, usage vs limits, payment method (masked)
- **Invoices** — invoice list, download PDF, RC/NRC discounts, failed payment + retry / ticket link

---

### 4.4 Branches (3 pages + 1 modal)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| BRN-01 | Branch List | Page | §4.5.1 — name, city, status, employee count, services count |
| BRN-02 | Branch Profile | Page | §4.4 — details, operating hours, gallery, GPS, save |
| BRN-03 | Request New Branch | Page | §4.5.2 — form; pending / rejected reason visibility |
| BRN-M01 | Branch Limit — Upgrade Prompt Modal | Modal | §4.5.2 — at max branches → prompt upgrade before submit |

---

### 4.5 Sub Admins (2 pages + 2 modals) — Main Admin only

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| SAD-01 | Sub Admins List | Page | §4.6 — name, email, phone, status, branches, last login |
| SAD-02 | Create / Edit Sub Admin | Page | §4.6 — branch multi-select + module permission toggles (§2.1) |
| SAD-M01 | Disable / Enable Sub Admin Modal | Modal | §4.6 — disable blocks login; enable restores (unless Super Admin disabled) |
| SAD-M02 | Reset Password Modal | Modal | §4.6 — triggers email to Sub Admin |

**SAD-02 module toggles:** Branch Profile, Employees, Leave & Holidays, Attendance, Services, Appointments, Transactions, Reports.

---

### 4.6 Employees (3 pages + 2 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| EMP-01 | Employee List | Page | §4.7.2 — search/filter by name, employee number, status |
| EMP-02 | Employee Detail | Page | §4.7.2 — profile, specialists services, weekly off, leave & attendance summary |
| EMP-03 | Add / Edit Employee | Page | §4.7.1 — name, phone, email, role, DOJ, photo; auto employee number |
| EMP-M01 | Edit Weekly Off Modal | Modal | §4.7.3 — applies from **next calendar day** |
| EMP-M02 | Deactivate Employee Modal | Modal | §4.7.4 — inactive; remove from future slots; retain history |

> Requires **branch context**. Sub Admin needs Employees permission.

---

### 4.7 Leave & Holidays (1 page + 3 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| LVH-01 | Leave & Holidays | Page | §4.8 — tabs: Employee Leave \| Branch Holidays |
| LVH-M01 | Apply Leave Modal | Modal | §4.8.1 — employee, type (Sick / Casual / Paid), date range, note |
| LVH-M02 | Manage Leave Modal | Modal | §4.8.1 — edit, cancel, or override (with audit note) |
| LVH-M03 | Add / Edit Holiday Modal | Modal | §4.8.2 — date, name, optional recurring annual; past holidays read-only |

---

### 4.8 Attendance (1 page + 2 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| ATT-01 | Attendance List | Page | §4.9 — employee, date, in/out, status (Present, Absent, Half-day, On Leave, Weekly Off) |
| ATT-M01 | Mark In / Mark Out Modal | Modal | §4.9 — manual entry for a given date |
| ATT-M02 | Edit Attendance Modal | Modal | §4.9 — edit current/past records (audit logged) |

---

### 4.9 Services & Availability (4 pages) — HIGH COMPLEXITY

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| SVC-01 | Service List | Page | §4.10.2 — filter status / specialist; sort name, price, popularity |
| SVC-02 | Create / Edit Service | Page | §4.10.1 — name, description, price, duration, photo, offline pay, specialists, status |
| SVC-03 | Slot Duration Configuration | Page | §4.11.1 — allowed granularities (e.g. 30 / 45 / 60 min) |
| SVC-04 | Availability Preview | Page | §4.11.2 — preview calendar for service + date; No Specialist Available state |

---

### 4.10 Appointments & Bookings (3 pages + 3 modals) — HIGH COMPLEXITY

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| APT-01 | Appointments List & Calendar | Page | §4.12.1 — list + day/week/month calendar; branch/org filters |
| APT-02 | Appointment Detail | Page | §4.12.2 — snapshot, payment breakdown, status/reschedule/refund history, actions |
| APT-03 | Booking History | Page | §4.12.5 — org/branch filters, export, drill-down to APT-02 |
| APT-M01 | Reschedule Modal | Modal | §4.12.3 — pick available slot; prior slot freed |
| APT-M02 | Cancel Booking Modal | Modal | §4.12.3–§4.12.4 — reason from master list; refund path if online paid |
| APT-M03 | Initiate Refund Modal | Modal | §4.12.3–§4.12.4 — cancelled + online paid; status Initiated → Completed/Failed |

**APT-01 filters:** date range, branch (org-wide), status, service, specialist, payment status, payment method.

**APT-02 action bar (status-gated):** Confirm, Reschedule, Cancel, Mark In Progress, Mark Completed, Mark No-Show, Initiate Refund — invalid transitions blocked by system (§5.4).

---

### 4.11 Transactions (2 pages)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| TXN-01 | Transaction List | Page | §4.13 — B2C payments; org or branch scope; export |
| TXN-02 | Transaction Detail | Page | §4.13 — view detail; link to related appointment |

> Subscription invoices (salon → GlowTap) live under **PROF-01 → Invoices**, not here.

---

### 4.12 Reports (2 pages)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| RPT-01 | Reports Index | Page | §4.14 — entry to org-level + branch-level reports |
| RPT-02 | Report View (Template) | Page | §4.14.1–§4.14.2 — shared layout; date/branch filters; CSV/Excel export |

**8 organization-level reports on RPT-02 (Main Admin):** Earnings Summary, Earnings by Branch, Earnings by Service, Earnings by Specialist, Appointment Summary, Payment Method Mix, Refund Report, Subscription & Utilization.

**7 branch-level reports on RPT-02:** Branch Daily Summary, Branch Earnings, Service Performance, Specialist Utilization, Leave & Attendance, Booking History Export, Peak Hours & No-Shows.

> Advanced analytics may be gated by subscription entitlements (§4.14).

---

### 4.13 Support & Ticketing (2 pages + 2 modals)

| ID | Screen Name | Type | Functional reference |
|----|-------------|------|---------------------|
| TKT-01 | Tickets List | Page | §4.15 — status: Created, In Progress, On Hold, Awaiting User Confirmation, Resolved |
| TKT-02 | Ticket Detail | Page | §4.15 — history, Super Admin replies (no internal notes), comments, attachments |
| TKT-M01 | Create Ticket Modal | Modal | §4.15 — reason/sub-reason, description, attachments, optional links, priority suggestion |
| TKT-M02 | Confirm Resolution Modal | Modal | §4.15 — when status is Awaiting User Confirmation; reopen within policy window |

---

## 5. Suggested Figma Build Order

Design in this order so shared patterns land first:

1. **SHELL-01** + tokens (branch selector is critical)
2. **AUTH-01 → AUTH-04**
3. **DASH-01** (includes banner slot)
4. **BRN-01 → BRN-03** + **BRN-M01**
5. **PROF-01 / PROF-02** + **PROF-M01**
6. **SAD-01 / SAD-02** + modals
7. **EMP / LVH / ATT** (branch-scoped ops)
8. **SVC-01 → SVC-04**
9. **APT-01 → APT-03** + booking modals
10. **TXN**, **RPT**, **TKT**

Frame naming: `[ID] Screen Name` — e.g. `DASH-01 Dashboard Home`, `APT-M02 Cancel Booking Modal`.  
Desktop frame size: **1440 × 1024** (enable vertical scrolling on main content).

---

*Aligned to Admin-Functional-Spec.md v1.3 only. Add screens when functional spec is updated.*
