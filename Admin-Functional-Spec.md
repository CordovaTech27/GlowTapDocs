# GlowTap Salon Admin Portal
## Functional Specification Document

**Version:** 1.1  
**Date:** June 28, 2026  
**Audience:** Business stakeholders, product owners, salon operations teams  
**Purpose:** Define what the Salon Admin portal does, who uses it, and how salon owners and delegated staff manage branches, staff, services, appointments, and subscriptions on GlowTap.

**Related:** Super-Admin-Functional-Spec.md v1.1

---

## 1. Executive Summary

The **GlowTap Salon Admin Portal** is the operational hub for onboarded salons. It enables the **Main Admin (Salon Admin)** — the primary owner account created at salon approval — to manage the organization profile, subscription, billing, branches, sub-admins, staff, services, appointments, and reports across one or more physical locations.

GlowTap follows an **Organization → Branch** model. The Main Admin sees all branches under the org on a central dashboard and selects a **active branch context** to perform branch-specific actions. **Sub Admins** are created by the Main Admin with access limited to assigned branches and permitted modules only.

End-user bookings and payments flow through the GlowTap consumer app; the Admin portal manages fulfillment, staff scheduling, service catalog, attendance, and salon-side financial visibility.

---

## 2. User Roles & Access

| Role | Description | Branch Access | Typical Permissions |
|------|-------------|---------------|---------------------|
| **Main Admin (Salon Admin)** | Primary org owner; auto-created on Super Admin salon approval | All branches under the org | Full access: profile, subscription, billing, sub-admins, all branch operations, org-level reports |
| **Sub Admin** | Delegated staff manager created by Main Admin | Assigned branches only | Module-scoped: e.g., employees, services, appointments, attendance, branch reports — as granted by Main Admin |

**Access principles:**
- Main Admin can create, edit, and disable Sub Admins and assign **branch list** + **module permissions** per Sub Admin
- Sub Admin cannot upgrade/downgrade subscription, manage org profile billing, create other Sub Admins, or access branches outside their assignment
- Super Admin can **disable** any admin account (fraud/policy); disabled users cannot log in
- When org is **Suspended** or **Terminated** by Super Admin, the Admin portal is locked (read-only or full lock per platform policy)

> Login is secured with email/password. Session timeout follows platform configuration.

### 2.1 Sub Admin Module Permissions

When creating or editing a Sub Admin, Main Admin toggles access per module:

| Module | Scope |
|--------|-------|
| Branch Profile | View/edit branch details for assigned branches |
| Employees | Onboard, edit, deactivate staff |
| Leave & Holidays | Weekly offs, leave application, branch holidays |
| Attendance | Mark and view in/out |
| Services | Create, edit, deactivate services and specialist tags |
| Appointments | View, confirm, reschedule, cancel; initiate refunds |
| Transactions | View branch B2C payment history |
| Reports | Branch-level reports for assigned branches |

Main Admin always retains full access regardless of toggles.

---

## 3. Platform Navigation Overview

```
Dashboard (org-wide; branch selector)
├── Organization Profile        (Main Admin only — subscription, billing, org details)
├── Branches                    (list, profile, request new branch)
├── Sub Admins                  (Main Admin only)
├── Employees                   (per branch context)
├── Leave & Holidays            (per branch context)
├── Attendance                  (per branch context)
├── Services                    (per branch context)
├── Appointments                (per branch context)
├── Transactions                (org or branch context)
├── Reports                     (org-level + branch-level)
└── Support & Ticketing         (raise/view tickets to Super Admin)
```

**Branch context:** Most operational modules require an active branch selection (from dashboard or branch switcher). Org-level modules (Organization Profile, Sub Admins, org-wide Reports, subscription upgrade) do not require branch context.

---

## 4. Module Specifications

### 4.1 Authentication

- **Login:** Email + password (credentials emailed at salon approval)
- **Logout** and session expiry handling
- **Change password** from profile/settings (logged-in user)
- **Forgot password:** From login screen — enter registered email → system sends reset link → user sets a new password on the reset page (link expires per platform policy)
- **Account disabled** state: clear message when Super Admin or Main Admin has disabled the account

> MFA may be added in a future release; not in scope for v1.0.

---

### 4.2 Dashboard (Home)

