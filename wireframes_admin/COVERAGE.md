# Salon Admin Wireframes — Coverage Audit

**Date:** July 24, 2026  
**Sources:** Admin-Functional-Spec.md v1.3 (§§1–4.2) · Admin-Figma-Screen-Guide.md v1.0

---

## A. §§1–4.2 + Figma AUTH / SHELL / DASH

### §4.2 / DASH-01 — **FULLY COVERED** (July 24, 2026)

| Spec item | Main Admin (`dashboard.html`) | Sub Admin (`dashboard-subadmin.html`) |
|-----------|-------------------------------|----------------------------------------|
| Branch cards: name, city, status (Active / Pending / Suspended), today's appts + revenue | Yes (4 cards) | Yes (assigned branch only) |
| Branch selector | Yes | Yes (assigned only) |
| Org KPIs: appts today/week; revenue today/week/month; employees; renewals | Yes | Yes (scoped copy) |
| Alerts: pending branch, expiry, failed renewal, tickets, leave | Yes (5 op cards) | Yes (branch-scoped subset) |
| Quick actions: switch, appointments, employee, service, ticket | Yes | Yes (no org/subscription actions) |
| Banners: upgrade, renewal, branch limit | Yes (3 banners) | N/A (org/plan — Main Admin) |
| No org subscription / Sub Admin management | N/A | Yes (nav + content stripped) |

Other §1–4.2 auth/shell items:
| Requirement | Status | Where |
|-------------|--------|--------|
| Main Admin vs Sub Admin | Covered | both dashboards |
| Account disabled | Covered | `login.html?disabled=1` |
| Org Suspended lock | Covered | `dashboard-locked.html` |
| AUTH-01–04 | Covered | login / forgot / reset / change-password |
| Session expiry | Covered | `login.html?expired=1` |
| MFA / Notifications center | Excluded per Figma guide §2 (NTF-01) | §4.16 via DASH banners + alerts |


---

## B. §4.3 Organization Profile & Subscription — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| PROF-01 | §4.3.1–§4.3.4 tabs: Details / Subscription / Invoices | `organization.html` |
| PROF-02 | §4.3.3 available plans + promo/contract discounts + proration preview | `change-plan.html` |
| PROF-M01 | Confirm plan change (pay if needed, effective date, invoice ref) | `change-plan.html#confirm-plan` |

**PROF-01 coverage:**
- **Details (§4.3.1):** business name, logo, registered address, GST/tax ID, owner, email, phone; Save + audit note; account status Active/Suspended/Terminated read-only
- **Subscription (§4.3.2):** plan name/code/start/renewal/cycle; entitlements matrix; usage vs limits; masked payment; Super Admin manual-change note
- **Invoices (§4.3.4):** purchase/renewal/upgrade/credit; Paid/Pending/Failed; Download PDF; RC/NRC descriptions; failed payment retry + ticket; post-change confirmation (`?changed=1`)

**Main Admin only** — Organization Profile nav not shown for Sub Admin.

---

## C. §4.4–4.5 Branches — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| BRN-01 | §4.5.1 Branch list | `branches.html` |
| BRN-02 | §4.4 Branch profile & settings | `branch-profile.html` |
| BRN-03 | §4.5.2 Request new branch | `request-branch.html` |
| BRN-M01 | At max branches → upgrade prompt | `#branch-limit` on list + request pages |

**§4.4 BRN-02:** name, address, city, pin, phone, email; start/end hours; optional gallery; status Active/Pending/Rejected/Suspended; optional GPS; Save; branch context.

**§4.5.1 BRN-01:** name, city, status, employees, services; switch context / open profile; Add Branch → limit modal when at max.

**§4.5.2 BRN-03:** at-limit locked form + under-limit submit form; pending/rejected list with rejection reason; BRN-M01 upgrade prompt.

---

