# GlowTap Salon Admin — Sub Admin Requirements

**Source:** Admin-Functional-Spec.md v1.3 (§2, §2.1, §4.2, §4.6, §5.5)  
**Purpose:** Define what a Sub Admin can see and do vs Main Admin.  
**Date:** July 26, 2026

---

## 1. Role summary

| | Main Admin | Sub Admin |
|---|------------|-----------|
| Who | Org owner (created on salon approval) | Delegated user created by Main Admin |
| Branches | All org branches | **Assigned branches only** |
| Access model | Full | **Assigned branches ∩ enabled modules** (§5.5) |

**Hard rules (§2):**
- Sub Admin **cannot** manage subscription / billing / org profile
- Sub Admin **cannot** create or manage other Sub Admins
- Sub Admin **cannot** access branches outside assignment
- Super Admin disable on a Sub Admin **overrides** Main Admin enable
- If org is Suspended / Terminated → portal locked for all admins

---

## 2. Always available (not module-gated)

| Function | Sub Admin |
|----------|-----------|
| Login / logout / session expiry | Yes |
| Forgot / reset password | Yes |
| Change password (logged in) | Yes |
| Dashboard (scoped) | Yes — assigned branches only |
| Branch switcher | Yes — assigned branches only |
| Account disabled message | Yes (if Main or Super Admin disabled them) |

---

## 3. Never visible to Sub Admin (Main Admin only)

| Nav / function | Spec |
|----------------|------|
| **Organization Profile** (details, subscription, invoices, plan change) | §4.3 — Main Admin only |
| **Sub Admins** (list / create / edit / disable / reset password) | §4.6 — Main Admin only |
| Org subscription KPIs / upgrade / renewal billing actions on dashboard | §4.2 Sub Admin view |
| Org-wide reports (Earnings Summary, by Branch, Subscription & Utilization, etc.) | §4.14.1 — Main Admin |
| Request **new** branch / branch-limit upgrade flow | Plan/org action — Main Admin |
| Org-wide appointment / transaction scope across unassigned branches | §5.5 |

---

## 4. Module permissions (§2.1) — what Main Admin can toggle

Access = module **ON** + branch **assigned**. If module OFF → hide nav item (or show locked / no access).

| Module toggle | Visible functions (assigned branches only) |
|---------------|--------------------------------------------|
| **Branch Profile** | View/edit branch details: name, address, hours, gallery, GPS, status view (§4.4) |
| **Employees** | List, detail, add/edit, weekly off, deactivate (§4.7) |
| **Leave & Holidays** | Apply/manage leave; branch holidays (§4.8) |
| **Attendance** | Mark In/Out; list/edit attendance (§4.9) |
| **Services** | Service list/create/edit/deactivate; specialists; slot config & availability preview (§4.10–4.11) |
| **Appointments** | List/calendar, detail, confirm/reschedule/cancel/complete/no-show; refund if allowed; booking history **branch-scoped** (§4.12, §5.4) |
| **Transactions** | B2C payment list/detail for assigned branches (§4.13) |
| **Reports** | **Branch-level** reports only (§4.14.2): Daily Summary, Branch Earnings, Service Performance, Specialist Utilization, Leave & Attendance, Booking History Export, Peak Hours & No-Shows |

Main Admin always has full access regardless of these toggles.

---

## 5. Navigation (Sub Admin shell)

Show only what is granted:

```
Dashboard                          (always — scoped)
├── Branches / Branch Profile      (if Branch Profile ON)
├── Employees                      (if Employees ON)
├── Leave & Holidays               (if Leave & Holidays ON)
├── Attendance                     (if Attendance ON)
├── Services                       (if Services ON)
├── Appointments & Bookings        (if Appointments ON)
├── Transactions                   (if Transactions ON)
├── Reports                        (if Reports ON — branch reports only)
└── Support & Ticketing            (see §6)
```

**Hidden:** Organization Profile · Sub Admins

---

## 6. Support & Ticketing

§4.15 allows salon admins to raise tickets; §4.16 notifies the **ticket raiser**. Support is **not** listed in §2.1 toggles.

**Recommended requirement:**
- Sub Admin **can** create/view **their own** tickets (and confirm resolution / reopen per policy)
- No separate module toggle in v1.0 — always available when logged in  
  *(If product later gates Support, add a §2.1 toggle.)*

---

## 7. Dashboard requirements (Sub Admin)

| Element | Behavior |
|---------|----------|
| Branch cards | Assigned branches only (name, city, status, today appts/revenue) |
| Branch selector | Assigned Active branches only |
| KPIs | Scoped to assigned branches (not full org) |
| Alerts | Branch-scoped (leave, tickets, branch ops) — **no** org billing / subscription / Sub Admin management |
| Quick actions | Appointments, employee, service, ticket — **only** if matching module is ON; **no** plan/subscription actions |
| Platform banners | May still show Super Admin–configured banners (consume-only) |

Reference wireframe: `wireframes_admin/dashboard-subadmin.html`

---

## 8. Example permission matrix (for QA / wireframes)

**Primary wireframe demo:** `manager@luxecurls.in` (Riya Kapoor) — **multiple assigned salons**

| Field | Value |
|-------|-------|
| Role | Sub Admin |
| Assigned branches | Bandra West, Koramangala, Juhu Wave, Indiranagar |
| Active branch | All Assigned (default) or multi-select any subset |

| Module | Granted |
|--------|:-------:|
| Branch Profile | Yes |
| Employees | Yes |
| Leave & Holidays | Yes |
| Attendance | Yes |
| Services | Yes |
| Appointments | Yes |
| Transactions | No |
| Reports | Yes |

**Visible nav:** Dashboard, Branch Profile, Employees, Leave & Holidays, Attendance, Services, Appointments, Reports, Support  
**Hidden:** Organization, Sub Admins, Transactions  
**Blocked:** Unassigned branch data (e.g. Andheri / Powai / Colaba), org invoices, create Sub Admin, change plan

*Single-salon assignment is also valid — the shell behaves the same; the picker simply lists one branch.*

---

## 9. Acceptance criteria (checklist)

- [ ] Sub Admin login lands on scoped dashboard (assigned branches only)
- [ ] Nav hides Organization Profile and Sub Admins
- [ ] Nav shows only modules toggled ON for that Sub Admin
- [ ] Branch switcher lists only assigned branches
- [ ] Opening an unassigned branch URL shows access denied / redirect
- [ ] Appointments / Transactions / Reports never show other branches’ data
- [ ] Reports index shows branch-level set only (no org-level report cards)
- [ ] Disabled Sub Admin cannot log in; SA-disabled cannot be re-enabled by Main Admin
- [ ] Org Suspended lock applies to Sub Admin the same as Main Admin

---

## 10. Wireframe follow-up

HTML wireframes live in **`sub admin wireframe/`** (same shell patterns as Main Admin):

1. Shell nav stripped to granted modules  
2. Branch switcher scoped to assigned branches  
3. Org-only pages unreachable → `access-denied.html`  
4. `dashboard.html` as the home pattern (from §4.2 Sub Admin view)  

Open `sub admin wireframe/index.html` to browse screens.

---

*Aligned to Admin-Functional-Spec.md v1.3 only.*