**Main Admin view — org-wide landing:**

- **Branch cards / list:** All branches with name, city, status (Active, Pending Approval, Suspended), today's appointment count, today's revenue snapshot
- **Branch selector:** Choose one branch to enter branch context for operational modules; selection persists until changed
- **Org KPIs:** Total appointments (today / week), total revenue (today / week / month), active employees across branches, upcoming renewals
- **Alerts:** Pending branch approval requests, subscription expiry window, failed renewal payment, open support tickets, staff on leave today
- **Quick actions:** Switch branch, view appointments, add employee, create service, raise support ticket
- **Promotional banners:** In-app banners configured by Super Admin (plan upgrade offers, renewal reminders, branch limit warnings)

**Sub Admin view:**
- Dashboard limited to **assigned branches** only
- Same branch selector and KPIs scoped to permitted branches
- No org subscription or Sub Admin quick actions

---

### 4.3 Organization Profile & Subscription (Main Admin Only)

Central profile for the salon **organization** (not a single branch).

#### 4.3.1 Organization Details

- Business name, logo, registered address, GST/tax ID, owner name, contact email, phone
- Edit and save org-level profile fields (audit logged)
- View account status: Active, Suspended, Terminated (read-only; set by Super Admin)

#### 4.3.2 Subscription & Entitlements

- **Current plan:** Name, code, start date, renewal/expiry date, billing cycle
- **Entitlements under plan:** Max branches, appointments module, employee limit (if plan-capped), analytics tier, other features per Super Admin **Feature Entitlements Matrix**
- **Usage vs limits:** Branch count vs max branches; feature flags shown as allowed / not allowed
- **Payment method** on file (masked)

#### 4.3.3 Plan Upgrade & Downgrade

Main Admin can initiate plan change from the profile:

1. View available plans (active plans only, as configured by Super Admin)
2. System validates **Plan Change Rules** defined by Super Admin:
   - **Upgrade:** May take effect immediately; billing per Super Admin rule — **prorated charge** or **no proration** (platform configuration)
   - **Downgrade:** Effective immediately or at next renewal per Super Admin rule; **branch count must fit** new plan limit before downgrade completes
   - Promotional / contract discounts display per plan (marketing descriptions from Super Admin)
3. Confirm change; payment collected if applicable
4. Confirmation shown with effective date and invoice reference

> Super Admin may also change plan manually from the Super Admin portal (goodwill, dispute); Admin sees updated state in profile.

#### 4.3.4 Invoices & Billing History

- List of subscription invoices: invoice number, date, type (purchase, renewal, upgrade, credit), amount, status (Paid, Pending, Failed)
- **Download invoice** (PDF) per row
- View applied RC/NRC discounts with description (as configured by Super Admin)
- Failed payment status with retry guidance and link to update payment / raise ticket

---

### 4.4 Branch Profile & Settings

Each branch has its own **Profile** section visible when that branch is in context (Main Admin or Sub Admin with Branch Profile permission).

**Branch details:**
- Branch name, address, city, pin code, contact phone, email
- Operating hours: **branch start time** and **branch end time** (used for slot generation)
- Branch photos / gallery (optional)
- Status: Active, Pending Approval, Rejected, Suspended
- GPS/map pin (optional, for consumer app discovery)

**Actions:**
- Edit branch details (Main Admin; Sub Admin if permitted)
- Submit **Save** — changes reflected immediately for booking and slot logic

> Primary branch is created at salon approval. Additional branches require a **Branch Request** (see §4.5).

---

### 4.5 Branch Management

#### 4.5.1 Branch List

- All org branches: name, city, status, employee count, services count
- Navigate to branch profile or switch branch context

#### 4.5.2 Request New Branch (Main Admin)

**Workflow (aligned with Super Admin §4.3):**

1. Main Admin clicks **Add Branch**
2. System checks: current branch count vs subscription **max branches**
   - If **at limit** → prompt to upgrade plan before submission
   - If **within limit** → allow form
3. Submit: branch name, address, contact, proposed operating hours
4. Status **Pending Approval** until Super Admin approves or rejects
5. Notification on approve/reject (email + in-app)
6. On approval, branch appears in dashboard and branch list as **Active**

Main Admin can view pending requests and rejection reason (if rejected).