## D. §4.6 Sub Admins — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| SAD-01 | §4.6 list | `sub-admins.html` |
| SAD-02 | §4.6 + §2.1 create/edit | `sub-admin-edit.html` |
| SAD-M01 | Disable / Enable | `#disable-subadmin` / `#enable-subadmin` |
| SAD-M02 | Reset password email | `#reset-password` |

**List:** name, email, phone, status (Active/Disabled), assigned branches, last login; Super Admin–disabled row (cannot re-enable).

**Create/Edit (`?new=1`):** name, email, phone; branch multi-select; §2.1 module toggles (Branch Profile, Employees, Leave & Holidays, Attendance, Services, Appointments, Transactions, Reports); send credentials email on create.

**Actions:** Disable (blocks login), Enable, Reset password (email). Main Admin only.

---

## E. §4.7 Employees — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| EMP-01 | §4.7.2 list | `employees.html` |
| EMP-02 | §4.7.2 detail | `employee-detail.html` |
| EMP-03 | §4.7.1 add/edit | `employee-edit.html` |
| EMP-M01 | §4.7.3 weekly off | `#weekly-off` |
| EMP-M02 | §4.7.4 deactivate | `#deactivate-employee` |

**List:** branch context; search/filter by name, emp #, status; Active/Inactive rows.

**Detail:** profile, specialist services, weekly off, leave & attendance summary; Edit weekly off / Deactivate.

**Onboard (`?new=1`):** name, phone, email, role, DOJ, optional photo; auto `EMP-#####`; status Active/Inactive; weekly off days.

**Weekly off:** applies from next calendar day. **Deactivate:** inactive, remove from future slots, retain history.

---

## F. §4.8 Leave & Holiday Management — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| LVH-01 | §4.8 tabs: Employee Leave \| Branch Holidays | `leave-holidays.html` |
| LVH-M01 | §4.8.1 Apply leave | `#apply-leave` |
| LVH-M02 | §4.8.1 Manage leave (edit / cancel / override) | `#manage-leave`, `#manage-leave-pending` |
| LVH-M03 | §4.8.2 Add / Edit holiday; past read-only | `#add-holiday`, `#edit-holiday`, `#view-holiday-past`, `#remove-holiday` |

**Employee leave:** Sick / Casual / Paid; employee + date range + note; weekly-off warning; Manage with edit, cancel, override + audit note.

**Branch holidays:** full-year list; recurring annual flag; future edit/remove; past view-only.

---

## G. §4.9 Attendance — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| ATT-01 | §4.9 list | `attendance.html` |
| ATT-M01 | §4.9 Mark In / Mark Out | `#mark-attendance`, `#mark-attendance-out` |
| ATT-M02 | §4.9 Edit (audit logged) | `#edit-attendance`, `#edit-attendance-half`, `#edit-attendance-absent`, `#edit-attendance-leave` |

**List:** branch context; date filter; employee, date, in/out, status (Present, Absent, Half-day, On Leave, Weekly Off); day summary tiles.

**Mark In/Out:** manual entry for employee + date + times + status. **Edit:** current/past with required audit note. **Leave / Weekly Off:** auto from leave & weekly-off modules.

---

## H. §4.10 Service Catalog — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| SVC-01 | §4.10.2 Service list | `services.html` |
| SVC-02 | §4.10.1 Create / Edit | `service-edit.html` (`?new=1` create) |

**List:** branch context; filter status / specialist; sort name, price, popularity; price, duration, offline pay, specialists, Active/Inactive; Deactivate / Activate.

**Create/Edit:** name, description, price, duration, photo, offline payment, status, tagged specialists. Inactive hidden from new bookings; existing appointments retain snapshot.

---

## I. §4.11 Time Slots & Availability — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| SVC-03 | §4.11.1 Slot duration configuration | `slot-config.html` |
| SVC-04 | §4.11.2 Availability preview | `availability-preview.html` |

**Slot config:** branch hours from profile; enable granularities (30/45/60/90/120); service duration alignment table.

**Availability preview:** service + date; factors (hours, duration, specialist rules, appointments); slot grid with Available, No Specialist Available, Booked, Outside hours; optional exclude-absent.