---

### 4.6 Sub Admin Management (Main Admin Only)

**List view:**
- Name, email, phone, status (Active, Disabled), assigned branches, last login

**Create / Edit Sub Admin:**
- Name, email, phone
- **Branch access:** Multi-select from org branches
- **Module permissions:** Toggle per §2.1
- Send credentials email on create (or invite flow)

**Actions:**
- **Disable** — blocks login; does not delete historical audit data
- **Enable** — restore access
- **Reset password** — triggers email to Sub Admin

> Super Admin can disable a Sub Admin for platform policy violations; Main Admin sees disabled state but cannot override Super Admin disable.

---

### 4.7 Employee Management

Available per **branch context** (Main Admin or Sub Admin with Employees permission).

#### 4.7.1 Employee Onboarding

- Add employee: name, phone, email, role/designation, date of joining, profile photo (optional)
- **Employee number:** Auto-generated by system (unique per org or per branch — configurable; sequential format e.g. `EMP-00042`)
- Status: Active, Inactive

#### 4.7.2 Employee List & Detail

- Search/filter by name, employee number, status
- Detail view: profile, assigned services (as specialist), weekly off, leave balance summary, attendance summary

#### 4.7.3 Weekly Off

- Define **weekly off day(s)** per employee (e.g., Monday, Sunday)
- **Edit weekly off:** Change applies from **immediate next calendar day** (not retroactive for today)
- Weekly off blocks specialist availability for slot generation

#### 4.7.4 Deactivate Employee

- Mark inactive; remove from future slot assignment; retain history

---

### 4.8 Leave & Holiday Management

#### 4.8.1 Employee Leave

**Leave types:**
- Sick Leave
- Casual Leave
- Paid Leave

**Apply leave (Admin / Sub Admin):**
- Select employee, leave type, date range, optional note
- Leave blocks specialist availability for affected dates

**Manage leave:**
- **Edit** pending or future leave
- **Cancel** leave
- **Override** — force approve/deny or adjust dates (with audit note)

Leave on a weekly off day or branch holiday: system warns; admin can proceed if needed.

#### 4.8.2 Branch Holidays

- Define **branch-wide holidays** for the full year (date, name, optional recurring annual flag)
- All employees follow branch holidays — no specialist availability on these dates
- Add, edit, remove future holidays; past holidays read-only

---

### 4.9 Attendance

Per branch context.

- **Mark In / Mark Out** for staff on a given date (manual entry by Admin / Sub Admin)
- **Attendance list:** Employee, date, in time, out time, status (Present, Absent, Half-day, On Leave)
- **Edit** attendance records for current and past dates (with audit log)
- Attendance integrates with leave: employee on approved leave shows **On Leave**; weekly off shows **Weekly Off**

> Optional future enhancement: biometric or geo check-in from staff app — not in v1.0 functional scope.

---

### 4.10 Service Catalog

Per branch context.

#### 4.10.1 Create / Edit Service

| Field | Description |
|-------|-------------|
| Service name | Display name on consumer app and admin |
| Description | Rich text or plain description |
| Price | Base price for the service |
| Duration | Service length — drives slot consumption (must align with slot configuration) |
| Photo | Image shown for this service under the branch |
| Offline payment allowed | Yes/No — if Yes, end user can pay at salon; if No, online payment required at booking |
| Status | Active, Inactive |
| Tagged specialists | One or more employees who can perform this service |

- Admin / Sub Admin can **edit or deactivate** services at any time
- Deactivated services hidden from new bookings; existing appointments retain service snapshot

#### 4.10.2 Service List

- Filter by status, category (if categories added later), specialist
- Sort by name, price, popularity

---

### 4.11 Time Slots & Availability

Per branch context; configured alongside services.

#### 4.11.1 Slot Duration Configuration

- Admin defines allowed **slot granularities** for the branch (e.g., 30 minutes, 45 minutes, 1 hour)
- Service duration must be a multiple of or map to configured slot sizes

#### 4.11.2 Auto-Generated Availability

System generates bookable slots based on:

1. Branch **operating hours** (start/end from branch profile)
2. **Service duration** selected
3. **Specialist availability:** employee weekly off, approved leave, branch holidays, attendance (optional: absent staff excluded)
4. Existing **confirmed appointments** blocking time