---

## J. §4.12 Appointments & Bookings — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| APT-01 | §4.12.1 List & calendar | `appointments.html` |
| APT-02 | §4.12.2 Detail + actions | `appointment-detail.html` |
| APT-03 | §4.12.5 Booking history | `booking-history.html` |
| APT-M01 | §4.12.3 Reschedule | `#reschedule` |
| APT-M02 | §4.12.3–4 Cancel | `#cancel-booking` |
| APT-M03 | §4.12.4 Initiate refund | `#initiate-refund` |

**APT-01:** widgets; list + day/week/month; filters (date, branch, status, service, specialist, payment status/method); sort; masked phone.

**APT-02:** snapshot, payment breakdown (gross/commission/net), status & refund history; status-gated action bar; Confirm + APT-M01/M02/M03.

**APT-03:** org/branch filters, date range, export CSV/Excel, status trail, refund flag, drill-down to detail.

---

## K. §4.13 Transactions (B2C) — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| TXN-01 | §4.13 Transaction list | `transactions.html` |
| TXN-02 | §4.13 Transaction detail | `transaction-detail.html` |

**List:** org/branch scope; filters (date, branch, status, method, service, specialist); txn ID, datetime, booking link, customer (masked), branch, service, gross, method, status (Success/Failed/Refunded/Disputed), net to salon; export CSV/Excel.

**Detail:** amount breakdown (gross / commission / net), gateway ref, link to appointment, payment timeline. Note: subscription invoices stay under Organization → Invoices.

---

## L. §4.14 Reports — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| RPT-01 | §4.14 Reports index | `reports.html` |
| RPT-02 | §4.14.1–§4.14.2 Report view template | `report-view.html?r=…` |

**Index:** 8 org reports + 7 branch reports as cards linking to shared template; entitlement note.

**Report view:** date range + branch multi-select; KPI strip; results table; CSV/Excel export. `?r=` switches title/description for each report type.

---

## M. §4.15 Support & Ticketing — **FULLY COVERED**

| Figma ID | Spec | File |
|----------|------|------|
| TKT-01 | §4.15 Tickets list | `support.html` |
| TKT-02 | §4.15 Ticket detail | `ticket-detail.html` (`?await=1` awaiting confirmation) |
| TKT-M01 | §4.15 Create ticket | `#create-ticket` |
| TKT-M02 | §4.15 Confirm resolution / reopen | `#confirm-resolution`, `#reopen-ticket` |

**List:** statuses Created / In Progress / On Hold / Awaiting User Confirmation / Resolved; priority; create ticket.

**Detail:** history with Super Admin replies (no internal notes); comments & attachments; confirm resolution when awaiting; reopen within policy window.

---

## N. §4.16 Notifications & In-App Banners — **COVERED (consume-only)**

| Spec item | Where | Notes |
|-----------|--------|--------|
| Platform banners (upgrade / renewal / branch limit) | `dashboard.html` Platform offers | Super Admin configures; Admin consumes (§4.16 / Figma DASH-01) |
| In-app: payment failed, branch pending/approved, plan change, renewal, ticket update | `dashboard.html` In-app alerts | Maps to §4.16 event channels marked Email + in-app |
| Account suspended | `dashboard-locked.html` | Shell lock state |
| Session expiry | `login.html?expired=1` | Auth |
| Email-only events (salon approved, Sub Admin credentials) | — | Out of band; no Admin UI screen |
| End-user cancel notify | Consumer app | Not Admin portal |
| Dedicated notifications center (NTF-01) | **Excluded** | Figma guide §2 — not in functional spec |
| Banner / CMS editor | **Excluded** | Super Admin only |

---

## O. Admin wireframe inventory — **COMPLETE** (§§4.1–4.16)

Auth through Support are fully wired; §4.16 is delivered via Dashboard banners + in-app alerts (no separate NTF page).

---

*Re-run this audit after any module refresh.*