**Display rules (consumer app + admin preview):**
- Available slot → bookable
- No qualified specialist for that window → show **No Specialist Available** (not bookable)
- Partial staff availability → only specialists free at that time are offered

Admin can **preview availability calendar** for a service + date to verify configuration.

---

### 4.12 Appointments

Per branch context (and org-wide list for Main Admin).

#### 4.12.1 Appointment List & Calendar

- Views: list and calendar (day / week)
- Filters: date range, status, service, specialist, payment status
- Statuses: Booked, Confirmed, In Progress, Completed, Cancelled, No-Show

**Displayed fields:**
- Appointment ID, date/time, end user name & contact (masked phone optional)
- Service, specialist, amount, payment method (Online / Offline), payment status
- Source: Consumer app (default)

#### 4.12.2 Appointment Detail

- Full booking details, end-user note, payment breakdown, history of status changes

#### 4.12.3 Admin Actions

| Action | Description |
|--------|-------------|
| **Confirm** | Acknowledge booking (if confirmation step enabled) |
| **Reschedule** | Change date/time within available slots; notify end user |
| **Cancel** | Cancel on behalf of customer; reason required |
| **Mark Completed** | Close appointment after service delivered |
| **Mark No-Show** | Customer did not arrive |

#### 4.12.4 Cancel & Refund

When Admin cancels an appointment:

- If **paid online** → Admin can **initiate refund** (full refund per appointment amount; partial refund policy per Super Admin / gateway rules)
- Refund status: Initiated, Processing, Completed, Failed
- If **offline payment** → no gateway refund; mark cancelled only
- Cancelled slot freed for rebooking
- Commission reversal to GlowTap handled per platform rules (Super Admin §5.5)

> Walk-in appointment creation by Admin may be added in a future release.

---

### 4.13 Transactions (B2C)

Visibility into **end-user payments to the salon** (aligned with Super Admin §4.5 — salon-facing view).

**Org-level (Main Admin):** All branches  
**Branch-level:** Selected branch only  
**Sub Admin:** Assigned branches with Transactions permission

**List fields:**
- Transaction ID, date/time, appointment/booking reference
- End user (name / masked ID)
- Branch, service description
- Gross amount, payment method, status (Success, Failed, Refunded, Disputed)
- Net to salon (after GlowTap commission — commission line item visible for transparency)

**Filters:** Date range, branch, status, payment method, service, specialist

**Actions:**
- View detail
- Export CSV/Excel
- Link to related appointment

> Subscription payments (salon → GlowTap) appear under Organization Profile → Invoices, not in B2C Transactions.

---

### 4.14 Reports

#### 4.14.1 Organization-Level Reports (Main Admin)

| Report | Description | Key Filters |
|--------|-------------|-------------|
| **Earnings Summary** | Total revenue, net to salon, online vs offline split, refund total | Date range, all branches or selected branches |
| **Earnings by Branch** | Comparative revenue per branch | Date range |
| **Earnings by Service** | Revenue and booking count per service | Date range, branch |
| **Earnings by Specialist** | Revenue and appointment count per employee | Date range, branch |
| **Appointment Summary** | Bookings, completions, cancellations, no-shows, conversion | Date range, branch, status |
| **Payment Method Mix** | Online vs offline volume and amount | Date range, branch |
| **Refund Report** | Refunds initiated, amounts, reasons | Date range, branch |
| **Subscription & Utilization** | Plan limits vs branch count, feature usage snapshot | Current period |

All org reports support **date range**, **branch multi-select**, and **CSV/Excel export**.

#### 4.14.2 Branch-Level Reports (Main Admin & Sub Admin)

Available for branch context (Sub Admin: assigned branches only).

| Report | Description | Key Filters |
|--------|-------------|-------------|
| **Branch Daily Summary** | Appointments, revenue, attendance headcount for the day | Date |
| **Branch Earnings** | Revenue breakdown for the branch | Date range |
| **Service Performance** | Top services by bookings and revenue | Date range |
| **Specialist Utilization** | Appointments per specialist, idle vs booked hours | Date range |
| **Leave & Attendance** | Leave taken by type, attendance rate | Date range, employee |
| **Peak Hours** | Booking density by hour/day of week | Date range |

**Export:** CSV/Excel on all reports.

> Advanced analytics tier features may be gated by subscription plan (Super Admin entitlements).

---

### 4.15 Support & Ticketing

Salon admins can raise issues to the GlowTap operations team (Super Admin §4.11).

**Create ticket:**
- Reason & sub-reason (from Super Admin master list)
- Description, attachments
- Link branch / appointment / transaction (optional)
- Priority suggestion (final priority may be set by Super Admin)

**Ticket list:**
- Status: Created, In Progress, On Hold, Awaiting User Confirmation, Resolved
- View history and Super Admin replies (internal notes not visible)

**Actions:**
- Add comment / attachment
- Confirm resolution when status is Awaiting User Confirmation
- Reopen if issue persists (within policy window)

---

### 4.16 Notifications & In-App Banners

| Event | Recipient | Channel |
|-------|-----------|---------|
| Salon approved (initial) | Main Admin | Email |
| Branch approved / rejected | Main Admin | Email + in-app |
| Subscription renewal reminder | Main Admin | Email + in-app banner |
| Plan change confirmation | Main Admin | Email + in-app |
| Invoice / payment failed | Main Admin | Email + in-app |
| Account suspended / resumed | Main Admin | Email + in-app |
| Ticket status update | Ticket raiser | Email + in-app |
| Sub Admin credentials | Sub Admin | Email |
| Appointment cancelled (by admin) | End user | Email/SMS/push (consumer app) |

**In-app banners** (Super Admin configured): plan upgrade prompts, renewal offers, branch limit warnings — shown on dashboard per targeting rules.

---

## 5. Key Business Rules

### 5.1 Branch Limits & Plan Entitlements

- Maximum branches enforced by current subscription plan (Super Admin §5.1)
- Features (employees cap, analytics tier, appointments module) enforced per **Feature Entitlements Matrix**
- Downgrade blocked if active branch count exceeds new plan limit — Main Admin must deactivate branches or cancel pending requests first

### 5.2 Plan Change & Billing

- Upgrade/downgrade behavior (proration, effective date) follows **Plan Change Rules** configured by Super Admin — not hardcoded in Admin portal
- Main Admin sees applicable charges/credits before confirming
- Invoice generated for chargeable plan changes; available in Organization Profile

### 5.3 Specialist Availability & Slots

- Slots generated only within branch operating hours
- Employee weekly off changes apply from **next calendar day**
- Branch holidays and approved leave remove specialist from availability
- If no specialist available for a slot → **No Specialist Available** (consumer-facing)

### 5.4 Appointments & Refunds

- Cancelling online-paid appointments triggers optional refund initiation by Admin
- Refund processing subject to payment gateway and Super Admin commission reversal rules
- Cancelled appointments cannot be reactivated; new booking required

### 5.5 Sub Admin Scope

- Sub Admin access is intersection of **assigned branches** AND **enabled modules**
- Main Admin cannot grant access to branches outside the org
- Super Admin disable on Sub Admin overrides Main Admin enable

### 5.6 Account Suspension

- When Super Admin suspends the org, Admin portal access is restricted; end-user booking to affected branches stops
- Data retained; no deletion of employees, services, or history

---

## 6. Glossary

| Term | Definition |
|------|------------|
| **Org / Organization** | Salon business entity on GlowTap; owns subscription and branches |
| **Branch** | Physical salon location under an organization |
| **Main Admin / Salon Admin** | Primary org administrator; full branch and subscription access |
| **Sub Admin** | Delegated user with limited branch and module access |
| **End User** | Consumer booking via GlowTap app |
| **Specialist** | Employee tagged to perform specific services |
| **RC / NRC** | Recurring / Non-Recurring Charge — subscription billing components |
| **B2C Transaction** | End-user payment to salon for services/bookings |
| **Slot** | Bookable time window derived from branch hours, service duration, and specialist availability |

---

## 7. Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1 | June 28, 2026 | GlowTap Product Team | Forgot password added to v1.0 auth scope |
| 1.0 | June 28, 2026 | GlowTap Product Team | Initial Admin portal functional specification |

---

*This document describes the intended behavior of the GlowTap Salon Admin Portal. Technical implementation details will be covered in the companion Admin Solutioning Document.*
